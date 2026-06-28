enum AccountStatus {
  pending,
  active,
  suspended,
  deactivated,
  verified,
}

extension AccountStatusLabel on AccountStatus {
  String get labelFr {
    switch (this) {
      case AccountStatus.pending:
        return "En attente";
      case AccountStatus.active:
        return "Actif";
      case AccountStatus.suspended:
        return "Suspendu";
      case AccountStatus.deactivated:
        return "Désactivé";
      case AccountStatus.verified:
        return "Vérifié";
    }
  }
}