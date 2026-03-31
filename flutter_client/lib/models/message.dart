class Message {
  final String from;
  final String content;
  final String time;
  final bool isGroup;
  final String? target;

  Message({
    required this.from,
    required this.content,
    required this.time,
    this.isGroup = false,
    this.target,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      from: json['from'] ?? '',
      content: json['content'] ?? '',
      time: json['time'] ?? '',
      isGroup: json['is_group'] ?? false,
      target: json['target'],
    );
  }
}
