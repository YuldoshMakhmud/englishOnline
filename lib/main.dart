import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mumtozadmin/user_home_scrren.dart';
import 'firebase_options.dart';
import 'admin_upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RoleSelector(),
    );
  }
}

class RoleSelector extends StatelessWidget {
  const RoleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tizimga kirish roli')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('👨‍💼 Admin panel'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('👤 User panel'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserHomeScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
