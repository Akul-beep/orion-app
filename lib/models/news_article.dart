class NewsArticle {
  final int id;
  final String headline;
  final String summary;
  final String url;
  final String image;
  final String source;
  final DateTime datetime;

  NewsArticle({
    required this.id,
    required this.headline,
    required this.summary,
    required this.url,
    required this.image,
    required this.source,
    required this.datetime,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? 0,
      headline: json['headline'] ?? '',
      summary: json['summary'] ?? '',
      url: json['url'] ?? '',
      image: json['image'] ?? '',
      source: json['source'] ?? '',
      datetime: DateTime.fromMillisecondsSinceEpoch((json['datetime'] as int? ?? 0) * 1000),
    );
  }
}


