import'package:flutter/material.dart';

import '../../../../shared/enums/status.dart';
import '../../data/models/appointment_models.dart';
// Fonction utilitaire graphique pour générer une couleur par statut
Color getStatusColor(Status status) {
  switch (status) {
    case Status.pending: return Colors.orange;
    case Status.confirmed: return Colors.blue;
    case Status.progress: return Colors.purple;
    case Status.finished: return Colors.green;
    case Status.canceled: return Colors.red;
  }
}
Widget buildAppointmentList(List<AppointmentModel> list) {
  if (list.isEmpty) {
    return const Center(child: Text('Liste vide.'));
  }
  return ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: list.length,
    itemBuilder: (context, index) {
      final rdv = list[index];
      final statusColor = getStatusColor(rdv.status);

      return Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.access_time, color: statusColor),
          ),
          title: Text(
            'Heure : ${rdv.heure.substring(0, 5)}', // Coupe les secondes inutiles
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date : ${rdv.date.day}/${rdv.date.month}/${rdv.date.year}'),
              Text('Lieu : ${rdv.localization}'),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rdv.status.name.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    },
  );
}