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
  double _progress = 0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Oldindan mavjud kategoriyalar
  final List<String> categories = [
    'Reading',
    'Listining',
    'Writing',
    'Speaking',
  ];

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

        // Progressni kuzatish
        uploadTask.snapshotEvents.listen((event) {
          setState(() {
            _progress = event.bytesTransferred / event.totalBytes;
          });
        });

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Firestore’ga saqlash
        await FirebaseFirestore.instance.collection('videos').add({
          'title': _titleController.text.isEmpty
              ? 'No title'
              : _titleController.text,
          'category': _categoryController.text.isEmpty
              ? 'Boshqa'
              : _categoryController.text,
          'url': downloadUrl,
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
      appBar: AppBar(title: const Text('👨‍💼 Admin Panel - Video yuklash')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '🎬 Video nomi'),
            ),
            const SizedBox(height: 8),

            // 🔽 Kategoriya matn + popup
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

            // 📤 Yuklash tugmasi
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadVideo,
              icon: const Icon(Icons.video_library),
              label: _isUploading
                  ? const Text('Yuklanmoqda...')
                  : const Text('Video tanlash va yuklash'),
            ),

            // 📊 Yuklanish progress
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

            // 🔥 Firestore’dan yuklangan videolarni chiqarish
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
