import mongoose from 'mongoose';
import * as dotenv from 'dotenv';

dotenv.config();

async function run() {
  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    console.error('MONGO_URI is not set in environment!');
    return;
  }

  console.log('Connecting to MongoDB...');
  await mongoose.connect(mongoUri);

  try {
    console.log('Dropping index "name_1" from companies collection...');
    const db = mongoose.connection.db;
    if (!db) {
      throw new Error('Database connection is not open');
    }
    await db.collection('companies').dropIndex('name_1');
    console.log('Successfully dropped index "name_1"!');
  } catch (error: any) {
    if (error.codeName === 'IndexNotFound' || error.message?.includes('index not found')) {
      console.log('Index "name_1" does not exist or was already dropped.');
    } else {
      console.error('Failed to drop index:', error);
    }
  } finally {
    await mongoose.connection.close();
    console.log('Connection closed.');
  }
}

run();
