/// The presentation roles supported by the UI while role persistence is being
/// coordinated with the backend.
enum AppRole {
  warrior,
  doctor,
}

extension AppRoleLabel on AppRole {
  String get label {
    switch (this) {
      case AppRole.warrior:
        return 'Sickle-cell warrior';
      case AppRole.doctor:
        return 'Doctor';
    }
  }
}
