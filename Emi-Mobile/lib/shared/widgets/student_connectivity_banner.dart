import 'package:flutter/material.dart';

import '../../app/theme/emi_theme.dart';
import '../../core/network/network_status_controller.dart';
import 'student_style.dart';

class StudentConnectivityBanner extends StatelessWidget {
  const StudentConnectivityBanner({super.key, required this.mode});

  final NetworkMode mode;

  @override
  Widget build(BuildContext context) {
    if (mode == NetworkMode.online) return const SizedBox.shrink();
    final offline = mode == NetworkMode.offline;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EmiSpacing.sm),
      decoration: BoxDecoration(
        color: StudentStyle.tint,
        borderRadius: BorderRadius.circular(EmiRadii.card),
      ),
      child: Row(
        children: [
          Icon(
            offline ? Icons.cloud_off_outlined : Icons.sync_problem_outlined,
            color: EmiColors.primary,
          ),
          const SizedBox(width: EmiSpacing.sm),
          Expanded(
            child: Text(
              offline
                  ? 'Kamu sedang offline. Konten tersimpan tetap bisa dibuka.'
                  : 'Koneksi tidak stabil. Beberapa data mungkin belum terbaru.',
              style: const TextStyle(color: StudentStyle.ink),
            ),
          ),
        ],
      ),
    );
  }
}
