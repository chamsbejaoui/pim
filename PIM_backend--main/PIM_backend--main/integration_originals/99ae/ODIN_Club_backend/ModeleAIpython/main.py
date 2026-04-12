import os
import json
import joblib
import numpy as np
from fastapi import FastAPI
from pydantic import BaseModel
from typing import Any, Literal
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.model_selection import StratifiedKFold, cross_validate, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.calibration import CalibratedClassifierCV
from sklearn.metrics import accuracy_score, recall_score, f1_score
import lightgbm as lgb
import shap

app = FastAPI(
    title="Antigravity AI Pro",
    description="AI-powered football player recruitment decision system (LightGBM + SHAP)",
    version="3.0.0",
)

MODEL_PATH = "model.pkl"
SCALER_PATH = "scaler.pkl"
DATASET_PATH = "dataset.json"
METRICS_PATH = "metrics.json"
KMEANS_PATH = "kmeans.pkl"

FEATURE_NAMES = ["speed", "endurance", "distance", "dribbles", "shots", "injuries", "heart_rate"]

# ==========================
# Data Model
# ==========================

class Player(BaseModel):
    userId: str | None = None
    firstName: str
    lastName: str
    dateOfBirth: str | None = None
    position: str | None = None
    strongFoot: str | None = None
    jerseyNumber: int | None = None
    height: float | None = None
    weight: float | None = None
    photo: str | None = None
    nationality: str | None = None
    speed: float
    endurance: float
    distance: float
    dribbles: float
    shots: float
    injuries: int
    heart_rate: float
    label: int | None = None


class ChemistryInsightsRequest(BaseModel):
    context: Literal["best_pairs", "conflicts", "lineup", "player_network", "pair_profile"]
    season: str | None = None
    payload: dict[str, Any]


def profile_name(data: dict) -> str:
    first_name = data.get("firstName")
    last_name = data.get("lastName")
    full_name = " ".join(part for part in [first_name, last_name] if part)
    if full_name.strip():
        return full_name.strip()
    return data.get("name", "Unknown")


def profile_identity(player: Player) -> dict:
    data = player.model_dump()
    return {
        "userId": player.userId,
        "firstName": player.firstName,
        "lastName": player.lastName,
        "profile_name": profile_name(data),
    }

# ==========================
# Utilities
# ==========================

def load_dataset():
    if os.path.exists(DATASET_PATH):
        with open(DATASET_PATH, "r") as f:
            return json.load(f)
    return []

def save_dataset(data):
    with open(DATASET_PATH, "w") as f:
        json.dump(data, f, indent=2)

def load_metrics():
    if os.path.exists(METRICS_PATH):
        with open(METRICS_PATH, "r") as f:
            return json.load(f)
    return {}

def save_metrics(metrics):
    with open(METRICS_PATH, "w") as f:
        json.dump(metrics, f, indent=2)

def extract_features(data):
    X = []
    y = []
    for p in data:
        if "label" in p and p["label"] is not None:
            X.append([p[f] for f in FEATURE_NAMES])
            y.append(p["label"])
    return np.array(X), np.array(y)

# ==========================
# Dynamic Cluster Labels
# ==========================

def assign_cluster_labels(kmeans, scaler):
    """Analyze centroids to assign meaningful labels based on actual stats."""
    centroids = kmeans.cluster_centers_  # shape: (n_clusters, n_features)

    # Inverse transform to get original-scale centroids
    centroids_original = scaler.inverse_transform(centroids)

    # Compute a composite "quality score" per cluster centroid
    # Higher speed, endurance, distance, dribbles, shots = better
    # Higher injuries, heart_rate = worse
    quality_scores = {}
    for i, centroid in enumerate(centroids_original):
        score = (
            centroid[0]  # speed
            + centroid[1]  # endurance
            + centroid[2] * 5  # distance (scaled up, typically 4-12)
            + centroid[3]  # dribbles
            + centroid[4] * 10  # shots (scaled up, typically 0-8)
            - centroid[5] * 10  # injuries (penalty)
            - centroid[6] * 0.5  # heart_rate (lower is better)
        )
        quality_scores[i] = score

    # Rank clusters by quality
    ranked = sorted(quality_scores.items(), key=lambda x: x[1], reverse=True)

    labels = {}
    label_names = ["Elite", "Prospect", "Standard"]
    for rank, (cluster_id, _) in enumerate(ranked):
        labels[cluster_id] = label_names[rank] if rank < len(label_names) else f"Group {cluster_id}"

    return labels

# ==========================
# Cross-Validation (NO data leakage — Pipeline)
# ==========================

def run_cross_validation(X, y):
    """
    Run stratified K-Fold cross-validation using a Pipeline.
    The scaler is fitted INSIDE each fold — no data leakage.
    """
    n_per_class = min(np.bincount(y))
    n_splits = min(5, n_per_class)
    if n_splits < 2:
        return {"warning": "Not enough samples per class for cross-validation"}

    cv = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=42)

    # Pipeline: scaler + model fitted together inside each fold
    pipeline = Pipeline([
        ("scaler", StandardScaler()),
        ("model", lgb.LGBMClassifier(
            n_estimators=500,
            learning_rate=0.05,
            max_depth=6,
            num_leaves=31,
            min_child_samples=2,
            random_state=42,
            verbose=-1,
        )),
    ])

    scoring = ["accuracy", "recall", "f1"]
    cv_results = cross_validate(pipeline, X, y, cv=cv, scoring=scoring, return_train_score=True)

    return {
        "n_folds": n_splits,
        "cv_accuracy": round(float(np.mean(cv_results["test_accuracy"])) * 100, 2),
        "cv_accuracy_std": round(float(np.std(cv_results["test_accuracy"])) * 100, 2),
        "cv_recall": round(float(np.mean(cv_results["test_recall"])) * 100, 2),
        "cv_recall_std": round(float(np.std(cv_results["test_recall"])) * 100, 2),
        "cv_f1": round(float(np.mean(cv_results["test_f1"])) * 100, 2),
        "cv_f1_std": round(float(np.std(cv_results["test_f1"])) * 100, 2),
        "train_accuracy": round(float(np.mean(cv_results["train_accuracy"])) * 100, 2),
    }

# ==========================
# Training (LightGBM + Early Stopping + Calibration)
# ==========================

def train_model():
    data = load_dataset()
    labeled = [p for p in data if p.get("label") is not None]

    if len(labeled) < 5:
        return {
            "status": f"Not enough labeled data to train (have {len(labeled)}, need 5)",
            "metrics": {},
        }

    X, y = extract_features(data)

    # --- Cross-Validation (on RAW X, no leakage) ---
    cv_metrics = run_cross_validation(X, y)

    # --- Fit scaler on full data for the final production model ---
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    # --- Train base LightGBM with early stopping ---
    # This model is used for feature importance and early stopping info.
    if len(X_scaled) >= 10:
        X_train, X_val, y_train, y_val = train_test_split(
            X_scaled, y, test_size=0.2, random_state=42, stratify=y
        )
        early_stopping_rounds = 50
    else:
        X_train, y_train = X_scaled, y
        X_val, y_val = None, None
        early_stopping_rounds = None

    base_model = lgb.LGBMClassifier(
        n_estimators=500,
        learning_rate=0.05,
        max_depth=6,
        num_leaves=31,
        min_child_samples=2,
        subsample=0.8,
        colsample_bytree=0.8,
        random_state=42,
        verbose=-1,
    )

    fit_params = {}
    if X_val is not None and early_stopping_rounds is not None:
        fit_params["eval_set"] = [(X_val, y_val)]
        fit_params["callbacks"] = [
            lgb.early_stopping(stopping_rounds=early_stopping_rounds, verbose=False),
            lgb.log_evaluation(period=0),
        ]

    base_model.fit(X_train, y_train, **fit_params)

    # --- Probability Calibration (sklearn 1.8+ compatible) ---
    # CalibratedClassifierCV with CV folds: internally trains + calibrates
    # using isotonic regression for well-calibrated probability outputs.
    n_cal_folds = min(3, min(np.bincount(y)))
    if n_cal_folds >= 2:
        cal_cv = StratifiedKFold(n_splits=n_cal_folds, shuffle=True, random_state=42)
        calibrated_model = CalibratedClassifierCV(
            estimator=lgb.LGBMClassifier(
                n_estimators=500,
                learning_rate=0.05,
                max_depth=6,
                num_leaves=31,
                min_child_samples=2,
                subsample=0.8,
                colsample_bytree=0.8,
                random_state=42,
                verbose=-1,
            ),
            method="isotonic",
            cv=cal_cv,
        )
        calibrated_model.fit(X_scaled, y)
    else:
        # Not enough data for calibration folds — use base model directly
        calibrated_model = base_model

    # --- Feature importance (from the base LightGBM) ---
    importance = base_model.feature_importances_
    feature_importance = {
        name: int(imp) for name, imp in
        sorted(zip(FEATURE_NAMES, importance), key=lambda x: x[1], reverse=True)
    }

    # --- Early stopping info ---
    early_stop_info = {}
    if hasattr(base_model, "best_iteration_"):
        early_stop_info["best_iteration"] = base_model.best_iteration_
        early_stop_info["total_estimators_configured"] = 500
        early_stop_info["early_stopping_rounds"] = early_stopping_rounds

    # --- Train KMeans + dynamic labels ---
    kmeans_info = {}
    if len(X_scaled) > 2:
        kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
        kmeans.fit(X_scaled)
        cluster_labels = assign_cluster_labels(kmeans, scaler)
        joblib.dump({"model": kmeans, "labels": cluster_labels}, KMEANS_PATH)
        kmeans_info["clusters_trained"] = 3
        kmeans_info["cluster_labels"] = cluster_labels

    # --- Save model + scaler ---
    joblib.dump({"calibrated": calibrated_model, "base": base_model}, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)

    all_metrics = {
        "training_samples": len(X),
        "cross_validation": cv_metrics,
        "feature_importance": feature_importance,
        "early_stopping": early_stop_info,
        "kmeans": kmeans_info,
        "calibration": "enabled (CalibratedClassifierCV)",
        "pipeline_cv": "enabled (no data leakage)",
    }
    save_metrics(all_metrics)

    return {
        "status": f"Model trained successfully on {len(X)} samples",
        "metrics": all_metrics,
    }

# ==========================
# Prediction (SHAP + Calibrated Probabilities)
# ==========================

