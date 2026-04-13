const { MongoClient, ObjectId } = require('mongodb');

async function run() {
  const client = new MongoClient('mongodb://127.0.0.1:27017');

  try {
    await client.connect();
    const db = client.db('odin_backend');
    const squads = db.collection('squads');

    const playerIds = [
      '69c713cac739d6d8686246af',
      '69c713cac739d6d8686246b0',
      '69c713cac739d6d8686246b1',
      '69c713cac739d6d8686246b2',
      '69c713cac739d6d8686246b3',
      '69c713cac739d6d8686246b4',
      '69c713cac739d6d8686246b5',
      '69c713cac739d6d8686246b6',
      '69c713cac739d6d8686246b7',
      '69c713cac739d6d8686246b8',
      '69c713cac739d6d8686246b9',
      '69c713cac739d6d8686246ba',
      '69c713cac739d6d8686246bb',
      '69c713cac739d6d8686246bc',
      '69c713cac739d6d8686246bd',
      '69c713cac739d6d8686246be',
      '69c713cac739d6d8686246bf',
      '69c713cac739d6d8686246c0',
      '69c713cac739d6d8686246c1',
      '69c713cac739d6d8686246c2',
      '69c713cac739d6d8686246c3',
      '69c713cac739d6d8686246c4',
      '69c713cac739d6d8686246c5',
      '69c713cac739d6d8686246c6'
    ].map((id) => new ObjectId(id));

    const starterIds = [
      '69c713cac739d6d8686246af',
      '69c713cac739d6d8686246b2',
      '69c713cac739d6d8686246b3',
      '69c713cac739d6d8686246b4',
      '69c713cac739d6d8686246b7',
      '69c713cac739d6d8686246b9',
      '69c713cac739d6d8686246ba',
      '69c713cac739d6d8686246bb',
      '69c713cac739d6d8686246c3',
      '69c713cac739d6d8686246c0',
      '69c713cac739d6d8686246c1'
    ].map((id) => new ObjectId(id));

    const benchIds = [
      '69c713cac739d6d8686246b1',
      '69c713cac739d6d8686246b5',
      '69c713cac739d6d8686246b8',
      '69c713cac739d6d8686246be',
      '69c713cac739d6d8686246bc',
      '69c713cac739d6d8686246bd',
      '69c713cac739d6d8686246c2',
      '69c713cac739d6d8686246c5'
    ].map((id) => new ObjectId(id));

    const reserveIds = [
      '69c713cac739d6d8686246b0',
      '69c713cac739d6d8686246b6',
      '69c713cac739d6d8686246bf',
      '69c713cac739d6d8686246c4',
      '69c713cac739d6d8686246c6'
    ].map((id) => new ObjectId(id));

    const now = new Date();
    const result = await squads.updateOne(
      { season: '2026-2027' },
      {
        $set: {
          season: '2026-2027',
          label: 'Squad principal seed',
          playerIds,
          starterIds,
          benchIds,
          reserveIds,
          targetSquadSize: 24,
          updatedAt: now
        },
        $setOnInsert: { createdAt: now }
      },
      { upsert: true }
    );

    console.log('Squad seed completed');
    console.log(
      JSON.stringify(
        {
          matched: result.matchedCount,
          modified: result.modifiedCount,
          upserted: result.upsertedCount
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
