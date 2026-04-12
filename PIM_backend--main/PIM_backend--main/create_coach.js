const { MongoClient } = require('mongodb');
const bcrypt = require('bcrypt');

async function run() {
  const uri = "mongodb://127.0.0.1:27017";
  const client = new MongoClient(uri);
  try {
    await client.connect();
    const db = client.db("odin_backend");
    const users = db.collection("users");

    const email = "coach@odin.com";
    const existing = await users.findOne({ email });
    
    if (existing) {
      console.log("Coach user already exists.");
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash("coach123", salt);

    const newUser = {
      email,
      passwordHash,
      firstName: "Entraîneur",
      lastName: "Principal",
      phone: "0600000000",
      jobTitle: "Head Coach",
      role: "STAFF_TECHNIQUE", // STAFF_TECHNIQUE is the enum for coach
      status: "ACTIVE",
      isActive: true,
      isEmailVerified: true,
      isApprovedByAdmin: true,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const result = await users.insertOne(newUser);
    console.log(`Successfully inserted coach user with _id: ${result.insertedId}`);
    console.log(`Email: ${email}`);
    console.log(`Password: coach123`);
  } catch(e) {
    console.error(e);
  } finally {
    await client.close();
  }
}

run().catch(console.dir);
