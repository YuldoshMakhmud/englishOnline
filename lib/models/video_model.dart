import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String title;
  final String url;
  final String category;
  final Timestamp uploadedAt;
  final String? description; // 🔹 qo‘shildi

  VideoModel({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
    required this.uploadedAt,
    this.description,
  });

  factory VideoModel.fromMap(Map<String, dynamic> data, String documentId) {
    return VideoModel(
      id: documentId,
      title: data['title'] ?? '',
      url: data['url'] ?? '',
      category: data['category'] ?? 'Other',
      uploadedAt: data['uploadedAt'] ?? Timestamp.now(),
      description: data['description'], // 🔹 Firestore’dan olingan
    );
  }
}
