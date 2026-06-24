const path = require('path');
require('dotenv').config();

const { db, isFirebaseConfigured } = require('./src/config/firebase.js');

async function checkReviews() {
  console.log('Is Firebase configured:', isFirebaseConfigured);
  if (!db) {
    console.error('Database connection not available.');
    return;
  }
  try {
    // Let's get all documents in reviews collection
    const reviewsSnapshot = await db.collection('reviews').get();
    console.log(`Total documents in 'reviews' collection: ${reviewsSnapshot.size}`);
    
    for (const doc of reviewsSnapshot.docs) {
      console.log(`Product reviews document ID: ${doc.id}`);
      // Get subcollection 'items'
      const itemsSnapshot = await doc.ref.collection('items').get();
      console.log(`  Subcollection 'items' size: ${itemsSnapshot.size}`);
      for (const itemDoc of itemsSnapshot.docs) {
        console.log(`    Review:`, JSON.stringify(itemDoc.data(), null, 2));
      }
    }
  } catch (error) {
    console.error('Error fetching reviews:', error);
  }
}

checkReviews();
