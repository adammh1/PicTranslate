import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow; 
    }
  }

  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;

        final OAuthCredential credential =
            FacebookAuthProvider.credential(accessToken.tokenString);

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        return userCredential.user;
      } else if (result.status == LoginStatus.cancelled) {
        print('Facebook login cancelled by user.');
        return null;
      } else {
        print('Facebook login failed: ${result.message}');
        return null;
      }
    } catch (e) {
      print('Error signing in with Facebook: $e');
      rethrow;
    }
  }

  Future<User?> registerWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print('Error registering with Google: $e');
      rethrow;
    }
  }

  Future<User?> registerWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;

        final OAuthCredential credential =
            FacebookAuthProvider.credential(accessToken.tokenString);

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        return userCredential.user;
      } else if (result.status == LoginStatus.cancelled) {
        print('Facebook registration cancelled by user.');
        return null;
      } else {
        print('Facebook registration failed: ${result.message}');
        return null;
      }
    } catch (e) {
      print('Error registering with Facebook: $e');
      rethrow;
    }
  }
}

 