def predict_player(player: Player):
    if not os.path.exists(MODEL_PATH):
        return {"error": "Model not trained yet. Add labeled data via /train first."}

    models = joblib.load(MODEL_PATH)
    calibrated_model = models["calibrated"]
    base_model = models["base"]
    scaler = joblib.load(SCALER_PATH)

    features = np.array([[player.speed, player.endurance, player.distance,
                          player.dribbles, player.shots, player.injuries,
                          player.heart_rate]])

    features_scaled = scaler.transform(features)

    # Calibrated prediction
    prediction = calibrated_model.predict(features_scaled)[0]
    probability = calibrated_model.predict_proba(features_scaled)[0]
    confidence = float(probability[1]) * 100  # calibrated probability of recruitment

    # --- SHAP values: per-player feature explanation ---
    explainer = shap.TreeExplainer(base_model)
    shap_values = explainer.shap_values(features_scaled)

    # For binary classification, shap_values may be a list [class_0, class_1]
    if isinstance(shap_values, list):
        player_shap = shap_values[1][0]  # SHAP values for class 1 (recruited)
    else:
        player_shap = shap_values[0]

    # Build per-feature explanation: positive = pushes toward recruitment
    shap_explanation = {}
    for name, sv in zip(FEATURE_NAMES, player_shap):
        shap_explanation[name] = {
            "shap_value": round(float(sv), 4),
            "impact": "positive" if sv > 0 else "negative" if sv < 0 else "neutral",
        }

    # Sort by absolute impact
    shap_explanation = dict(
        sorted(shap_explanation.items(), key=lambda x: abs(x[1]["shap_value"]), reverse=True)
    )

    # --- Clustering with dynamic labels ---
    cluster = 0
    cluster_label = "Unknown"

    if os.path.exists(KMEANS_PATH):
        kmeans_data = joblib.load(KMEANS_PATH)
        kmeans = kmeans_data["model"]
        cluster_labels = kmeans_data["labels"]
        cluster = int(kmeans.predict(features_scaled)[0])
        cluster_label = cluster_labels.get(cluster, f"Group {cluster}")

    return {
        "user": profile_identity(player),
        "recruitment": "Yes" if prediction == 1 else "No",
        "confidence_score": round(confidence, 2),
        "calibrated": True,
        "cluster_profile": cluster,
        "cluster_label": cluster_label,
        "shap_explanation": shap_explanation,
    }

# ==========================
# Similar Players (Euclidean Distance)
# ==========================

def find_similar_players(player: Player, top_n: int = 5):
    """Find the N most similar players from the dataset using Euclidean distance."""
    if not os.path.exists(SCALER_PATH):
        return {"error": "Model not trained yet. Train first via /train."}

    scaler = joblib.load(SCALER_PATH)
    data = load_dataset()

    if len(data) == 0:
        return {"error": "No profiles in the dataset."}

    # Scale the target player's features
    target_features = np.array([[player.speed, player.endurance, player.distance,
                                  player.dribbles, player.shots, player.injuries,
                                  player.heart_rate]])
    target_scaled = scaler.transform(target_features)

    # Load cluster info if available
    cluster_labels_map = {}
    kmeans = None
    if os.path.exists(KMEANS_PATH):
        kmeans_data = joblib.load(KMEANS_PATH)
        kmeans = kmeans_data["model"]
        cluster_labels_map = kmeans_data["labels"]

    results = []
    for p in data:
        p_features = np.array([[p["speed"], p["endurance"], p["distance"],
                                 p["dribbles"], p["shots"], p["injuries"],
                                 p["heart_rate"]]])
        p_scaled = scaler.transform(p_features)
        distance = float(np.linalg.norm(target_scaled - p_scaled))

        cluster_label = "Unknown"
        if kmeans is not None:
            cluster = int(kmeans.predict(p_scaled)[0])
            cluster_label = cluster_labels_map.get(cluster, f"Group {cluster}")

        results.append({
            "user": {
                "userId": p.get("userId"),
                "firstName": p.get("firstName"),
                "lastName": p.get("lastName"),
                "profile_name": profile_name(p),
            },
            "speed": p["speed"],
            "endurance": p["endurance"],
            "distance": p["distance"],
            "dribbles": p["dribbles"],
            "shots": p["shots"],
            "injuries": p["injuries"],
            "heart_rate": p["heart_rate"],
            "distance_score": round(distance, 4),
            "similarity_pct": round(max(0, (1 - distance / 10) * 100), 1),  # Normalize to 0-100%
            "cluster_label": cluster_label,
        })

    # Sort by distance (closest first), exclude exact match (distance ~0)
    results.sort(key=lambda x: x["distance_score"])
    # Filter out the player itself (if in dataset)
    target_name = profile_identity(player)["profile_name"]
    results = [
        r for r in results
        if r["user"]["profile_name"] != target_name or r["distance_score"] > 0.01
    ]

    return {
        "user": profile_identity(player),
        "similar_profiles": results[:top_n],
    }


# ==========================
# Potential Score (DateOfBirth-Weighted Elite Proximity)
# ==========================

def compute_potential_score(player: Player):
    """Compute a development potential score (0-100) based on proximity to Elite cluster."""
    if not os.path.exists(SCALER_PATH) or not os.path.exists(KMEANS_PATH):
        return {"error": "Model not trained yet. Train first via /train."}

    scaler = joblib.load(SCALER_PATH)
    kmeans_data = joblib.load(KMEANS_PATH)
    kmeans = kmeans_data["model"]
    cluster_labels = kmeans_data["labels"]

    # Find Elite cluster index
    elite_cluster = None
    for cluster_id, label in cluster_labels.items():
        if label == "Elite":
            elite_cluster = cluster_id
            break

    if elite_cluster is None:
        return {"error": "Elite cluster not found. Retrain the model."}

    # Get Elite centroid in original scale
    elite_centroid_scaled = kmeans.cluster_centers_[elite_cluster]
    elite_centroid = scaler.inverse_transform([elite_centroid_scaled])[0]

    # Player features
    player_features = np.array([player.speed, player.endurance, player.distance,
                                 player.dribbles, player.shots, player.injuries,
                                 player.heart_rate])

    # Calculate gap to Elite for each feature
    elite_gap = {}
    for i, name in enumerate(FEATURE_NAMES):
        current = float(player_features[i])
        target = float(elite_centroid[i])

        if name in ("injuries", "heart_rate"):
            # Lower is better for injuries and heart_rate
            gap = current - target  # positive means worse than Elite
            direction = "decrease"
        else:
            # Higher is better for speed, endurance, etc.
            gap = target - current  # positive means room to improve
            direction = "increase"

        elite_gap[name] = {
            "current": round(current, 1),
            "elite_target": round(target, 1),
            "gap": round(gap, 1),
            "direction": direction,
        }

    # Compute raw proximity score (0-100)
    # Scale player features and compute distance to Elite centroid
    player_scaled = scaler.transform([player_features])
    distance_to_elite = float(np.linalg.norm(player_scaled - elite_centroid_scaled))
    # Normalize: distance 0 = score 100, distance ~5+ = score ~0
    raw_score = max(0, min(100, (1 - distance_to_elite / 5) * 100))

    # Date-of-birth factor: younger = more potential
    dob_bonus = 5
    dob_factor = "+5pts (dateOfBirth unknown)"
    if player.dateOfBirth:
        try:
            birth_year = int(player.dateOfBirth[:4])
            current_year = 2026
            age = current_year - birth_year
            if age <= 18:
                dob_bonus = 15
            elif age <= 21:
                dob_bonus = 10
            elif age <= 25:
                dob_bonus = 5
            else:
                dob_bonus = 0
            dob_factor = f"+{dob_bonus}pts (age {age} from dateOfBirth)"
        except (TypeError, ValueError):
            dob_bonus = 5
            dob_factor = "+5pts (invalid dateOfBirth format)"

    potential_score = min(100, round(raw_score + dob_bonus, 1))

    # Get current cluster
    player_cluster = int(kmeans.predict(player_scaled)[0])
    player_cluster_label = cluster_labels.get(player_cluster, f"Group {player_cluster}")

    return {
        "user": profile_identity(player),
        "potential_score": potential_score,
        "raw_proximity_score": round(raw_score, 1),
        "dateOfBirth_factor": dob_factor,
        "dateOfBirth_bonus": dob_bonus,
        "current_cluster": player_cluster_label,
        "elite_gap": elite_gap,
    }


# ==========================
# Development Plan (SHAP-Based Improvement Targets)
# ==========================

def generate_development_plan(player: Player):
    """Generate a personalized development plan using SHAP negative impacts."""
    if not os.path.exists(MODEL_PATH) or not os.path.exists(SCALER_PATH):
        return {"error": "Model not trained yet. Train first via /train."}

    # Get prediction + SHAP
    prediction = predict_player(player)
    if "error" in prediction:
        return prediction

    shap_explanation = prediction.get("shap_explanation", {})

    # Get Elite centroid for target values
    elite_centroid = None
    if os.path.exists(KMEANS_PATH):
        scaler = joblib.load(SCALER_PATH)
        kmeans_data = joblib.load(KMEANS_PATH)
        kmeans = kmeans_data["model"]
        cluster_labels = kmeans_data["labels"]

        for cluster_id, label in cluster_labels.items():
            if label == "Elite":
                elite_centroid = scaler.inverse_transform([kmeans.cluster_centers_[cluster_id]])[0]
                break

    player_features = {
        "speed": player.speed,
        "endurance": player.endurance,
        "distance": player.distance,
        "dribbles": player.dribbles,
        "shots": player.shots,
        "injuries": player.injuries,
        "heart_rate": player.heart_rate,
    }

    # Build improvement plan from SHAP weaknesses
    improvements = []
    strengths = []

    for feature_name, shap_info in shap_explanation.items():
        shap_value = shap_info["shap_value"]
        impact = shap_info["impact"]
        current_value = player_features.get(feature_name, 0)

        # Elite target
        target_value = None
        if elite_centroid is not None:
            feat_idx = FEATURE_NAMES.index(feature_name)
            target_value = float(elite_centroid[feat_idx])

        if impact == "negative":
            # This feature hurts the recruitment chance
            if feature_name in ("injuries", "heart_rate"):
                direction = "decrease"
                improvement_text = f"Reduce {feature_name.replace('_', ' ')} from {round(current_value, 1)} to {round(target_value, 1) if target_value else 'lower'}"
            else:
                direction = "increase"
                improvement_text = f"Increase {feature_name.replace('_', ' ')} from {round(current_value, 1)} to {round(target_value, 1) if target_value else 'higher'}"

            priority = "high" if abs(shap_value) > 0.3 else "medium"

            improvements.append({
                "feature": feature_name,
                "current_value": round(current_value, 1),
                "target_value": round(target_value, 1) if target_value else None,
                "direction": direction,
                "shap_impact": round(shap_value, 4),
                "priority": priority,
                "recommendation": improvement_text,
            })
        elif impact == "positive":
            strengths.append({
                "feature": feature_name,
                "current_value": round(current_value, 1),
                "shap_impact": round(shap_value, 4),
                "note": f"{feature_name.replace('_', ' ').title()} is a strong point (+{round(shap_value, 3)})",
            })

    # Sort improvements by absolute SHAP impact (most critical first)
    improvements.sort(key=lambda x: abs(x["shap_impact"]), reverse=True)

    return {
        "user": profile_identity(player),
        "current_cluster": prediction.get("cluster_label", "Unknown"),
        "recruitment_confidence": prediction.get("confidence_score", 0),
        "improvements": improvements,
        "strengths": strengths,
        "summary": f"{len(improvements)} areas to improve, {len(strengths)} strengths identified",
    }


