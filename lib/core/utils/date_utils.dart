import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatTanggal(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  static String formatTanggalPendek(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String formatJam(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String hitungSisaHari(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deadline.year, deadline.month, deadline.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) return 'Terlewat ${diff.abs()} hari';
    if (diff == 0) return 'Hari ini!';
    if (diff == 1) return 'Besok';
    return '$diff hari lagi';
  }

  static bool isDeadlineDekat(DateTime deadline, {int hariWarning = 3}) {
    final now = DateTime.now();
    final diff = deadline.difference(now).inDays;
    return diff >= 0 && diff <= hariWarning;
  }

  static bool isDeadlineLewat(DateTime deadline) {
    return deadline.isBefore(DateTime.now());
  }

  // Konversi TimeOfDay ke menit (untuk sorting)
  static int timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Format deadline lengkap: "Senin, 20 Jan 2025 · 23:59"
  /// Kalau tidak ada jam spesifik: "Senin, 20 Jan 2025"
  static String formatDeadlineLengkap(DateTime date, TimeOfDay? time) {
    final tanggal = formatTanggalPendek(date);
    if (time == null) return tanggal;
    return '$tanggal · ${formatJam(time)}';
  }

  /// Hitung sisa waktu dengan akurasi jam
  /// Contoh: "2 jam lagi", "Besok 14:00", "3 hari lagi"
  static String hitungSisaWaktu(DateTime deadline, TimeOfDay? time) {
    final now = DateTime.now();
    final target = time != null
        ? DateTime(
            deadline.year, deadline.month, deadline.day, time.hour, time.minute)
        : DateTime(deadline.year, deadline.month, deadline.day, 23, 59);

    final diff = target.difference(now);

    if (diff.isNegative) {
      if (diff.inHours.abs() < 24) {
        return 'Terlewat ${diff.inHours.abs()} jam';
      }
      return 'Terlewat ${diff.inDays.abs()} hari';
    }
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lagi';
    if (diff.inHours < 24) return '${diff.inHours} jam lagi';
    if (diff.inDays == 1) {
      return time != null ? 'Besok ${formatJam(time)}' : 'Besok';
    }
    return '${diff.inDays} hari lagi';
  }
}
