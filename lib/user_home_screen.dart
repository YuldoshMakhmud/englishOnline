import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mumtozadmin/video_player_screen.dart';
import 'category_videos_screen.dart';
import 'models/video_model.dart'; // VideoModel ga category va uploadedAt maydonlarini qo‘shing

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  /// Kategoriya ro‘yxatini olish
  Future<List<String>> getCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('videos')
        .get();

    // Firestore’dan category maydonini olamiz va unique qilish
    final categories = snapshot.docs
        .map((doc) => (doc.data()['category'] ?? 'Boshqa') as String)
        .toSet()
        .toList();

    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategoriyalar')),
      body: FutureBuilder<List<String>>(
        future: getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Hozircha kategoriya yo‘q'));
          }

          final categories = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryVideosScreen(category: category),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// category_videos_screen.dart
class CategoryVideosScreen extends StatelessWidget {
  final String category;
  const CategoryVideosScreen({super.key, required this.category});

  Future<List<VideoModel>> getVideosByCategory(String category) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('videos')
        .get();

    final videos = snapshot.docs
        .map((doc) => VideoModel.fromMap(doc.data(), doc.id))
        .where(
          (video) => (video.category.toLowerCase() == category.toLowerCase()),
        )
        .toList();

    // Dart ichida sort qilish (so‘nggi yuklangan video birinchi bo‘lsin)
    videos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    return videos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Videos: $category')),
      body: FutureBuilder<List<VideoModel>>(
        future: getVideosByCategory(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Hozircha video yo‘q'));
          }

          final videos = snapshot.data!;

          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(
                    Icons.play_circle_fill,
                    size: 40,
                    color: Colors.blue,
                  ),
                  title: Text(video.title),
                  onTap: () {
                    // VideoPlayerScreen ga o‘tkazish
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          videoUrl: video.url,
                          title: video.title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// models/video_model.dart
class VideoModel {
  final String id;
  final String title;
  final String url;
  final String category;
  final Timestamp uploadedAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
    required this.uploadedAt,
  });

  factory VideoModel.fromMap(Map<String, dynamic> data, String documentId) {
    return VideoModel(
      id: documentId,
      title: data['title'] ?? '',
      url: data['url'] ?? '',
      category: data['category'] ?? 'Boshqa',
      uploadedAt: data['uploadedAt'] ?? Timestamp.now(),
    );
  }
}
