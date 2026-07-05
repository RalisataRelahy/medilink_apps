import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/medecine_provider.dart';

class PrescriptionFormScreen extends ConsumerStatefulWidget {
  const PrescriptionFormScreen({super.key});

  @override
  ConsumerState<PrescriptionFormScreen> createState() => _FormulaireState();
}

class _FormulaireState extends ConsumerState<PrescriptionFormScreen> {
  // Variable locale pour stocker l'ID du médicament sélectionné
  String? _selectedMedicineId;

  @override
  Widget build(BuildContext context) {
    // 1. On écoute le provider qui va chercher les médicaments sur Supabase
    final medicinesAsync = ref.watch(medicinesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un médicament')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisir un médicament :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 2. On gère l'affichage selon l'état de la requête réseau
            medicinesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Erreur de chargement : $err'),
              data: (medicines) {
                if (medicines.isEmpty) {
                  return const Text('Aucun médicament disponible en base.');
                }

                // 3. Construction du DropdownButton une fois les données reçues
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Sélectionnez un médicament',
                  ),
                  // La valeur actuelle sélectionnée (au début, elle est null)
                  initialValue: _selectedMedicineId,
                  // Ce qui se passe quand le médecin clique sur un élément
                  onChanged: (String? newId) {
                    setState(() {
                      _selectedMedicineId = newId; // On stocke l'ID choisi !
                    });
                  },
                  // On transforme chaque Map (médicament) en un élément de liste cliquable
                  items: medicines.map((medicine) {
                    return DropdownMenuItem<String>(
                      value: medicine.id as String, // Ce que la fonction onChanged va recevoir
                      child: Text('${medicine.name} - ${medicine.dosage} ${medicine.type}'), // Ce que le docteur voit à l'écran
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),

            // Un bouton de test pour valider que vous avez bien récupéré l'ID
            ElevatedButton(
              onPressed: _selectedMedicineId == null
                  ? null // Désactivé si rien n'est sélectionné
                  : () {
                // Vous pouvez maintenant utiliser cet ID pour faire votre insertion
                // dans votre table 'prescription_medicine'
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ID sélectionné : $_selectedMedicineId')),
                );
              },
              child: const Text('Valider le choix'),
            ),
          ],
        ),
      ),
    );
  }
}
