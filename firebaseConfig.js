// firebaseConfig.js
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyBlzMSfjaaUJayejWynJ5Lc-zfo6x-rGPo",
  authDomain: "carpoolfypapp.firebaseapp.com",
  projectId: "carpoolfypapp",
  storageBucket: "carpoolfypapp.appspot.com",
  messagingSenderId: "343162898509",
  appId: "1:343162898509:android:63d1b6f5f20325503f3404",
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
