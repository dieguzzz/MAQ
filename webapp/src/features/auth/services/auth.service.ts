import {
  signInWithPopup,
  GoogleAuthProvider,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  sendPasswordResetEmail,
} from "firebase/auth";
import { auth } from "@/lib/firebase/client";

const googleProvider = new GoogleAuthProvider();

export const authService = {
  signInWithGoogle: () => signInWithPopup(auth, googleProvider),

  signInWithEmail: (email: string, password: string) =>
    signInWithEmailAndPassword(auth, email, password),

  signUpWithEmail: (email: string, password: string) =>
    createUserWithEmailAndPassword(auth, email, password),

  signOut: () => signOut(auth),

  resetPassword: (email: string) => sendPasswordResetEmail(auth, email),
};
