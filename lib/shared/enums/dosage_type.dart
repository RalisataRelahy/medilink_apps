enum UniteDosage {
  mg('mg', 'Milligramme'),
  g('g', 'Gramme'),
  mcg('mcg', 'Microgramme (µg)'),
  ml('ml', 'Millilitre'),
  goutte('goutte', 'Goutte(s)'),
  ui('UI', 'Unité Internationale'),
  pourcent('%', 'Pourcentage'),
  mgMl('mg/ml', 'Milligramme par millilitre');

  // Le symbole abrégé (ex: "mg") qui sera enregistré dans votre base de données
  final String code;

  // Le nom complet en français pour l'afficher proprement à l'écran
  final String nomComplet;

  const UniteDosage(this.code, this.nomComplet);

  // Une fonction très utile pour retrouver l'enum à partir d'un texte de la base de données
  static UniteDosage fromCode(String code) {
    return UniteDosage.values.firstWhere(
          (element) => element.code == code,
      orElse: () => UniteDosage.mg, // Valeur par défaut en cas d'erreur
    );
  }
}
//USAGE
// DropdownButton<UniteDosage>(
// value: UniteDosage.mg, // La valeur sélectionnée par défaut
// items: UniteDosage.values.map((UniteDosage unite) {
// return DropdownMenuItem<UniteDosage>(
// value: unite,
// child: Text(unite.nomComplet), // Affiche "Milligramme" à l'écran
// );
// }).toList(),
// onChanged: (UniteDosage? nouvelleValeur) {
// // Code pour enregistrer le choix : nouvelleValeur.code
// },
// );
// FLUTTER===========>SUPABASE
//String codeAEnregistrer = UniteDosage.mg.code; // Donnera la chaîne de caractères "mg"

//SUPABASE==============>FLUTTER
// String codeRecu = "mg/ml";
// UniteDosage monUnite = UniteDosage.fromCode(codeRecu); // Convertit en UniteDosage.mgMl
