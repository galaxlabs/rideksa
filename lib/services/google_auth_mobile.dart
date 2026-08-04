import 'package:firebase_auth/firebase_auth.dart' as fb;

Future<fb.UserCredential> signInWithGooglePlatform(fb.FirebaseAuth auth) async {
  return auth.signInWithProvider(fb.GoogleAuthProvider());
}

Future<fb.UserCredential?> getGoogleRedirectResultPlatform(fb.FirebaseAuth auth) async {
  return null;
}
