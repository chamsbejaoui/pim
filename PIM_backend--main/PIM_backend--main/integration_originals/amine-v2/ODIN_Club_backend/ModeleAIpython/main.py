import os
import json
import joblib
import numpy as np
from fastapi import FastAPI
from pydantic import BaseModel
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
# API Endpoints
# ==========================

@app.get("/")
def home():
    return {"message": "Antigravity AI Pro v4.0 — LightGBM + SHAP + Insights 🚀"}

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
