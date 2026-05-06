class LectureModel {
  final int id;
  final String title;
  final String? videoPath;
  final double? duration;
  final int orderIndex;
  final bool isFreePreview;
  final int courseId;

  LectureModel({
    required this.id,
    required this.title,
    this.videoPath,
    this.duration,
    required this.orderIndex,
    required this.isFreePreview,
    required this.courseId,
  });

  factory LectureModel.fromJson(Map<String, dynamic> json) => LectureModel(
    id: json['id'],
    title: json['title'],
    videoPath: json['video_path'],
    duration:
        json['duration'] != null ? (json['duration'] as num).toDouble() : null,
    orderIndex: json['order_index'] ?? 0,
    isFreePreview: json['is_free_preview'] ?? false,
    courseId: json['course_id'],
  );

  String get formattedDuration {
    if (duration == null) return '';
    final mins = (duration! / 60).floor();
    final secs = (duration! % 60).floor();
    return '${mins}m ${secs}s';
  }
}
