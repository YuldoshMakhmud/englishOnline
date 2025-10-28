class VideoModel {
  final String id;
  final String title;
  final String url;
  final String category;

  VideoModel({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
  });

  factory VideoModel.fromMap(Map<String, dynamic> data, String documentId) {
    return VideoModel(
      id: documentId,
      title: data['title'] ?? '',
      url: data['url'] ?? '',
      category: data['category'] ?? 'Boshqa',
    );
  }
}
