import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'video_player_screen.dart';
import 'models/video_model.dart';

class CategoryVideosScreen extends StatelessWidget {
  final String category;
  const CategoryVideosScreen({super.key, required this.category});

  Stream<List<VideoModel>> getVideosByCategory() {
    print('Filter category: $category'); // debug
    return FirebaseFirestore.instance
        .collection('videos')
        .where('category', isEqualTo: category)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Found docs: ${snapshot.docs.length}'); // debug
          return snapshot.docs
              .map((doc) => VideoModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: StreamBuilder<List<VideoModel>>(
        stream: getVideosByCategory(),
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
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
