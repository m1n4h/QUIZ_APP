import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';

class GoogleSignInHelper {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );

  static Future<Map<String, dynamic>?> signIn() async {
    try {
      print('Starting Google Sign-In...');
      
      // First, try to sign out any existing user
      await _googleSignIn.signOut();
      
      // Sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('User cancelled Google Sign-In');
        Get.snackbar(
          'Cancelled',
          'Google sign-in was cancelled',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return null;
      }
      
      print('Google user obtained: ${googleUser.email}');
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      print('Google auth obtained');
      print('Access token: ${googleAuth.accessToken?.substring(0, 20)}...');
      print('ID token: ${googleAuth.idToken?.substring(0, 20)}...');
      
      // Return user data
      return {
        'email': googleUser.email,
        'name': googleUser.displayName ?? 'Google User',
        'googleId': googleUser.id,
        'profileImage': googleUser.photoUrl,
        'accessToken': googleAuth.accessToken,
        'idToken': googleAuth.idToken,
      };
      
    } on Exception catch (error) {
      print('Google Sign-In Error: $error');
      
      String errorMessage = error.toString();
      if (error.toString().contains('ApiException: 10')) {
        errorMessage = 'Configuration error: SHA-1 fingerprint or Client ID mismatch. Please check your google-services.json';
      } else if (error.toString().contains('ApiException: 12501')) {
        errorMessage = 'Sign-in cancelled by user';
      }
      
      Get.snackbar(
        'Google Sign-In Failed',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('Google Sign-Out successful');
    } catch (error) {
      print('Google Sign-Out Error: $error');
    }
  }

  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }

  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}