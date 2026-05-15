"use client";

import { initializeApp, getApps, type FirebaseApp } from "firebase/app";
import { getAuth, type Auth } from "firebase/auth";
import { getFirestore, type Firestore } from "firebase/firestore";
import { getStorage, type FirebaseStorage } from "firebase/storage";
import { getAnalytics, isSupported } from "firebase/analytics";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  measurementId: process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID,
};

let _app: FirebaseApp | null = null;
let _auth: Auth | null = null;
let _db: Firestore | null = null;
let _storage: FirebaseStorage | null = null;

function getApp(): FirebaseApp {
  if (_app) return _app;
  if (!firebaseConfig.apiKey) {
    throw new Error(
      "Firebase no configurado. Define NEXT_PUBLIC_FIREBASE_* en el entorno."
    );
  }
  _app = getApps().length ? getApps()[0]! : initializeApp(firebaseConfig);
  return _app;
}

export const auth = new Proxy({} as Auth, {
  get(_t, prop) {
    if (!_auth) _auth = getAuth(getApp());
    return Reflect.get(_auth, prop, _auth);
  },
});

export const db = new Proxy({} as Firestore, {
  get(_t, prop) {
    if (!_db) _db = getFirestore(getApp());
    return Reflect.get(_db, prop, _db);
  },
});

export const storage = new Proxy({} as FirebaseStorage, {
  get(_t, prop) {
    if (!_storage) _storage = getStorage(getApp());
    return Reflect.get(_storage, prop, _storage);
  },
});

export const analyticsPromise =
  typeof window !== "undefined"
    ? isSupported().then((yes) => (yes ? getAnalytics(getApp()) : null))
    : Promise.resolve(null);
