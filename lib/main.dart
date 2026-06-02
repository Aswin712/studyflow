import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/database_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'app/app.dart';
import 'shared/widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable network fetch — dihapus karena font ttf tidak di-bundle
  // GoogleFonts.config.allowRuntimeFetching = false;

  // Wajib untuk format tanggal Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  final db = await DatabaseService.getInstance();
  final storage = await LocalStorageService.getInstance();
  final notif = NotificationService();
  
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  await notif.init(
    onDidReceiveNotificationResponse: (response) {
      if (response.payload != null) {
        final parts = response.payload!.split('|');
        if (parts.length == 2) {
          final type = parts[0];
          final id = parts[1];
          // We must wait for the app to finish building, so we delay the navigation slightly
          Future.delayed(const Duration(milliseconds: 500), () {
            if (navigatorKey.currentState != null) {
              // Push a custom route or named route based on type
              // For simplicity, we can't directly push screens that need Provider context here
              // without an explicit context that has the providers.
              // We'll push a named route or we can pass navigatorKey to StudyFlowApp.
              // Wait, instead of pushing directly, we can store it in a static variable 
              // or handle it in the home screen.
              // Let's just pass the navigatorKey down.
              if (type == 'task') {
                 // But wait, TaskDetailScreen needs a Task object. We only have the ID.
                 // So we need a route that resolves the task by ID.
                 // We will push a route '/task_detail' with arguments id.
                 navigatorKey.currentState!.pushNamed('/task_detail', arguments: id);
              } else if (type == 'exam') {
                 navigatorKey.currentState!.pushNamed('/exam_detail', arguments: id);
              }
            }
          });
        }
      }
    }
  );

  final isFirstLaunch = storage.loadIsFirstLaunch();

  // Setup Global Error Widget
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return GlobalErrorWidget(details: details);
  };

  runZonedGuarded(() {
    runApp(StudyFlowApp(
      db: db,
      storage: storage,
      notif: notif,
      isFirstLaunch: isFirstLaunch,
      navigatorKey: navigatorKey,
    ));
  }, (error, stackTrace) {
    // Di sini bisa dikirim ke Crashlytics / Sentry di production
    debugPrint('Zoned Error: $error');
  });
}
