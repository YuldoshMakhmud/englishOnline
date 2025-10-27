class VideoModel {
  final String id;
  final String title;
  final String url;

  VideoModel({required this.id, required this.title, required this.url});

  factory VideoModel.fromMap(Map<String, dynamic> data, String documentId) {
    return VideoModel(
      id: documentId,
      title: data['title'] ?? '',
      url: data['url'] ?? '',
    );
  }
}
