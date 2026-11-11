import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._auth);

  // Supabase.instance.client.auth: the part of Supabase that handles users.
  final GoTrueClient _auth;

  // Sends a new AuthState every time someone signs in or out.
  Stream<AuthState> authChanges() => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  // Returns true when the user is signed in right away. It returns false when
  // Supabase still needs the user to confirm their email first.
  Future<bool> signUp(String email, String password) async {
    final response = await _auth.signUp(email: email, password: password);
    return response.session != null;
  }

  // Opens GitHub's login page. After the user approves, GitHub sends them back
  // to this app, and Supabase finishes the sign-in automatically.
  Future<void> signInWithGitHub() async {
    await _auth.signInWithOAuth(
      OAuthProvider.github,
      // On the web, come back to the same address the app is running on.
      redirectTo: kIsWeb ? Uri.base.origin : null,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
