import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await Supabase.initialize(
    url: 'https://efhhcmtwdshrgsltgzqg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmaGhjbXR3ZHNocmdzbHRnenFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxMTA4NzYsImV4cCI6MjA5NDY4Njg3Nn0.OB7yyDyJPXPWTq8pRLeGIQzVrCRYofwf7xR-JHF0CS4',
  );
  runApp(
    ProviderScope(
      child:App(),
    )
  );
}

