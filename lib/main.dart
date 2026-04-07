import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/mesh_provider.dart';
import 'providers/message_provider.dart';
// import 'providers/location_provider.dart';
// import 'providers/location_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OffGridApp());
}

class OffGridApp extends StatelessWidget {
  const OffGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MeshProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        // ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'OFFGRID',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}