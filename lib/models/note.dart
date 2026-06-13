class Note {
  final String id;
  final String title;
  final String content;
  final bool hasImage;
  final String lastModified;
  final int imageCount;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.hasImage = false,
    required this.lastModified,
    this.imageCount = 0,
  });
}