# ==========================
# Chemistry Insights (AI Service)
# ==========================

def _as_dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def _safe_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _safe_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _pair_label(pair: dict[str, Any]) -> str:
    a_name = str(pair.get("playerAName") or pair.get("source") or "Player A")
    b_name = str(pair.get("playerBName") or pair.get("target") or "Player B")
    return f"{a_name} + {b_name}"


def _best_pairs_insights(payload: dict[str, Any]) -> list[str]:
    rows = [_as_dict(item) for item in _as_list(payload.get("pairs")) if isinstance(item, dict)]
    if len(rows) == 0:
        return ["No chemistry pair data available for this filter. Capture pair observations first."]

    rows.sort(key=lambda pair: _safe_float(pair.get("averageRating"), 0.0), reverse=True)
    top = rows[0]
    top_label = _pair_label(top)
    top_rating = _safe_float(top.get("averageRating"), 0.0)
    top_obs = _safe_int(top.get("observationCount"), 0)

    insights = [
        f"Top synergy is {top_label} at {top_rating:.1f}/10 (n={top_obs}). Prioritize this duo in coordinated attacking patterns."
    ]

    if len(rows) > 1:
        second = rows[1]
        insights.append(
            f"Secondary synergy is {_pair_label(second)} at {_safe_float(second.get('averageRating'), 0.0):.1f}/10. Build a rotating triangle around both pairs."
        )

    top_three = rows[:3]
    top_three_avg = sum(_safe_float(pair.get("averageRating"), 0.0) for pair in top_three) / len(top_three)
    insights.append(f"Top-3 pair chemistry average is {top_three_avg:.2f}/10, indicating a strong reusable relational core.")

    low_sample_pairs = [pair for pair in top_three if _safe_int(pair.get("observationCount"), 0) < 3]
    if len(low_sample_pairs) > 0:
        insights.append("Some high-rated pairs still have low sample size (<3 observations). Confirm stability before making irreversible tactical decisions.")

    return insights[:5]


def _conflicts_insights(payload: dict[str, Any]) -> list[str]:
    rows = [_as_dict(item) for item in _as_list(payload.get("pairs")) if isinstance(item, dict)]
    if len(rows) == 0:
        return ["No conflict pair data found for this filter."]

    rows.sort(key=lambda pair: _safe_float(pair.get("averageRating"), 10.0))
    risk = rows[0]
    risk_label = _pair_label(risk)
    risk_rating = _safe_float(risk.get("averageRating"), 10.0)
    risk_obs = _safe_int(risk.get("observationCount"), 0)

    insights = [
        f"Highest-risk pair is {risk_label} at {risk_rating:.1f}/10 (n={risk_obs}). Reduce shared-lane exposure and define clearer role separation."
    ]

    confirmed_conflicts = [pair for pair in rows if _safe_float(pair.get("averageRating"), 10.0) <= 4.5 and _safe_int(pair.get("observationCount"), 0) >= 3]
    if len(confirmed_conflicts) > 0:
        insights.append(f"There are {len(confirmed_conflicts)} confirmed conflict pairs (rating <= 4.5 with n>=3). Schedule targeted relational drills before using them in high-pressure phases.")

    low_sample_conflicts = [pair for pair in rows if _safe_float(pair.get("averageRating"), 10.0) <= 4.5 and _safe_int(pair.get("observationCount"), 0) < 3]
    if len(low_sample_conflicts) > 0:
        insights.append("At least one conflict signal has low sample size. Run controlled test minutes before hard exclusions.")

    return insights[:5]


def _lineup_insights(payload: dict[str, Any]) -> list[str]:
    summary = _as_dict(payload.get("summary"))
    impact = _as_dict(payload.get("impact"))
    smart_alerts = [str(item) for item in _as_list(payload.get("smartPairingAlerts"))]

    score = _safe_float(summary.get("chemistryScore"), 0.0)
    coverage = _safe_float(summary.get("coverage"), 0.0)

    insights: list[str] = []

    if score >= 8.0:
        insights.append(f"Lineup chemistry score is {score:.2f}/10: high cohesion profile. Preserve the core relational structure and rotate around it.")
    elif score >= 6.5:
        insights.append(f"Lineup chemistry score is {score:.2f}/10: stable but improvable. Upgrade 1-2 weak links for better match resilience.")
    else:
        insights.append(f"Lineup chemistry score is {score:.2f}/10: fragile relational network. Prioritize compatibility over pure individual rating for next selection.")

    if coverage < 40:
        insights.append(f"Chemistry coverage is {coverage:.1f}%. Increase pair observations to improve AI confidence in lineup decisions.")

    central_triangle = _as_dict(impact.get("centralTriangle"))
    central_score = _safe_float(central_triangle.get("score"), -1)
    if central_score >= 0:
        if central_score >= 8:
            insights.append(f"Central triangle is strong ({central_score:.2f}). Use this axis to control tempo and trigger transitions.")
        elif central_score < 6.5:
            insights.append(f"Central triangle is weak ({central_score:.2f}). Rebalance midfield roles or test alternative central pairing.")

    weak_link = _as_dict(impact.get("leftFlankWeakLink"))
    weak_rating = _safe_float(weak_link.get("rating"), -1)
    if weak_rating >= 0 and weak_rating <= 4.5:
        insights.append(
            f"Critical weak link detected: {weak_link.get('playerAName', 'Player A')} + {weak_link.get('playerBName', 'Player B')} ({weak_rating:.1f}/10). Avoid stacking them in the same corridor."
        )

    if len(smart_alerts) > 0:
        insights.append(f"Priority coaching alert: {smart_alerts[0]}")

    return insights[:6]


def _player_network_insights(payload: dict[str, Any]) -> list[str]:
    player = _as_dict(payload.get("player"))
    summary = _as_dict(payload.get("summary"))
    connections = [_as_dict(item) for item in _as_list(payload.get("connections")) if isinstance(item, dict)]

    player_name = str(player.get("playerName") or "This player")
    if len(connections) == 0:
        return [f"{player_name} has no chemistry links yet. Collect observed pair ratings before role optimization."]

    avg_rating = _safe_float(summary.get("averageRating"), 0.0)
    connections.sort(key=lambda item: _safe_float(item.get("rating"), 0.0), reverse=True)
    strongest = connections[0]
    weakest = connections[-1]

    insights = [
        f"{player_name}'s strongest link is {strongest.get('teammateName', 'Unknown')} at {_safe_float(strongest.get('rating'), 0.0):.1f}/10. Build local combinations around this anchor relation.",
        f"{player_name}'s weakest link is {weakest.get('teammateName', 'Unknown')} at {_safe_float(weakest.get('rating'), 0.0):.1f}/10. Use staged minutes and explicit role constraints to reduce disconnect risk.",
    ]

    if avg_rating >= 8:
        insights.append(f"Network average is {avg_rating:.2f}/10: this player is a high-cohesion connector.")
    elif avg_rating < 6.5:
        insights.append(f"Network average is {avg_rating:.2f}/10: this player requires selective pairing support to stabilize team structure.")

    tested_links = len([item for item in connections if _safe_int(item.get("observationCount"), 0) >= 3])
    insights.append(f"Reliable links (n>=3): {tested_links}/{len(connections)}. Increase repetitions for low-sample connections.")

    return insights[:6]


def _pair_profile_insights(payload: dict[str, Any]) -> tuple[list[str], float]:
    player_a = _as_dict(payload.get("playerA"))
    player_b = _as_dict(payload.get("playerB"))
    style_a = _as_dict(player_a.get("style"))
    style_b = _as_dict(player_b.get("style"))

    a_name = str(player_a.get("playerName") or "Player A")
    b_name = str(player_b.get("playerName") or "Player B")

    baseline = _safe_float(payload.get("baselineProfileScore"), 0.0)
    if baseline <= 0:
        metrics = [
            "possessionPlay",
            "selfishness",
            "oneTouchPreference",
            "directPlay",
            "riskTaking",
            "pressingIntensity",
            "offBallMovement",
            "communication",
            "defensiveDiscipline",
            "creativity",
        ]
        similarities = []
        for metric in metrics:
            left = _safe_float(style_a.get(metric), 5.0)
            right = _safe_float(style_b.get(metric), 5.0)
            similarities.append(max(0.0, 10.0 - abs(left - right)))
        baseline = round(sum(similarities) / len(similarities), 2) if len(similarities) > 0 else 5.0

    selfishness_a = _safe_float(style_a.get("selfishness"), 5.0)
    selfishness_b = _safe_float(style_b.get("selfishness"), 5.0)
    communication_a = _safe_float(style_a.get("communication"), 5.0)
    communication_b = _safe_float(style_b.get("communication"), 5.0)
    off_ball_a = _safe_float(style_a.get("offBallMovement"), 5.0)
    off_ball_b = _safe_float(style_b.get("offBallMovement"), 5.0)

    # Style-aware correction layer around baseline compatibility.
    correction = 0.0
    if selfishness_a + selfishness_b >= 15:
        correction -= 0.8
    if communication_a + communication_b >= 14:
        correction += 0.5
    if abs(off_ball_a - off_ball_b) <= 2:
        correction += 0.4

    score = max(0.0, min(10.0, round(baseline + correction, 2)))

    insights = [
        f"Profile chemistry estimate for {a_name} + {b_name}: {score:.2f}/10.",
    ]

    if score >= 8.5:
        insights.append("Strong profile compatibility: prioritize these players in connected tactical zones.")
    elif score <= 4.5:
        insights.append("High profile friction: avoid forcing this pair in the same corridor without role constraints.")
    else:
        insights.append("Moderate compatibility: use targeted co-adaptation drills to stabilize their relationship.")

    if selfishness_a + selfishness_b >= 15:
        insights.append("Both profiles show high selfishness tendency. Define explicit passing triggers to avoid disconnection.")
    if communication_a + communication_b >= 14:
        insights.append("Communication profile is strong. Leverage this pair as an on-field coordination anchor.")

    return insights[:6], score


