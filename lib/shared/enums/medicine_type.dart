enum MedicineType {
  syrup("Sirop"),
  compressed("Comprimé"),
  injection("Injection"),
  capsule("Gélule"),
  powderSachet("Sachet de poudre"),
  bulb("Ampoule"),
  ointment("Pommade"),
  gel("Gel"),
  spray("Spray"),
  aerosol("Aérosol");

  final String labelFr;
  const MedicineType(this.labelFr);
}
