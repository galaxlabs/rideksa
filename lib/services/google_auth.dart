import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'google_auth_mobile.dart'
    if (dart.library.html) 'google_auth_web.dart';

Future<fb.UserCredential> signInWithGoogleProvider(fb.FirebaseAuth auth) =>
    signInWithGooglePlatform(auth);

Future<fb.UserCredential?> getGoogleRedirectResult(fb.FirebaseAuth auth) =>
    getGoogleRedirectResultPlatform(auth);
