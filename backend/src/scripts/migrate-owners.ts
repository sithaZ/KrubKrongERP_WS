import mongoose from 'mongoose';
import * as dotenv from 'dotenv';
import { User, UserSchema } from '../users/user.entity';

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
    const userModel = mongoose.model(User.name, UserSchema);

    // Get all users
    const users = await userModel.find({}).exec();
    console.log(`Found ${users.length} total users in the database:`);

    let updatedCount = 0;

    for (const user of users) {
      console.log(`- User: "${user.name}", Role: "${user.role}", Email: "${user.email}"`);
      
      // If the user's name/username contains "owner" (case-insensitive) or role is manager (case-insensitive)
      const nameMatch = user.name?.toLowerCase().includes('owner') || user.username?.toLowerCase().includes('owner');
      const roleMatch = user.role?.toLowerCase() === 'manager';

      if ((nameMatch || roleMatch) && user.role !== 'OWNER') {
        console.log(`  --> Updating user "${user.name}" role from "${user.role}" to "OWNER"...`);
        user.role = 'OWNER';
        await user.save();
        updatedCount++;
      }
    }

    console.log(`Migration complete! Successfully updated ${updatedCount} users to OWNER.`);
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await mongoose.connection.close();
    console.log('Connection closed.');
  }
}

run();
