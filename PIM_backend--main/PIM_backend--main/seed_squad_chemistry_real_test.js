const { MongoClient, ObjectId } = require('mongodb');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017';
const DB_NAME = process.env.DB_NAME || 'odin_backend';
const SEASON = process.env.SEASON || '2026-2027';

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, Number(value.toFixed(2))));
}

function bucket(position = '') {
  const upper = position.toUpperCase();
  if (upper.includes('GK')) return 'GK';
  if (['CB', 'LB', 'RB', 'LWB', 'RWB'].some((token) => upper.includes(token))) return 'DEF';
  if (['CDM', 'CM', 'CAM', 'DM', 'AM', 'LM', 'RM'].some((token) => upper.includes(token))) return 'MID';
  if (['LW', 'RW', 'ST', 'CF', 'FW'].some((token) => upper.includes(token))) return 'ATT';
  return 'OTHER';
}

function corridor(position = '') {
  const upper = position.toUpperCase();
  if (upper.includes('L')) return 'LEFT';
  if (upper.includes('R')) return 'RIGHT';
  return 'CENTER';
}

function hashString(value) {
  let hash = 0;
  for (let index = 0; index < value.length; index += 1) {
    hash = (hash * 31 + value.charCodeAt(index)) % 1000003;
  }
  return hash;
}

function seededOffset(key, spread) {
  const normalized = (hashString(key) % 1000) / 1000;
  return (normalized * 2 - 1) * spread;
}

function playerDisplayName(player) {
  return player.name || `${player.firstName || ''} ${player.lastName || ''}`.trim() || String(player._id);
}

function qualityScore(player) {
  const speed = Number(player.speed || 0);
  const endurance = Number(player.endurance || 0);
  const dribbles = Number(player.dribbles || 0);
  const shots = Number(player.shots || 0);
  const role = bucket(player.position);

  if (role === 'GK') {
    return clamp(60 + endurance * 0.08 + speed * 0.05, 55, 92);
  }

  const technical = dribbles * 0.25 + shots * 0.25;
  const physical = speed * 0.25 + endurance * 0.25;
  const roleBonus =
    role === 'ATT' ? 6 : role === 'MID' ? 4.5 : role === 'DEF' ? 3.5 : 2;

  return clamp(58 + technical + physical * 0.55 + roleBonus, 58, 94);
}

function buildStatistics(player, rank) {
  const quality = qualityScore(player);
  const role = bucket(player.position);
  const eventBase =
    role === 'GK' ? 34 : role === 'DEF' ? 39 : role === 'MID' ? 43 : 41;
  const totalEvents = Math.round(eventBase + seededOffset(`${player._id}:events`, 4));
  const averageScore = clamp(6.4 + (quality - 60) / 18 + seededOffset(`${player._id}:avg`, 0.18), 6.3, 9.35);
  const bestScore = clamp(averageScore + 0.45 + Math.abs(seededOffset(`${player._id}:best`, 0.35)), averageScore, 9.9);

  return {
    totalEvents,
    averageScore,
    bestScore,
    rank: `#${rank}`
  };
}

function buildStyleProfile(player) {
  const role = bucket(player.position);
  const speed = Number(player.speed || 0);
  const dribbles = Number(player.dribbles || 0);
  const shots = Number(player.shots || 0);
  const foot = (player.strongFoot || '').toLowerCase();

  const base = {
    possessionPlay: 5.5,
    selfishness: 4.8,
    oneTouchPreference: 5.5,
    directPlay: 5.4,
    riskTaking: 5.1,
    pressingIntensity: 5.6,
    offBallMovement: 5.7,
    communication: 5.9,
    defensiveDiscipline: 5.7,
    creativity: 5.1
  };

  if (role === 'GK') {
    Object.assign(base, {
      possessionPlay: 5.2,
      selfishness: 2.5,
      oneTouchPreference: 6.3,
      directPlay: 6.1,
      riskTaking: 4.2,
      pressingIntensity: 2.5,
      offBallMovement: 2.1,
      communication: 8.2,
      defensiveDiscipline: 8.8,
      creativity: 3.6
    });
  } else if (role === 'DEF') {
    Object.assign(base, {
      possessionPlay: 5.8,
      selfishness: 3.8,
      oneTouchPreference: 6.2,
      directPlay: 5.3,
      riskTaking: 4.9,
      pressingIntensity: 6.5,
      offBallMovement: 5.1,
      communication: 6.9,
      defensiveDiscipline: 8.4,
      creativity: corridor(player.position) === 'CENTER' ? 4.2 : 5.6
    });
  } else if (role === 'MID') {
    Object.assign(base, {
      possessionPlay: 7.3,
      selfishness: 4.4,
      oneTouchPreference: 7.1,
      directPlay: 6.4,
      riskTaking: 6.1,
      pressingIntensity: 7.1,
      offBallMovement: 6.8,
      communication: 7.4,
      defensiveDiscipline: player.position?.toUpperCase().includes('CDM') ? 8.1 : 6.3,
      creativity: player.position?.toUpperCase().includes('CAM') ? 8.4 : 7.1
    });
  } else if (role === 'ATT') {
    Object.assign(base, {
      possessionPlay: 6.4,
      selfishness: 5.9,
      oneTouchPreference: 6.3,
      directPlay: 7.8,
      riskTaking: 7.2,
      pressingIntensity: 6.2,
      offBallMovement: 8.2,
      communication: 6.2,
      defensiveDiscipline: 4.2,
      creativity: corridor(player.position) === 'CENTER' ? 6.5 : 8.5
    });
  }

  base.directPlay = clamp(base.directPlay + (speed - 75) / 25, 0, 10);
  base.creativity = clamp(base.creativity + (dribbles - 20) / 20, 0, 10);
  base.selfishness = clamp(base.selfishness + (shots - 15) / 25, 0, 10);
  base.oneTouchPreference = clamp(base.oneTouchPreference + (foot === 'left' ? 0.2 : 0), 0, 10);

  return Object.fromEntries(
    Object.entries(base).map(([key, value]) => [key, clamp(value, 0, 10)])
  );
}

