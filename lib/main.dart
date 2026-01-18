import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'back/providers/book_provider.dart';
import 'app.dart';

void main() async {
  // Nécessaire avant d'appeler des plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration SQLite pour Windows/Linux (desktop)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    // Provider wrapper pour l'état global
    ChangeNotifierProvider(
      create: (context) => BookProvider()..loadBooks(),
      child: const BooklyApp(),
    ),
  );
}