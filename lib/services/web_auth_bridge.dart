import 'package:firebase_auth/firebase_auth.dart' as fb;

Future<Map<String, dynamic>?> webSignInWithEmailPassword(String email, String password) async {
  final credential = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  final user = credential.user;
  if (user == null) return null;
  return {
    'uid': user.uid,
    'email': user.email ?? '',
    'displayName': user.displayName ?? '',
  };
}
