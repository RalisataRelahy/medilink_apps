import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/shared/enums/user_role.dart';
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

Widget buildAppointmentList(List<AppointmentModel> list, UserRole userRole) {
  if (list.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textGrey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'Aucun rendez-vous trouvé.',
            style: TextStyle(color: AppColors.textGrey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: list.length,
    itemBuilder: (context, index) {
      final rdv = list[index];
      final statusColor = getStatusColor(rdv.status);
      final profile = rdv.profile;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  color: statusColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMMM yyyy', 'fr_FR').format(rdv.date),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                rdv.status.labelFr.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.background,
                              backgroundImage: profile?.avatarUrl != null 
                                  ? NetworkImage(profile!.avatarUrl!) 
                                  : null,
                              child: profile?.avatarUrl == null 
                                  ? const Icon(Icons.person, color: AppColors.textLight) 
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userRole == UserRole.patient
                                        ? "Dr. ${profile?.fullName ??
                                        'Inconnu'}"
                                        : (profile?.fullName ?? "Patient Inconnu"),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textGrey),
                                      const SizedBox(width: 4),
                                      Text(
                                        rdv.heure.substring(0, 5),
                                        style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          rdv.localization ?? "undefined",
                                          style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
