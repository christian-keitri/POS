/// Holds the current logged-in user. Set after login, cleared on logout.
class AppUser {
  final int id;
  final String email;
  final String? businessName;

  const AppUser({
    required this.id,
    required this.email,
    this.businessName,
  });

  String get displayName => businessName ?? email;
}

class AppState {
  static AppUser? currentUser;
}
