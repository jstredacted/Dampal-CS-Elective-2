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

  // The names go into the user's metadata. The handle_new_user database
  // trigger copies them into the new row of the profiles table.
  // Returns false when Supabase still needs the user to confirm their email.
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {'first_name': firstName, 'last_name': lastName},
    );
    return response.session != null;
  }

  // Opens Google's sign-in page. After the user picks an account, Google
  // sends them back to this app and Supabase finishes the sign-in.
  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      // On the web, come back to the same address the app is running on.
      redirectTo: kIsWeb ? Uri.base.origin : null,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
