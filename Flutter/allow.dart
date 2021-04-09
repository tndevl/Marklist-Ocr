import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Allow {
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<bool> start() async {
    bool ok;
    if (FirebaseAuth.instance.currentUser == null) {
      await signInWithGoogle();
    }
    if (FirebaseAuth.instance.currentUser != null) {
      ok = true;
    }
    return ok;
  }

  Future<void> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
