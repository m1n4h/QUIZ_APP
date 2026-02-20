import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Configure for web if needed
    // clientId: 'YOUR_CLIENT_ID.apps.googleusercontent.com', // For web
    serverClientId: '460380605476-a2ggvf8m10d8g7451fkanvb6hq41sq1f.apps.googleusercontent.com',

  );

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser != null) {
        // Get user details
        final GoogleSignInAuthentication googleAuth = 
            await googleUser.authentication;
        
        // Print user info for debugging
        print('Google User: ${googleUser.email}');
        print('Google Display Name: ${googleUser.displayName}');
        print('Google ID: ${googleUser.id}');
        print('Google Photo URL: ${googleUser.photoUrl}');
        print('Google Auth Token: ${googleAuth.accessToken}');
        print('Google ID Token: ${googleAuth.idToken}');
        
        return googleUser;
      }
    } catch (error) {
      print('Google Sign-In Error: $error');
      Get.snackbar(
        'Google Sign-In Failed',
        error.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    return null;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }

  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}