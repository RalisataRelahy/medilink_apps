import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medilink/features/appointments/views/providers/appointment_provider.dart';
import 'package:medilink/features/auth/views/providers/auth_provider.dart';

import '../../../../shared/enums/user_role.dart';
import '../../../doctors/views/providers/doctor_provider.dart';

class AddAppointment extends ConsumerStatefulWidget {
  const AddAppointment({super.key});

  @override
  ConsumerState<AddAppointment> createState() => AddAppointmentState();
}

class AddAppointmentState extends ConsumerState<AddAppointment> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs et variables d'état du formulaire
  final _reasonController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDoctorId;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Sélecteur de date
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Sélecteur d'heure
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  // Soumission du formulaire
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une date et une heure.'),
          ),
        );
        return;
      }
      final formattedTime =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';
      final success = await ref
          .read(createAppointmentProvider.notifier)
          .addAppointment(
            doctorId: _selectedDoctorId ?? '',
            patientId: ref.read(authProvider).user?.id ?? '',
            date: _selectedDate ?? DateTime.now(),
            time: formattedTime,
          );
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande de rendez-vous enregistrée !')),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        final error = ref.read(createAppointmentProvider).error;
        print(error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la création : $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final doctorsAsync = ref.watch(allDoctorsProvider);

    // Écran pour le rôle Patient
    if (authState.user?.role == UserRole.patient) {
      return Scaffold(
        appBar: AppBar(title: const Text('Demander un rendez-vous')),
        body: doctorsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Erreur : $err')),
          data: (doctorsList) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Remplissez les informations ci-dessous pour planifier votre consultation.',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      value: _selectedDoctorId,
                      isExpanded: true,
                      itemHeight: 64,
                      // Garde de la hauteur pour la liste ouverte
                      decoration: const InputDecoration(
                        labelText: 'Choisir un médecin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),

                      // NOUVEAU : Définit ce qui s'affiche dans le champ APPRÈS la sélection
                      selectedItemBuilder: (BuildContext context) {
                        return doctorsList.map((doctor) {
                          final firstName = doctor.profile.firstName ?? '';
                          final lastName = doctor.profile.lastName ?? '';
                          final fullName = 'Dr. $firstName $lastName'.trim();

                          return Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              fullName, // Uniquement le nom complet ici
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList();
                      },

                      // Ce qui s'affiche dans la liste OUVERTE (Nom + Adresse)
                      items: doctorsList.map((doctor) {
                        final firstName = doctor.profile.firstName ?? '';
                        final lastName = doctor.profile.lastName ?? '';
                        final address = doctor.profile.address ?? '';
                        final fullName = 'Dr. $firstName $lastName'.trim();

                        return DropdownMenuItem<String>(
                          value: doctor.profile.id.toString(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (address.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  address,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedDoctorId = value),
                      validator: (value) =>
                          value == null ? 'Veuillez choisir un médecin' : null,
                    ),
                    const SizedBox(height: 16),

                    // Étape 2 : Choisir la date
                    ListTile(
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: Text(
                        _selectedDate == null
                            ? 'Sélectionner une date'
                            : DateFormat(
                                'dd MMMM yyyy',
                                'fr_FR',
                              ).format(_selectedDate!),
                      ),
                      trailing: const Icon(Icons.arrow_drop_down),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),

                    // Étape 3 : Choisir l'heure
                    ListTile(
                      leading: const Icon(Icons.access_time_rounded),
                      title: Text(
                        _selectedTime == null
                            ? "Sélectionner l'heure"
                            : _selectedTime!.format(context),
                      ),
                      trailing: const Icon(Icons.arrow_drop_down),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: 16),

                    // Étape 4 : Saisir le motif
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Motif de la consultation',
                        hintText: 'Décrivez brièvement vos symptômes...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez indiquer le motif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Bouton de validation
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Confirmer le rendez-vous',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    // Écran d'accès refusé
    return Scaffold(
      appBar: AppBar(title: const Text('Accès refusé')),
      body: const Center(
        child: Text("Seuls les patients peuvent demander un rendez-vous."),
      ),
    );
  }
}
