import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  double _progress = 0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  final List<String> categories = [
    'reading',
    'listening',
    'writing',
    'speaking',
  ];

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _pickAndUploadVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withReadStream: true,
      withData: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _isUploading = true;
        _progress = 0;
      });

      final pickedFile = result.files.single;
      final filePath = pickedFile.path;
      final fileName = pickedFile.name;

      if (filePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Faylni olishning imkoni yo‘q')),
        );
        setState(() => _isUploading = false);
        return;
      }

      try {
        final file = File(filePath);
        final storageRef = FirebaseStorage.instance.ref().child(
          'videos/${DateTime.now().millisecondsSinceEpoch}_$fileName',
        );

        final uploadTask = storageRef.putFile(file);
        uploadTask.snapshotEvents.listen((event) {
          setState(() {
            _progress = event.bytesTransferred / event.totalBytes;
          });
        });

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('videos').add({
          'title': _titleController.text.isEmpty
              ? 'No title'
              : _titleController.text,
          'category': _categoryController.text.isEmpty
              ? 'boshqa'
              : _categoryController.text.trim().toLowerCase(),
          'url': downloadUrl,
          'description':
              'Bu video ${_titleController.text} haqida ma’lumot beradi.',
          'uploadedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Video muvaffaqiyatli yuklandi!')),
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
      appBar: AppBar(
        title: const Text('👨‍💼 Admin Panel - Video yuklash'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '🎬 Video nomi'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: '🏷 Kategoriya',
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (String value) {
                    _categoryController.text = value;
                  },
                  itemBuilder: (BuildContext context) {
                    return categories.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadVideo,
              icon: const Icon(Icons.video_library),
              label: _isUploading
                  ? const Text('Yuklanmoqda...')
                  : const Text('Video tanlash va yuklash'),
            ),
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: LinearProgressIndicator(value: _progress),
              ),
            const SizedBox(height: 20),
            const Text(
              '📋 Yuklangan videolar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('videos')
                    .orderBy('uploadedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final videos = snapshot.data!.docs;
                  if (videos.isEmpty) {
                    return const Center(child: Text('Hozircha video yo‘q'));
                  }
                  return ListView.builder(
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final data = videos[index].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.blue,
                          ),
                          title: Text(data['title'] ?? ''),
                          subtitle: Text(
                            'Kategoriya: ${data['category'] ?? ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('videos')
                                  .doc(videos[index].id)
                                  .delete();
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