def generate_chemistry_insights(req: ChemistryInsightsRequest) -> dict[str, Any]:
    payload = _as_dict(req.payload)
    score: float | None = None

    if req.context == "best_pairs":
        insights = _best_pairs_insights(payload)
    elif req.context == "conflicts":
        insights = _conflicts_insights(payload)
    elif req.context == "lineup":
        insights = _lineup_insights(payload)
    elif req.context == "pair_profile":
        insights, score = _pair_profile_insights(payload)
    else:
        insights = _player_network_insights(payload)

    return {
        "context": req.context,
        "season": req.season,
        "source": "python-ai-service",
        "engine": "chemistry-insight-v1",
        "insights": insights,
        "score": score,
    }


# ==========================
# API Endpoints
# ==========================

@app.get("/")
def home():
    return {"message": "Antigravity AI Pro v4.0 — LightGBM + SHAP + Insights 🚀"}


@app.post("/chemistry/insights")
def chemistry_insights(req: ChemistryInsightsRequest):
    """Generate AI insights for team chemistry contexts (pairs, conflicts, lineup, network)."""
    return generate_chemistry_insights(req)

@app.post("/predict")
def predict(player: Player):
    """Predict recruitment decision with SHAP explanation and calibrated confidence."""
    return predict_player(player)

@app.post("/similar")
def similar(player: Player, top_n: int = 5):
    """Find the most similar user profiles from the training dataset."""
    return find_similar_players(player, top_n)

@app.post("/potential")
def potential(player: Player):
    """Compute development potential score (0-100) based on proximity to Elite cluster."""
    return compute_potential_score(player)

@app.post("/development-plan")
def development_plan(player: Player):
    """Generate a personalized development plan using SHAP-based weakness analysis."""
    return generate_development_plan(player)

@app.post("/train")
def add_and_train(players: list[Player]):
    """Add labeled user profile data and retrain the model."""
    data = load_dataset()

    added = 0
    for p in players:
        player_dict = p.model_dump()
        if p.label is not None:
            data.append(player_dict)
            added += 1

    save_dataset(data)
    result = train_model()

    return {
        "profiles_added": added,
        "total_dataset_size": len(data),
        "training_status": result["status"],
        "metrics": result.get("metrics", {}),
    }

@app.get("/dataset")
def get_dataset():
    """View the current training dataset."""
    data = load_dataset()
    return {"total": len(data), "data": data}

@app.get("/metrics")
def get_metrics():
    """View CV metrics, feature importance, calibration and clustering info."""
    return load_metrics()

@app.get("/status")
def model_status():
    """Check if the model is trained and ready."""
    model_exists = os.path.exists(MODEL_PATH)
    data = load_dataset()
    labeled = [p for p in data if p.get("label") is not None]
    metrics = load_metrics()

    return {
        "model_trained": model_exists,
        "model_type": "LightGBM (calibrated)" if model_exists else None,
        "dataset_size": len(data),
        "labeled_samples": len(labeled),
        "ready_for_prediction": model_exists,
        "cross_validation_metrics": metrics.get("cross_validation", {}),
        "feature_importance": metrics.get("feature_importance", {}),
    }

class MacroCycleGenRequest(BaseModel):
    macro_type: str
    weeks_count: int

