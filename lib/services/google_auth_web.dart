import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;

Future<fb.UserCredential> signInWithGooglePlatform(fb.FirebaseAuth auth) async {
  await auth.signInWithRedirect(fb.GoogleAuthProvider());
  throw fb.FirebaseAuthException(
    code: 'redirect-started',
    message: 'Redirecting to Google sign-in.',
  );
}

Future<fb.UserCredential?> getGoogleRedirectResultPlatform(fb.FirebaseAuth auth) async {
  try {
    return await auth.getRedirectResult().timeout(const Duration(seconds: 4));
  } on TimeoutException {
    return null;
  }
}
