class Education {
  final int id;
  final String title;
  final String category;
  final String type;
  final String content;
  final String thumbnailUrl;
  final String? level;
  final String? description;
  final String? readingTime;
  final int view;
  final String? formattedDate;

  Education({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.content,
    required this.thumbnailUrl,
    this.level,
    this.description,
    this.readingTime,
    required this.view,
    this.formattedDate,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      type: json['type'],
      content: json['content'],
      thumbnailUrl: json['thumbnail_url'],
      level: json['level'],
      readingTime: json['reading_time'],
      view: json['view'],
      formattedDate: json['formatted_date'],
    );
  }
}
