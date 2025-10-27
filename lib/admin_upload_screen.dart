import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  bool _isUploading = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  Future<void> _pickAndUploadVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withReadStream: true, // katta fayllar uchun stream
      withData: false, // bytes emas, stream orqali yuboriladi
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _isUploading = true);

      final pickedFile = result.files.single;
      final fileName = pickedFile.name;
      final filePath = pickedFile.path;

      if (filePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faylni olishning imkoni yo‘q')),
        );
        setState(() => _isUploading = false);
        return;
      }

      try {
        final file = File(filePath);
        final storageRef = FirebaseStorage.instance.ref().child(
          'videos/${DateTime.now().millisecondsSinceEpoch}_$fileName',
        );

        // Stream orqali yuklash
        final uploadTask = storageRef.putFile(file);

        // Yuklash progressini kuzatish (ixtiyoriy)
        uploadTask.snapshotEvents.listen((event) {
          final progress = (event.bytesTransferred / event.totalBytes) * 100;
          debugPrint('Yuklash: ${progress.toStringAsFixed(2)}%');
        });

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Firestore’ga saqlash
        await FirebaseFirestore.instance.collection('videos').add({
          'title': _titleController.text.isEmpty
              ? 'No title'
              : _titleController.text,
          'category': _categoryController.text.isEmpty
              ? 'No category'
              : _categoryController.text,
          'url': downloadUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video muvaffaqiyatli yuklandi!')),
        );
        _titleController.clear();
        _categoryController.clear();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }

      setState(() => _isUploading = false);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Video tanlanmadi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel - Video yuklash')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Video nomi'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Kategoriya'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadVideo,
              icon: const Icon(Icons.video_library),
              label: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Video tanlash va yuklash'),
            ),
          ],
        ),
      ),
    );
  }
}