function chemistryBoostByNames(nameA, nameB) {
  const key = [nameA, nameB].sort().join('::');
  const boosts = new Map([
    [['Achraf Hakimi', 'Mohamed Salah'].sort().join('::'), 0.7],
    [['Jude Bellingham', 'Kylian Mbappe'].sort().join('::'), 0.9],
    [['Jude Bellingham', 'Vinicius Junior'].sort().join('::'), 0.85],
    [['Kevin De Bruyne', 'Erling Haaland'].sort().join('::'), 1.45],
    [['Rodri', 'Kevin De Bruyne'].sort().join('::'), 1.25],
    [['Theo Hernandez', 'Kylian Mbappe'].sort().join('::'), 1.05],
    [['Virgil van Dijk', 'Mohamed Salah'].sort().join('::'), 0.8]
  ]);

  return boosts.get(key) || 0;
}

function tacticalZone(playerA, playerB) {
  const left = corridor(playerA.position);
  const right = corridor(playerB.position);
  if (left === right && left !== 'CENTER') {
    return `${left.toLowerCase()} corridor`;
  }
  if (bucket(playerA.position) === 'DEF' && bucket(playerB.position) === 'DEF') {
    return 'defensive line';
  }
  if (bucket(playerA.position) === 'MID' && bucket(playerB.position) === 'MID') {
    return 'central midfield';
  }
  if (bucket(playerA.position) === 'ATT' || bucket(playerB.position) === 'ATT') {
    return 'final third';
  }
  return 'build-up phase';
}

function buildChemistry(playerA, playerB, starters) {
  const nameA = playerDisplayName(playerA);
  const nameB = playerDisplayName(playerB);
  const bucketA = bucket(playerA.position);
  const bucketB = bucket(playerB.position);
  const corridorA = corridor(playerA.position);
  const corridorB = corridor(playerB.position);
  const bothStarters = starters.has(String(playerA._id)) && starters.has(String(playerB._id));

  let score = 5.35;

  if (playerA.nationality && playerA.nationality === playerB.nationality) score += 1.1;
  if (bucketA === bucketB) score += bucketA === 'GK' ? -1.8 : 0.35;
  if (playerA.position === playerB.position) score += playerA.position === 'CB' ? 0.85 : -0.55;
  if (corridorA === corridorB && corridorA !== 'CENTER') score += 0.55;
  if (corridorA === 'CENTER' && corridorB === 'CENTER') score += 0.4;

  const positionPair = [playerA.position, playerB.position].sort().join('::');
  const pairBonuses = new Map([
    [['LB', 'LW'].sort().join('::'), 1.55],
    [['RB', 'RW'].sort().join('::'), 1.55],
    [['CB', 'GK'].sort().join('::'), 1.2],
    [['CB', 'CB'].sort().join('::'), 0.95],
    [['CAM', 'ST'].sort().join('::'), 1.35],
    [['CDM', 'CB'].sort().join('::'), 0.9],
    [['CDM', 'CM'].sort().join('::'), 0.8],
    [['CM', 'LW'].sort().join('::'), 0.35],
    [['CM', 'RW'].sort().join('::'), 0.35],
    [['LW', 'ST'].sort().join('::'), 1.0],
    [['RW', 'ST'].sort().join('::'), 1.0]
  ]);
  score += pairBonuses.get(positionPair) || 0;

  if (bucketA === 'GK' && bucketB === 'GK') score -= 1.2;
  if (bucketA === 'ATT' && bucketB === 'ATT' && playerA.position === playerB.position) score -= 0.8;

  score += chemistryBoostByNames(nameA, nameB);
  if (bothStarters) score += 0.45;

  const qualityGap = Math.abs(qualityScore(playerA) - qualityScore(playerB));
  score -= Math.min(qualityGap / 25, 0.45);
  score += seededOffset(`${playerA._id}:${playerB._id}:chem`, 0.38);

  const rating = clamp(score, 3.4, 9.75);
  const observationCount = bothStarters
    ? Math.round(8 + Math.abs(seededOffset(`${playerA._id}:${playerB._id}:obs`, 4)))
    : Math.round(4 + Math.abs(seededOffset(`${playerA._id}:${playerB._id}:obs`, 3)));
  const lastRating = clamp(rating + seededOffset(`${playerA._id}:${playerB._id}:last`, 0.45), 0, 10);
  const aiScore = clamp((rating * 0.82) + 0.9 + seededOffset(`${playerA._id}:${playerB._id}:ai`, 0.25), 0, 10);

  let note = 'Stable relation to monitor in competitive sessions.';
  if (rating >= 8.6) {
    note = 'High-trust connection with repeatable automatisms.';
  } else if (rating <= 4.6) {
    note = 'Low natural cohesion. Needs controlled tactical exposure.';
  }

  return {
    averageRating: rating,
    lastRating,
    observationCount,
    aiScore,
    aiScoreVersion: 'rule-based-seed-v1',
    observedBy: 'codex-real-test-seed',
    tacticalZone: tacticalZone(playerA, playerB),
    notes: note
  };
}

