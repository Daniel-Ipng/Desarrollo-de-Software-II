class Post {
  final int userId;
  final int id;
  final String title;
  final String body;

  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        userId: json['userId'] as int,
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'id': id,
        'title': title,
        'body': body,
      };

  Post copyWith({String? title, String? body}) => Post(
        userId: userId,
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
      );

  @override
  String toString() => 'Post(id: $id, title: $title)';
}
