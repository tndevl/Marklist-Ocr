import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'widgets.dart';
import 'package:provider/provider.dart';
import 'allow.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with WidgetsBindingObserver {
  signInWithGoogle() async {
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

  signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  int current;

  Widget build(BuildContext context) {
    var user = Provider.of<User>(context);
    var connection = Provider.of<ConnectivityResult>(context);
    return Scaffold(
        appBar: UniBar('User Profile'),
        body: Column(children: [
          if (user != null && connection != ConnectivityResult.none) ...[
            Center(
              child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(user.photoURL)),
            ),
            Center(
              child: ClipRRect(
                child: FlatButton(
                  onPressed: () async {
                    await Allow().signInWithGoogle();
                  },
                  child: Text('Change User'),
                ),
              ),
            ),
            Center(
              child: ClipRRect(
                child: Align(
                  alignment: Alignment.center,
                  child: FlatButton(
                    onPressed: () async {
                      await signOut();
                    },
                    child: Text('Sign out'),
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          ],
          if (user == null && connection != ConnectivityResult.none) ...[
            Center(child: Icon(Icons.account_circle)),
            Center(
              child: ClipRRect(
                child: FlatButton(
                  onPressed: () async {
                    await Allow().signInWithGoogle();
                  },
                  child: Text('Sign in'),
                  color: Colors.grey[600],
                ),
              ),
            )
          ],
          if (connection == ConnectivityResult.none) ...[
            Center(
                child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Icon(Icons.signal_wifi_off), Text('No connection')],
            ))
          ]
        ]));
  }
}