@app.post("/generate-microcycles")
def generate_microcycles(req: MacroCycleGenRequest):
    """V3 Pro: Generate expert-level micro-cycles (RPE, exercises objects, nutrition, indicators)."""
    micro_cycles = []
    macro_type = req.macro_type.upper()
    weeks = req.weeks_count

    # ── PRE_SEASON data bank ──────────────────────────────────
    pre_season_weeks = [
        {
            "label": "Choc physiologique",
            "focus": "HIGH_INTENSITY",
            "objective": "Remettre les organismes en charge maximale après off-season. Établir les bases aérobies.",
            "trainingVolume": "Très élevé — 8 séances / 16h",
            "intensityLevel": "60%-75% VMA — travail foncier long",
            "chargeRpe": 7,
            "ratioTravailRepos": "4:1",
            "keyExercises": [
                {"ordre": 1, "nom": "Gacon 45/15", "objectif": "Développer la PMA et la capacité répétitive", "repetitions": "6×6 répétitions", "intensite": "90% VMA", "materiel": "Plots, chrono GPS"},
                {"ordre": 2, "nom": "Circuit endurance musculaire", "objectif": "Renforcement gainage + résistance musculaire", "repetitions": "4 circuits × 8 exercices × 45s", "intensite": "Modéré", "materiel": "TRX, élastiques, banc"},
                {"ordre": 3, "nom": "Jeux réduits 3v3 pressing", "objectif": "Transition physique → tactique", "repetitions": "5×4min avec 2min récup", "intensite": "85%+ FCmax", "materiel": "Terrain 20×20m, 2 buts"}
            ],
            "medicalAdvice": "Surveiller la VRC (HRV) quotidiennement. Échauffements progressifs 20min obligatoires. Risque élevé de contractures après off-season.",
            "indicateursProgression": ["Distance parcourue/séance > 9km", "RPE moyen < 8", "Aucune blessure musculaire"],
            "nutritionRecommandee": "Charge glucidique élevée pré et post-entraînement. Hydratation 3L/jour minimum. Protéines 1.8g/kg/jour.",
            "sessionVideoTactique": False,
        },
        {
            "label": "Consolidation aérobie",
            "focus": "HIGH_INTENSITY",
            "objective": "Renforcer le socle aérobie et introduire les premières charges explosives.",
            "trainingVolume": "Élevé — 7 séances / 13h",
            "intensityLevel": "70%-85% VMA — intervalles progressifs",
            "chargeRpe": 8,
            "ratioTravailRepos": "3:1",
            "keyExercises": [
                {"ordre": 1, "nom": "30-15 IFT (Buchheit)", "objectif": "Évaluer et développer la VMA de manière spécifique football", "repetitions": "3 séries de 6min", "intensite": "95-100% VMA", "materiel": "Plots, GPS, chrono"},
                {"ordre": 2, "nom": "Pliométrie horizontale", "objectif": "Développement force réactive et explosivité sprint", "repetitions": "4×8 bonds horizontaux max", "intensite": "Maximal", "materiel": "Haies basses 30cm, terrain gazon"},
                {"ordre": 3, "nom": "Opposition 5v5+GK pressing haut", "objectif": "Intensité cardio en contexte ballon — automatismes défensifs", "repetitions": "6×5min, 90s récupération", "intensite": "85%+ FCmax", "materiel": "Terrain 35×25m, 4 petits buts"}
            ],
            "medicalAdvice": "Prise en charge préventive des ischio-jambiers (Nordic curl 2x/sem). Surveiller les genoux sur la pliométrie — interdire si douleur antérieure.",
            "indicateursProgression": ["VMA testée ou estimée > semaine précédente", "Temps de contact sol < 200ms en pliométrie", "FC récupération 1min < 140bpm"],
            "nutritionRecommandee": "Apport protéique augmenté (2g/kg). Collation pré-séance 90min avant : céréales + protéine. Bain de sel d'Epsom 2x/semaine.",
            "sessionVideoTactique": False,
        },
        {
            "label": "Décharge & super-compensation",
            "focus": "RECOVERY",
            "objective": "Surcompensation et assimilation du cycle de charge. Récupération neuromusculaire.",
            "trainingVolume": "Faible — 3 séances / 4.5h",
            "intensityLevel": "50%-60% VMA — régénération",
            "chargeRpe": 4,
            "ratioTravailRepos": "1:2",
            "keyExercises": [
                {"ordre": 1, "nom": "Footing aérobie lent", "objectif": "Accélération de la récupération par activation circulatoire légère", "repetitions": "1×30min continu", "intensite": "60% FCmax — conversation possible", "materiel": "Terrain ou piste"},
                {"ordre": 2, "nom": "Stretching PNF", "objectif": "Restauration de la longueur musculaire et prévention contractures", "repetitions": "3×30s par groupe musculaire", "intensite": "Doux — sans douleur", "materiel": "Tapis, élastiques"},
                {"ordre": 3, "nom": "Proprioception + équilibre", "objectif": "Stabilisation articulaire cheville/genou — prévention entorse", "repetitions": "3×2min par jambe", "intensite": "Contrôle — faible intensité", "materiel": "Plateau instable, Bosu"}
            ],
            "medicalAdvice": "Massage récupération prioritaire. Contrôle sommeil (≥8h). Pas de séance intense si HRV basse. Banlir alcool et veilles tardives.",
            "indicateursProgression": ["Sensation de forme (éch. 1-10) > 7", "FC repos revenue à la normale", "Moral élevé — motivation montante"],
            "nutritionRecommandee": "Réduction glucides à 4g/kg. Augmenter légumes et antioxydants (baies, épinards). Oméga-3 indispensables cette semaine.",
            "sessionVideoTactique": True,
        },
    ]

    # ── COMPETITION data bank ─────────────────────────────────
    competition_weeks = [
        {
            "label": "Pic de forme pré-match",
            "focus": "HIGH_INTENSITY",
            "objective": "Atteindre le pic de forme pour les matchs à fort enjeu. Explosivité et acuité tactique maximales.",
            "trainingVolume": "Modéré — 5 séances / 8h",
            "intensityLevel": "95%-105% VMA — Intermittent court",
            "chargeRpe": 8,
            "ratioTravailRepos": "3:1",
            "keyExercises": [
                {"ordre": 1, "nom": "Sprints 10-20-30m avec résistance", "objectif": "Activation neuro-musculaire explosive avant match", "repetitions": "3 séries × 5 sprints — récup 90s", "intensite": "Sprint maximal 100%", "materiel": "Élastiques résistance, plots de vitesse, chrono"},
                {"ordre": 2, "nom": "Opposition 7v7 avec consignes tactiques match", "objectif": "Automatiser les schémas de jeu sous fatigue modérée", "repetitions": "3×8min — 3min récup active", "intensite": "85-90% FCmax", "materiel": "Terrain demi-terrain, buts réglementaires"},
                {"ordre": 3, "nom": "Séance de finition et penaltys", "objectif": "Confiance offensive et réflexes de buteur", "repetitions": "5×10 frappes — 6 penaltys", "intensite": "Technique — concentration maximale", "materiel": "Buts réglementaires, ballons ×15"}
            ],
            "medicalAdvice": "Gel froid sur les groupes sollicités après séance. Pas d'entraînement intense J-2 match. Surveiller signes de fatigue centrale (irritabilité, baisse réflexes).",
            "indicateursProgression": ["% tirs cadrés > 60%", "Distance sprint/match > 800m", "Temps de réaction < 250ms"],
            "nutritionRecommandee": "Charge glucidique 2 jours avant match (6-8g/kg). Collation matchday : pâtes + poulet 3h avant. Éviter graisses et fibres le jour J.",
            "sessionVideoTactique": True,
        },
        {
            "label": "Consolidation tactique",
            "focus": "MAINTENANCE",
            "objective": "Automatisation des schémas tactiques sous fatigue réelle de saison.",
            "trainingVolume": "Moyen — 5 séances / 9h",
            "intensityLevel": "70%-80% VMA — charge contrôlée",
            "chargeRpe": 6,
            "ratioTravailRepos": "2:1",
            "keyExercises": [
                {"ordre": 1, "nom": "Jeu de position 4v4+2 jokers", "objectif": "Maîtrise technique balle au pied sous pression légère", "repetitions": "4×6min — 2min récup", "intensite": "70% FCmax — contrôle", "materiel": "Terrain 30×30m, 2 couleurs de chasuble"},
                {"ordre": 2, "nom": "Circuit força-vitesse (RSA)", "objectif": "Maintien qualité sprints répétés en milieu de saison", "repetitions": "6×40m sprint — 20s récup passive", "intensite": "95% vitesse max", "materiel": "Plots, chrono, GPS individuel"},
                {"ordre": 3, "nom": "Travail sur schémas tactiques fixes (corners, CFA)", "objectif": "Efficacité sur phases arrêtées — 25-30% des buts en pro", "repetitions": "3 variantes × 8 répétitions chacune", "intensite": "Technique — faible effort physique", "materiel": "Terrain réglementaire, ballons, cibles"}
            ],
            "medicalAdvice": "Point médical individuel obligatoire milieu de semaine. Contrôle des douleurs chroniques (genou, épaule). Adaptation charge pour joueurs > 3 matchs/semaine.",
            "indicateursProgression": ["Précision passes longues > 70%", "Buts sur phases arrêtées > 0", "Aucune blessure de contact"],
            "nutritionRecommandee": "Ration équilibrée standard 50-30-20 (G-L-P). Supplémentation magnésium soir pour récupération musculaire. Éviter repas lourds la veille séance intensive.",
            "sessionVideoTactique": True,
        },
        {
            "label": "Récupération active post-phase",
            "focus": "RECOVERY",
            "objective": "Régénération physique et mentale avant nouveau bloc de matchs.",
            "trainingVolume": "Faible — 3 séances / 5h",
            "intensityLevel": "60%-70% VMA — récupération",
            "chargeRpe": 3,
            "ratioTravailRepos": "1:3",
            "keyExercises": [
                {"ordre": 1, "nom": "Natation/aqua-jogging récupération", "objectif": "Décharge articulaire et activation circulatoire sans impact", "repetitions": "1×30min continue", "intensite": "Très faible — respiration contrôlée", "materiel": "Piscine ou bain froid (si disponible)"},
                {"ordre": 2, "nom": "Yoga & mobilité fonctionnelle", "objectif": "Restauration amplitude articulaire et réduction tensions myofasciales", "repetitions": "45min de séquences guidées", "intensite": "Aucune — étirement progressif", "materiel": "Tapis de sol, rouleau foam"},
                {"ordre": 3, "nom": "Travail vidéo individuel + fixation objectifs", "objectif": "Préparation mentale et tactique du prochain bloc", "repetitions": "30min par joueur avec coach", "intensite": "Mental — pas d'effort physique", "materiel": "Tablette/écran, logiciel d'analyse vidéo"}
            ],
            "medicalAdvice": "Cryothérapie corps entier recommandée si disponible. Contrôle prise de sang (ferritine, vitamine D). Interdire tout effort intense si joueur présente température > 37.5°.",
            "indicateursProgression": ["HRV revenue > baseline personnelle", "Sensation de forme subjective > 8/10", "Motivation retrouvée — testé par questionnaire"],
            "nutritionRecommandee": "Jeûne intermittent optionnel 16h. Curcumine et gingembre anti-inflammatoires. Réhydratation avec électrolytes. Sommeil 9h/nuit cette semaine.",
            "sessionVideoTactique": True,
        },
        {
            "label": "Super-compensation & maintien",
            "focus": "MAINTENANCE",
            "objective": "Exploiter la fenêtre de super-compensation. Maintenir l'état de forme sans surcharger.",
            "trainingVolume": "Modéré — 4 séances / 7h",
            "intensityLevel": "75%-85% VMA — ondulatoire",
            "chargeRpe": 6,
            "ratioTravailRepos": "2:1",
            "keyExercises": [
                {"ordre": 1, "nom": "Test Cooper ou yo-yo IR2", "objectif": "Mesure objective de la condition physique pour ajustements", "repetitions": "1 test complet — 12min ou distance max", "intensite": "Maximale — effort total", "materiel": "Terrain 400m ou piste, chrono, GPS"},
                {"ordre": 2, "nom": "Travail de puissance alactique (sprints)", "objectif": "Entretien explosivité sans produire de fatigue accumulative", "repetitions": "3 séries × 3 sprints 15m — récup 3min", "intensite": "100% vitesse max", "materiel": "Plots chronométrés, terrain sec"},
                {"ordre": 3, "nom": "Match à thème (11v11 ou 9v9)", "objectif": "Application système de jeu — intensité proche match officiel", "repetitions": "2×25min avec arrêts coach", "intensite": "Match-like — 85-95% FCmax", "materiel": "Terrain réglementaire, arbitre, chrono"}
            ],
            "medicalAdvice": "Test Cooper dangereux si joueur non prêt — évaluation médicale préalable obligatoire. Surveillance crampons et revêtement terrain pour éviter entorses.",
            "indicateursProgression": ["Score Cooper > score précédent", "Vitesse sprint 15m ≤ meilleur perso", "Ratio enchainements tactiques réussis > 70%"],
            "nutritionRecommandee": "Périodisation nutritionnelle : hauts glucides les jours d'effort, faibles les jours de repos. Créatine monohydrate 3g/j pour les profils puissance.",
            "sessionVideoTactique": True,
        },
    ]

    for i in range(1, weeks + 1):
        if macro_type == "PRE_SEASON":
            template = pre_season_weeks[(i - 1) % len(pre_season_weeks)]
        elif macro_type == "COMPETITION":
            template = competition_weeks[(i - 1) % len(competition_weeks)]
        else:  # REST
            template = {
                "label": "Repos total — Déconnexion",
                "focus": "RECOVERY",
                "objective": "Régénération totale du système nerveux central et périphérique. Reconstitution des réserves hormonales.",
                "trainingVolume": "Néant — 0 séance structurée",
                "intensityLevel": "0% — repos complet",
                "chargeRpe": 1,
                "ratioTravailRepos": "0:7",
                "keyExercises": [
                    {"ordre": 1, "nom": "Loisirs actifs libres", "objectif": "Maintien de l'activité légère sans contrainte compétitive", "repetitions": "Libre — 30-60min max/jour", "intensite": "Très faible — plaisir pur", "materiel": "Aucun équipement requis"},
                    {"ordre": 2, "nom": "Bilan médical de fin de saison", "objectif": "Détection des pathologies chroniques et axes de prévention pour la saison suivante", "repetitions": "1 séance bilan complète", "intensite": "Non applicable", "materiel": "Cabinet médical, IRM si besoin"},
                    {"ordre": 3, "nom": "Entretien psychologique individuel", "objectif": "Décompression mentale, fixation objectifs N+1, gestion émotionnelle", "repetitions": "1 session 60min par joueur", "intensite": "Mental — non applicable", "materiel": "Psychologue du sport ou coach certifié"}
                ],
                "medicalAdvice": "Interdire toute charge intense. Contrôle hormonal (testostérone/cortisol) si disponible. Aucune décision de renouvellement de contrat cette semaine — impact psychologique négatif prouvé.",
                "indicateursProgression": ["Moral ≥ 8/10 au retour", "Forme corporelle stable (poids)", "Envie de retrouver le terrain"],
                "nutritionRecommandee": "Réduction calorique modérée (-15%) vu la baisse d'activité. Maintien protéines 1.6g/kg pour éviter catabolisme. Pas de régime strict — plaisir alimentaire autorisé.",
                "sessionVideoTactique": False,
            }

        micro_cycles.append({
            "weekNumber": i,
            "label": template["label"],
            "focus": template["focus"],
            "objective": template["objective"],
            "trainingVolume": template["trainingVolume"],
            "intensityLevel": template["intensityLevel"],
            "chargeRpe": template["chargeRpe"],
            "ratioTravailRepos": template["ratioTravailRepos"],
            "keyExercises": template["keyExercises"],
            "medicalAdvice": template["medicalAdvice"],
            "indicateursProgression": template["indicateursProgression"],
            "nutritionRecommandee": template["nutritionRecommandee"],
            "sessionVideoTactique": template["sessionVideoTactique"],
        })

    return {"macro_type": macro_type, "generated_weeks": len(micro_cycles), "micro_cycles": micro_cycles}

class PlayerInput(BaseModel):
    id: str
    name: str
    position: str
    rating: float

