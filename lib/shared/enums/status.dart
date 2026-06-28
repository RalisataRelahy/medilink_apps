enum Status {
  pending("En attente"),
  canceled("Annulé"),
  confirmed("Confirmé"),
  progress("En cours"),
  finished("Terminé");

  final String labelFr;
  const Status(this.labelFr);
}
