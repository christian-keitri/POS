import 'package:pos/models/user.dart';

/// Holds the current logged-in user. Set after login, cleared on logout.

class AppState {
  static User? currentUser;
  static String? authToken;
}