class OpponentGenRequest(BaseModel):
    opponent_style: str
    available_players: list[PlayerInput]

@app.post("/tactics/suggest-formation")
def suggest_tactics(req: OpponentGenRequest):
    """V3 Pro: Full tactical analysis - individual/collective instructions, set pieces, locker room speech."""
    style = req.opponent_style.upper()

    # ── STYLES DATA ───────────────────────────────────────────
    style_profiles = {
        "POSSESSION": {
            "formation": "4-2-3-1",
            "justification": "Le double pivot neutralise le milieu de possession adverse et permet de récupérer haut sans s'exposer aux contres.",
            "analyse_adverse": {
                "style_resume": "Équipe qui construit patiemment depuis le bas, cherche à trouver l'espace entre les lignes. Dominant en termes de possession et de rythme.",
                "phase_offensive": "Combinaisons courtes entre CB et MDef pour attirer le pressing, puis passe longue vers l'ailier fixé haut. Le 10 cherche constamment l'espace entre les lignes.",
                "phase_defensive": "Bloc haut organisé, pressing collectif dès perte. Contact immédiat sur le porteur pour empêcher la relance structurée.",
                "transitions": "Transition défensive ultra-rapide — restructuration en 3 secondes. Transition offensive lente et construite.",
                "points_forts": ["Triangle CB-MDef-10 difficile à couper", "Aile gauche dominante avec un ailier créatif", "Récupération haute organisée"],
                "points_faibles": ["Sensible au contre rapide dans le dos du bloc haut", "Latéral droit lent dans le retour défensif", "Peu efficace sur les longs ballons directs"],
                "danger_principal": "Le N.10 dans l'espace entre les lignes — neutraliser ses appels dos au jeu en priorité absolue."
            },
            "bloc_defensif": "Médian",
            "pressing_trigger": "Déclencher le pressing collectif sur la passe vers le latéral gauche adverse — signal : lever de bras du CDM.",
            "axe_offensif": "Flanc droit par le RB en montée + RW en 1v1 contre leur latéral gauche lent.",
            "positions_data": [
                {"role": "GK", "x": 0.5, "y": 0.9, "role_label": "Gardien", "instruction": "Relance LONGUE directement sur le ST pour court-circuiter leur milieu dense. Interdiction de relancer court sous pression — risque perte balle en zone dangereuse.", "actions_cles": ["Couverture zone de la surface sur les centres", "Communication non-stop sur les 1v1 latéraux"], "joueur_adverse": "N°9 adverse — très actif dans le pressing sur gardien dès relance"},
                {"role": "RB", "x": 0.85, "y": 0.75, "role_label": "Latéral droit", "instruction": "Liberté offensive maximale sur le côté droit — leur LB est lent au retour. Monter en soutien de l'ailier, chercher les 2v1. Centre depuis la ligne de fond prioritaire.", "actions_cles": ["2v1 avec RW sur le flanc", "Récupération haute sur leur LB en possession"], "joueur_adverse": "Milieu gauche adverse — peut créer le surnombre sur ton couloir"},
                {"role": "CB", "x": 0.65, "y": 0.8, "role_label": "Défenseur central droit", "instruction": "Sortir haut et agressivement sur le 9 dès qu'il tourne le dos. Ne JAMAIS le laisser se retourner dans l'axe. Relance rapide vers le MDroit dès récupération.", "actions_cles": ["Duel aérien sur corner adverse", "Couverture de la diagonale si le LB monte"], "joueur_adverse": "Ailier gauche adverse — cherche le 1v1 dans le dos du latéral"},
                {"role": "CB", "x": 0.35, "y": 0.8, "role_label": "Défenseur central gauche", "instruction": "Couverture permanente du LB lors de ses montées. Anticiper les longs ballons dans le dos — ligne haute à conserver avec le partenaire CB.", "actions_cles": ["Communiquer les mises hors-jeu avec le CB droit", "Relance courte préférentielle vers le MDef"], "joueur_adverse": "Avant-centre adverse — tendance à décrocher côté gauche"},
                {"role": "LB", "x": 0.15, "y": 0.75, "role_label": "Latéral gauche", "instruction": "Montées DOSÉES — 2 maximum par mi-temps. Toujours vérifier qu'un CB est en couverture avant de monter. Verrouiller le couloir défensivement en priorité.", "actions_cles": ["Centre bas au sol en priorité si montée", "Bloc défensif immédiat dès perte de balle"], "joueur_adverse": "Ailier droit adverse — rapide, cherche le 1v1 dans la profondeur"},
                {"role": "CDM", "x": 0.65, "y": 0.6, "role_label": "Milieu défensif axial droit", "instruction": "Casser les passes vers le N.10. Se positionner EN PERMANENCE entre les lignes pour intercepter. Ne jamais monter si le partenaire CDM n'est pas en couverture.", "actions_cles": ["Pressing sur porteur dès récupération adverse", "Distribution 1 touche pour transition rapide"], "joueur_adverse": "N°10 adverse — cerveau du jeu, à étouffer absolument"},
                {"role": "CDM", "x": 0.35, "y": 0.6, "role_label": "Milieu défensif axial gauche", "instruction": "Essuie-glace — compenser les montées du LB. Couvrir l'espace abandonné par le partenaire CDM en pressing. Sécuriser le centre à 2.", "actions_cles": ["Double pivot en phase défensive", "Appel en profondeur sur transition"], "joueur_adverse": "Milieu droit adverse — très actif dans les récupérations hautes"},
                {"role": "CAM", "x": 0.5, "y": 0.4, "role_label": "Milieu offensif central", "instruction": "Décrocher entre les lignes pour créer le surnombre. Prise de balle dos au jeu, protection et demi-tour immédiat vers l'avant. Frappe de loin si l'espace se présente.", "actions_cles": ["Transmission au sol vers les ailiers", "Pressing déclenché sur le CB adverse en possession"], "joueur_adverse": "MDef adverse — surveiller son positionnement pour les interceptions"},
                {"role": "RW", "x": 0.85, "y": 0.35, "role_label": "Ailier droit", "instruction": "Piquer dans le dos du LB adverse dès récupération. 1v1 — ton meilleur atout côté droit. Centre ou frappe au premier poteau en priorité.", "actions_cles": ["Courses en profondeur derrière la ligne défensive", "2v1 avec RB en montée"], "joueur_adverse": "LB adverse — repérer ses habitudes de montée pour exploiter le dos"},
                {"role": "LW", "x": 0.15, "y": 0.35, "role_label": "Ailier gauche", "instruction": "Rentrer intérieur pour frapper ou créer le surnombre dans l'axe. Fixer le RB adverse pour libérer le LB en montée. Repli défensif immédiat sur perte.", "actions_cles": ["1v1 puis rentrer sur le pied fort", "Bloc défensif si RB adverse en possession"], "joueur_adverse": "RB adverse — noter s'il monte haut ou reste bas"},
                {"role": "ST", "x": 0.5, "y": 0.15, "role_label": "Avant-centre", "instruction": "Jeu de dos — protéger le ballon, temporiser pour laisser monter les milieux. Décrocher côté gauche pour créer 2v1 avec ailier. PRESSING déclencheur sur CB adverse dès relance courte.", "actions_cles": ["Remise de tête sur long ballon", "Pressing pressing CB adverse sur engagement"], "joueur_adverse": "CB central droit adverse — son pied faible est le gauche, l'orienter systématiquement"},
            ],
            "phases_arretees": {
                "corners_pour": "Départ court vers le CAM, centre au 2e poteau — CB vient en retard. Variante : passe à la limite (joueur seul à la bordure de surface).",
                "corners_contre": "Marquage individuel strict sur les 6 meilleurs sauteurs adverses. Libero positionné au point de pénalty contre le retour de balle.",
                "coups_francs_pour": "Tir direct si à moins de 22m. Sinon : combinaison — appel + passe en retrait + frappe.",
                "coups_francs_contre": "Mur de 4 — gardien côté ouvert. Un joueur supplémentaire sur la ligne de but côté gardien."
            },
            "consignes_collectives": {
                "phases_defensives": [
                    "Bloc médian organisé à 4-4-2 dès que leur CB a le ballon en zone centrale",
                    "Pressing collectif déclenché sur la passe vers LB adverse — signal : bras levé du CDM",
                    "Ne jamais défendre en infériorité numérique dans l'axe — compenser systématiquement"
                ],
                "phases_offensives": [
                    "Sortie de balle rapide par le bas — 3-5 passes max avant de jouer vers l'avant",
                    "Attaquer systématiquement le flanc droit (leur faiblesse identifiée) avec 2v1 RB+RW",
                    "Variante longue balle directe sur ST si leur pressing monte trop haut"
                ],
                "transitions_offensives": [
                    "Dès récupération : 3 touches max, vertical immédiat vers ST ou ailiers",
                    "Si récupération dans notre moitié : possession courte pour remonter le bloc adverse"
                ],
                "transitions_defensives": [
                    "Repli immédiat à -6s : tous les joueurs derrière la ligne de balle sans exception",
                    "Le CDM reste en pivot pour casser la première relance adverse"
                ]
            },
            "variantes_selon_score": {
                "si_on_mene": "Bloc bas à 4-5-1, conservation balle, sortie sur contre-attaque rapide côté droit.",
                "si_egalite": "Maintenir le système — ne rien changer avant 70e minute. Conserver l'équilibre.",
                "si_on_perd": "Passage en 3-4-3 dès 60e minute — pressing haut permanent, balles longues directes sur ST."
            },
            "message_vestiaire": "Ce soir, nous affrontons une équipe qui croit que le football se joue avec le ballon. Nous allons leur montrer qu'il se joue aussi sans. Leur latéral gauche est lent — c'est notre autoroute. Chaque contre doit être rapide, précis, impitoyable. Cinq secondes après la récupération, le ballon doit être en zone de finition. On reste organisés, on reste connectés, et on les punit sur leurs erreurs. Ce match est à nous."
        },
        "COUNTER_ATTACK": {
            "formation": "3-5-2",
            "justification": "La défense à 3 sécurise l'axe contre leurs contres rapides. Les pistons bloquent les couloirs et peuvent apporter la largeur offensivement.",
            "analyse_adverse": {
                "style_resume": "Équipe compacte qui défend bas et déclenche des contres ultra-rapides sur 3-4 passes avec des joueurs de vitesse. Dangereuse sur les pertes de balle en phase offensive.",
                "phase_offensive": "Récupération défensive dans leur camp, transition immédiate en 2-3 touches vers les attaquants rapides sur les côtés. Exploitation des espaces laissés derrière notre défense.",
                "phase_defensive": "Bloc bas organisé derrière le ballon — deux lignes de 4 ou 5 très compactes sous 35m. Pressing uniquement sur le porteur si erreur.",
                "transitions": "Transition offensive ultra-rapide (< 5s du but). Transition défensive lente — les attaquants ne pressent pas en bas.",
                "points_forts": ["Vitesse des attaquants de pointe sur les couloirs", "Compacité défensive difficile à percer", "Efficacité redoutables sur les un-contre-un"],
                "points_faibles": ["Peu de possession — peut s'épuiser à défendre longtemps", "Faible en jeu aérien sur les cors (peu de grands gabarits)", "Latéraux hauts lors des contres — espaces dans le dos"],
                "danger_principal": "Les attaquants de vitesse dans le dos de notre défense — ne JAMAIS laisser d'espaces derrière notre ligne défensive."
            },
            "bloc_defensif": "Bas",
            "pressing_trigger": "Presser uniquement si le porteur est dos au jeu ou orienté vers sa propre cage. Sinon rester en bloc compact.",
            "axe_offensif": "Jeu aérien sur les corners et coups francs latéraux — leur faiblesse défensive identifiée. Au sol : combinaisons dans l'axe.",
            "positions_data": [
                {"role": "GK", "x": 0.5, "y": 0.9, "role_label": "Gardien", "instruction": "Sweeper-keeper — sortir sur les ballons dans la profondeur AVANT que leur attaquant ne les atteigne. Communication permanente sur la ligne défensive haute.", "actions_cles": ["Sortie aérienne sur tout ballon dans la surface", "Relance longue immédiate après récupération"], "joueur_adverse": "N°9 adverse — très rapide, attend le ballon dans le dos"},
                {"role": "CB", "x": 0.75, "y": 0.8, "role_label": "Défenseur central droit", "instruction": "Ligne haute et compacte avec les 2 autres CB. Gagner les duels aériens sur les longs ballons adverses. Défendre en reculant face aux attaquants rapides — ne pas sortir seul.", "actions_cles": ["Duel aérien sur chaque long ballon", "Communication mises hors-jeu avec le CB central"], "joueur_adverse": "Ailier gauche adverse — rapide, cherche la profondeur"},
                {"role": "CB", "x": 0.5, "y": 0.82, "role_label": "Défenseur central", "instruction": "Pilier de la défense à 3 — couverture en permanence des partenaires. Organisation de la ligne, déclenchement du hors-jeu. Relance courte préférentielle vers le MDef central.", "actions_cles": ["Lever de bras pour déclencher le hors-jeu", "Relance aérienne en cas de pression forte"], "joueur_adverse": "N°9 adverse — surveiller ses déclarations dans le dos de la ligne"},
                {"role": "CB", "x": 0.25, "y": 0.8, "role_label": "Défenseur central gauche", "instruction": "Couverture du WB gauche lors de ses montées. Interdire les combinaisons entre leur ailier et leur milieu dans ton couloir. Sortir fort sur le porteur qui se retourne.", "actions_cles": ["Couverture des montées du WB gauche", "Duel sol sur leurs ailiers"], "joueur_adverse": "Ailier droit adverse — cherche les 1v1 dans le couloir gauche"},
                {"role": "RWB", "x": 0.9, "y": 0.55, "role_label": "Piston droit", "instruction": "Montées offensives dans le couloir droit pour créer la surnombre. Centre bas au sol priorité. Retour défensif immédiat et systématique sur perte. Ton couloir doit être verrouillé.", "actions_cles": ["Sprint dans le dos de leur LB", "Navigation rapide montée-descente pour fatiguer l'adversaire"], "joueur_adverse": "LB adverse — surveiller s'il monte haut pour exploiter son dos"},
                {"role": "CM", "x": 0.65, "y": 0.55, "role_label": "Milieu central droit", "instruction": "Box-to-box — alterner phases défensives et offensives avec énergie et rigueur. Arriver en retard dans la surface sur les centres depuis la gauche.", "actions_cles": ["Double pivot avec CM gauche en phase défensive", "Frappe de loin si espace"], "joueur_adverse": "Milieu droit adverse — très actif dans les récupérations hautes"},
                {"role": "CM", "x": 0.35, "y": 0.55, "role_label": "Milieu central gauche", "instruction": "Relayeur gauche — sécuriser le jeu en fixant des positions compactes. Éviter les pertes de balle en zone centrale — danger contre immédiat.", "actions_cles": ["Sécuriser les possessions en zone centrale", "Transmission au sol vers WB gauche en montée"], "joueur_adverse": "Milieu gauche adverse — surveiller son positionnement en transition"},
                {"role": "LWB", "x": 0.1, "y": 0.55, "role_label": "Piston gauche", "instruction": "Verrouiller le couloir défensivement — ton adversaire direct est rapide. Monter uniquement sur signal du CM gauche. Centre depuis la ligne de fond en priorité.", "actions_cles": ["1v1 défensif sur leur ailier rapide", "Centre tendu au 2e poteau"], "joueur_adverse": "Ailier droit adverse — très rapide, dangereux en 1v1"},
                {"role": "CAM", "x": 0.5, "y": 0.4, "role_label": "Soutien offensif", "instruction": "Lien entre le milieu et les deux avant-centres. Décrocher pour faciliter les combinaisons. Éviter les pertes de balle — une perte = contre immédiat.", "actions_cles": ["Remise intelligente pour les 2 ST", "Pressing déclenché sur CB adverse en possession haute"], "joueur_adverse": "MDef adverse — son positionnement impacte nos transitions"},
                {"role": "ST", "x": 0.65, "y": 0.2, "role_label": "Avant-centre droit", "instruction": "Axe droit — appels en profondeur côté droit pour étirer leur défense. Jeu dos au but pour temporiser et permettre les montées des pistons. Pressing en dehors de la surface sur leur CB.", "actions_cles": ["Appel en profondeur sur le côté droit", "Pressing CB adverse sur engagement"], "joueur_adverse": "CB central adverse — il sort facilement, exploiter l'espace dans son dos"},
                {"role": "ST", "x": 0.35, "y": 0.2, "role_label": "Avant-centre gauche", "instruction": "Axe gauche — complémentarité avec le partenaire ST. Chercher le 2e poteau sur les centres depuis le côté droit. Duel aérien — leur défense est faible dans les airs.", "actions_cles": ["2e poteau sur les centres", "Remise de tête pour le partenaire"], "joueur_adverse": "CB gauche adverse — faible en duel aérien, le cibler sur les phases arrêtées"}
            ],
            "phases_arretees": {
                "corners_pour": "Corner fort vers le 2e poteau — nos CB sont supérieurs aériennement. Variante : corner brossé court pied gauche.",
                "corners_contre": "Zone défensive stricte — 2 joueurs sur la ligne de but. Attention au résumé court — presser immédiatement.",
                "coups_francs_pour": "Frappe directe si < 25m. Sinon : déviation sur course croisée en bout de mur.",
                "coups_francs_contre": "Mur de 5 contre les frappes directes. Gardien côté ouvert. 1 joueur supplémentaire sur la ligne."
            },
            "consignes_collectives": {
                "phases_defensives": [
                    "Bloc bas organisé à 5-3-2 dès qu'ils ont le ballon dans leur moitié de terrain",
                    "Aucune sortie individuelle — sortir uniquement à 2 sur le porteur",
                    "Ligne défensive à 30m de notre but maximum — ne jamais laisser d'espace dans le dos"
                ],
                "phases_offensives": [
                    "Jeu aérien prioritaire — capitaliser sur notre avantage physique",
                    "Passes dans la profondeur pour les 2 ST dès récupération haute",
                    "Largeur fournie par les pistions — pas par les milieux centraux"
                ],
                "transitions_offensives": [
                    "Dès récupération dans notre bloc : long ballon direct vers l'un des 2 ST",
                    "Si possession : 3-4 passes courtes avant de jouer vers l'avant"
                ],
                "transitions_defensives": [
                    "Repli immédiat ULTRA-rapide — leur danger vient de leur vitesse en transition",
                    "Les 2 ST doivent reculer jusqu'au milieu dès la perte de balle"
                ]
            },
            "variantes_selon_score": {
                "si_on_mene": "Bloc bas à 5-4-1, conserver, ne pas prendre de risque — leur seul atout est le contre.",
                "si_egalite": "Maintenir le système — proposer plus de jeu long vers les ST pour peser sur leur défense.",
                "si_on_perd": "Monter le bloc à médian. 4-3-3 offensif avec pressing haut. Risquer les espaces."
            },
            "message_vestiaire": "Ils misent sur notre impatience. Ils veulent qu'on s'étire, qu'on s'expose, qu'on leur donne les espaces dans notre dos. Ce soir, on les frustre. On est compacts, on est patients, et on les détruit sur les phases arrêtées où ils sont vulnérables. Chaque corner, chaque coup franc, c'est une opportunité de but. Restez organisés, soyez disciplinés, et la victoire viendra naturellement. Ensemble."
        },
        "HIGH_PRESS": {
            "formation": "4-3-3",
            "justification": "La 4-3-3 équilibrée permet de jouer bas et de contrer rapidement — contre-pressing haut inefficace contre notre jeu court et précis.",
            "analyse_adverse": {
                "style_resume": "Équipe ultra-aggressive avec un pressing très haut dès la perte de balle. Cherche à récupérer dans les 6 secondes à 30m du but adverse.",
                "phase_offensive": "Jeu court sous pression, triangles rapides pour sortir du pressing. L'ailier fixe haut pour étirer la défense adverse.",
                "phase_defensive": "Pressing man-to-man très haut avec des joueurs décalés pour couper les passes. Épuisant sur 90 minutes.",
                "transitions": "Transition offensive rapide sur récupération haute — quelques passes pour finir. Transition défensive immédiate after perte.",
                "points_forts": ["Récupérations hautes fréquentes = buts faciles", "Intensité décourageante pour les équipes techniques", "Pressing déclenché systématiquement sur le CB"],
                "points_faibles": ["Épuisement physique en 2e mi-temps", "Espaces dans le dos du bloc lors du pressing", "Latéraux hauts = vulnérables au long ballon"],
                "danger_principal": "Le pressing sur nos CB en phase de relance — une mauvaise relance = but immédiat."
            },
            "bloc_defensif": "Bas à médian",
            "pressing_trigger": "Ne pas presser haut — les laisser venir et jouer long ballon. Contre-pressing déclenché uniquement dans leur moitié.",
            "axe_offensif": "Long ballon direct sur le ST ou RW derrière leur ligne défensive haute — exploiter les espaces dans le dos.",
            "positions_data": [
                {"role": "GK", "x": 0.5, "y": 0.9, "role_label": "Gardien", "instruction": "Long ballon DIRECT dès pression. Ne jamais relancer court sous pression haute. Ballons tendus vers le ST ou les ailiers uniquement. Deuxième ballon — anticiper.", "actions_cles": ["Long ballon techniquement précis sous pression", "Sortie sur 2e ballon après dégagement"], "joueur_adverse": "Attaquant de pressing adverse — surveiller sa trajectoire sur tes relances"},
                {"role": "RB", "x": 0.85, "y": 0.75, "role_label": "Latéral droit", "instruction": "Conserver et transmettre rapidement sous pression. Montées uniquement si leur pressing est cassé et la situation est favorable. Passe courte préférentielle vers le CDM.", "actions_cles": ["1-2 rapide avec le CDM pour échapper au pressing", "Rentrer à l'intérieur si le couloir est saturé"], "joueur_adverse": "Ailier gauche adverse — leur presseur le plus actif sur ton couloir"},
                {"role": "CB", "x": 0.65, "y": 0.8, "role_label": "Défenseur central droit", "instruction": "Ne jamais hésiter à jouer long si le pressing arrive. Dégagement en touche acceptable si aucune solution courte. Ton calme est notre sécurité.", "actions_cles": ["Long ballon décisif sur ST si pressing", "Relance courte vers RB si libre"], "joueur_adverse": "N°9 adverse — leur presseur principal sur les CB"},
                {"role": "CB", "x": 0.35, "y": 0.8, "role_label": "Défenseur central gauche", "instruction": "Identique partenaire — ne pas s'emballer sous pression. Jeu simple : conserver ou jouer long. Communication permanente avec le RB et LB pour les solutions.", "actions_cles": ["Decision rapide sous pression (< 2 secondes)", "Organisation de la ligne haute hors pressing"], "joueur_adverse": "Ailier droit adverse — vient presser le CB en cas de relance courte"},
                {"role": "LB", "x": 0.15, "y": 0.75, "role_label": "Latéral gauche", "instruction": "Appel latéral pour offrir une solution courte aux CB. Si sous pression — jouer en touche plutôt que risquer la perte. Montées dosées quand le pressing est cassé.", "actions_cles": ["Solution courte aux CB sous pression", "Centre bas au sol si montée possible"], "joueur_adverse": "Ailier droit adverse — surveiller ses courses de pressing sur toi"},
                {"role": "CDM", "x": 0.5, "y": 0.6, "role_label": "Milieu défensif", "instruction": "Décrocher entre la défense et leur milieu pour offrir la solution courte aux CB. Pivot de la relance — 1 touche si possible. JAMAIS de prise de risque en zone centrale.", "actions_cles": ["Décrochage pour recevoir entre les lignes", "Distribution 1 touche vers les côtés"], "joueur_adverse": "Milieu adverse — cherche à intercepter tes passes vers les CB"},
                {"role": "CM", "x": 0.7, "y": 0.45, "role_label": "Milieu central droit", "instruction": "Casser les lignes de pressing avec des appels profonds. Si le ballon est joué long, être présent pour le 2e ballon. Jeu simple sous pression — ne pas s'emballer.", "actions_cles": ["Appel profond pour casser le pressing", "Présence sur le 2e ballon"], "joueur_adverse": "MDef adverse — surveille tes déplacements en zone centrale"},
                {"role": "CM", "x": 0.3, "y": 0.45, "role_label": "Milieu central gauche", "instruction": "Soutien à la relance côté gauche. Triangles avec le LB et le LW pour sortir proprement. Si sous pression — garde la balle et protège.", "actions_cles": ["Triangle LB-CM-LW pour sortie de pression", "Protection de balle dos au jeu"], "joueur_adverse": "Milieu droit adverse — très actif dans le contre-pressing"},
                {"role": "RW", "x": 0.85, "y": 0.25, "role_label": "Ailier droit", "instruction": "Fixer le LB adverse TRÈS HAUT pour étirer leur ligne défensive. Appel en profondeur sur long ballon du GK. Le reste du temps — rester haut pour garder la ligne défensive adverse basse.", "actions_cles": ["Appel en profondeur sur long ballon", "Fixer le LB en hauteur pour étirer la défense"], "joueur_adverse": "LB adverse — il monte haut, exploiter son dos sur long ballon"},
                {"role": "LW", "x": 0.15, "y": 0.25, "role_label": "Ailier gauche", "instruction": "Idem RW — fixer haut, appels profonds. Rentrer intérieur si ballon côté droit pour finition. Rester discipliné défensivement — leur pressing est immédiat.", "actions_cles": ["Fixer en hauteur pour étirer la défense", "Rentrée intérieure pour finition"], "joueur_adverse": "RB adverse — surveiller s'il monte pour identifier l'espace dans son dos"},
                {"role": "ST", "x": 0.5, "y": 0.15, "role_label": "Avant-centre", "instruction": "Cible du long ballon direct. Remise de tête pour les milieux en montée. Dos au jeu — protéger et temporiser. Pressing déclenché sur les CB adverses si récupération haute.", "actions_cles": ["Remise de tête sur long ballon", "Appel en profondeur pour casser la ligne"], "joueur_adverse": "CB central adverse — son positionnement haut crée l'espace dans son dos"}
            ],
            "phases_arretees": {
                "corners_pour": "Corner brossé vers le 1er poteau pour déviation + prolongation. Variante : corner court à l'ailier puis centre.",
                "corners_contre": "Marquage zone + libero. Sortie rapide dès récupération pour exploiter leur pressing haut désorganisé.",
                "coups_francs_pour": "Si < 20m : tir direct en puissance. Si > 20m : combinaison ou centre dans la surface.",
                "coups_francs_contre": "Mur de 4. Gardien côté ouvert. Anti-pressing sur récupération — jouer vite."
            },
            "consignes_collectives": {
                "phases_defensives": ["Bloc compact — ne jamais défendre en infériorité dans l'axe", "Pressing uniquement délenché dans leur moitié de terrain", "Longues distances à parcourir = leur épuisement en 2e mi-temps"],
                "phases_offensives": ["Long ballon sur ST ou ailiers dès que leur pressing monte", "Jeu court rapide en triangle dès que la pression est cassée", "Attaque côté droit — leur LB s'épuise en montant haut"],
                "transitions_offensives": ["Long ballon direct sur ST dès récupération sous pression", "Passes rapides si bloc adverse encore désorganisé"],
                "transitions_defensives": ["Repli rapide — leur pressing haut crée des espaces derrière nous", "CDM reste bas même en phase offensive"]
            },
            "variantes_selon_score": {
                "si_on_mene": "Conserver avec bloc médian. Jouer lentement en sortant proprement. Ne surtout pas presser haut.",
                "si_egalite": "Continuer le système. Attendre leur fatigue en 2e mi-temps pour accélérer.",
                "si_on_perd": "Monter notre pressing à médian. Jouer plus vite — 1-2 touches max. Long ballon moins fréquent."
            },
            "message_vestiaire": "Leur pressing est leur arme et leur piège. S'ils pressent haut, c'est qu'il y a de l'espace dans leur dos. On va les laisser venir, jouer simple, et les punir en profondeur. En 2e mi-temps, leur intensité va baisser — notre discipline d'aujourd'hui sera notre victoire de demain. Restez calmes sous pression. Un ballon mal joué n'est pas une faiblesse — une faiblesse, c'est de paniquer. Soyez sereins, soyez précis."
        }
    }

    # Sélection du profil (fallback sur HIGH_PRESS si style inconnu)
    profile = style_profiles.get(style, style_profiles["HIGH_PRESS"])

    available = sorted(req.available_players, key=lambda p: p.rating, reverse=True)
    assigned_players = []

    for pos_data in profile["positions_data"]:
        role = pos_data["role"]
        best_match = next((p for p in available if p.position == role), None)
        if not best_match:
            if role in ["GK"]:
                best_match = next((p for p in available if p.position in ["GK", "DEF"]), available[0] if available else None)
            elif "B" in role or "CB" in role:
                best_match = next((p for p in available if "DEF" in p.position or "B" in p.position), available[0] if available else None)
            elif "M" in role or "DM" in role or "AM" in role:
                best_match = next((p for p in available if "MID" in p.position or "M" in p.position), available[0] if available else None)
            else:
                best_match = next((p for p in available if "ATT" in p.position or "ST" in p.position or "W" in p.position), available[0] if available else None)

        if best_match:
            available.remove(best_match)
            player_id = best_match.id
            player_name = best_match.name
        else:
            player_id = None
            player_name = "Poste non pourvu"

        assigned_players.append({
            "player_id": player_id,
            "player_name": player_name,
            "role": role,
            "role_label": pos_data["role_label"],
            "x": pos_data["x"],
            "y": pos_data["y"],
            "instruction": pos_data["instruction"],
            "actions_cles": pos_data["actions_cles"],
            "joueur_adverse_a_surveiller": pos_data["joueur_adverse"],
        })

    return {
        "formation": profile["formation"],
        "formation_justification": profile["justification"],
        "analyse_adverse": profile["analyse_adverse"],
        "instructions": profile["analyse_adverse"]["style_resume"],
        "strengths": profile["analyse_adverse"]["points_forts"],
        "weaknesses": profile["analyse_adverse"]["points_faibles"],
        "danger_principal": profile["analyse_adverse"]["danger_principal"],
        "bloc_defensif": profile["bloc_defensif"],
        "pressing_trigger": profile["pressing_trigger"],
        "axe_offensif": profile["axe_offensif"],
        "phases_arretees": profile["phases_arretees"],
        "starting_xi": assigned_players,
        "consignes_collectives": profile["consignes_collectives"],
        "variantes_selon_score": profile["variantes_selon_score"],
        "message_vestiaire": profile["message_vestiaire"],
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