async function run() {
  const client = new MongoClient(MONGO_URI);

  try {
    await client.connect();
    const db = client.db(DB_NAME);
    const playersCollection = db.collection('players');
    const squadsCollection = db.collection('squads');
    const pairsCollection = db.collection('chemistry_pairs');
    const profilesCollection = db.collection('player_style_profiles');

    const squad = await squadsCollection.findOne({ season: SEASON });
    if (!squad) {
      throw new Error(`No squad found for season "${SEASON}"`);
    }

    const squadIds = (squad.playerIds || []).map((id) => new ObjectId(String(id)));
    const players = await playersCollection.find({ _id: { $in: squadIds } }).toArray();
    if (players.length !== squadIds.length) {
      throw new Error(`Expected ${squadIds.length} squad players, found ${players.length}`);
    }

    const starterIds = new Set((squad.starterIds || []).map(String));
    const sortedByQuality = [...players].sort((left, right) => qualityScore(right) - qualityScore(left));
    const rankById = new Map(sortedByQuality.map((player, index) => [String(player._id), index + 1]));

    for (const player of players) {
      await playersCollection.updateOne(
        { _id: player._id },
        {
          $set: {
            status: 'active',
            statistics: buildStatistics(player, rankById.get(String(player._id)) || players.length)
          }
        }
      );

      const styleProfile = buildStyleProfile(player);
      await profilesCollection.updateOne(
        { season: SEASON, playerId: player._id },
        {
          $set: {
            season: SEASON,
            playerId: player._id,
            ...styleProfile,
            preferredStyles: [bucket(player.position), corridor(player.position)].filter(Boolean),
            notes: `Auto-generated real-test profile for ${playerDisplayName(player)}.`,
            updatedBy: 'codex-real-test-seed',
            updatedAt: new Date()
          },
          $setOnInsert: { createdAt: new Date() }
        },
        { upsert: true }
      );
    }

    let pairWrites = 0;
    for (let i = 0; i < players.length; i += 1) {
      for (let j = i + 1; j < players.length; j += 1) {
        const playerA = players[i];
        const playerB = players[j];
        const [aId, bId] = [String(playerA._id), String(playerB._id)].sort((a, b) => a.localeCompare(b));
        const chemistry = buildChemistry(playerA, playerB, starterIds);

        await pairsCollection.updateOne(
          { season: SEASON, pairKey: `${aId}:${bId}` },
          {
            $set: {
              season: SEASON,
              playerAId: new ObjectId(aId),
              playerBId: new ObjectId(bId),
              pairKey: `${aId}:${bId}`,
              ...chemistry,
              aiScoreComputedAt: new Date(),
              lastObservedAt: new Date(),
              updatedAt: new Date()
            },
            $setOnInsert: { createdAt: new Date() }
          },
          { upsert: true }
        );
        pairWrites += 1;
      }
    }

    const playerStatsCount = await playersCollection.countDocuments({
      _id: { $in: squadIds },
      'statistics.averageScore': { $exists: true }
    });
    const profileCount = await profilesCollection.countDocuments({ season: SEASON });
    const pairCount = await pairsCollection.countDocuments({ season: SEASON });

    console.log(
      JSON.stringify(
        {
          season: SEASON,
          squadPlayers: players.length,
          playerStatsCount,
          profileCount,
          pairCount,
          pairWrites
        },
        null,
        2
      )
    );
  } finally {
    await client.close();
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
