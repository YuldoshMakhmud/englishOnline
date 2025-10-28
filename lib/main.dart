import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ✅ To‘g‘ri importlar
import 'admin_upload_screen.dart';
import 'user_home_screen.dart';

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
      debugShowCheckedModeBanner: false,
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
