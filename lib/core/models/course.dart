import 'dart:ui';

class Course {
  final String id;
  final String name;
  final int sks;
  final String lecturer;
  final String room;
  final Color color;
  final String? grade;
  final bool isCompleted;

  const Course({
    required this.id,
    required this.name,
    required this.sks,
    required this.lecturer,
    required this.room,
    required this.color,
    this.grade,
    this.isCompleted = false,
  });

  /// Ambil inisial dari nama mata kuliah (maks 2 kata)
  /// "Pemrograman Mobile" -> "PM"
  /// "Matematika" -> "MA"
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  Course copyWith({
    String? id,
    String? name,
    int? sks,
    String? lecturer,
    String? room,
    Color? color,
    String? grade,
    bool? isCompleted,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      sks: sks ?? this.sks,
      lecturer: lecturer ?? this.lecturer,
      room: room ?? this.room,
      color: color ?? this.color,
      grade: grade ?? this.grade,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sks': sks,
        'lecturer': lecturer,
        'room': room,
        'color': color.toARGB32(),
        'grade': grade,
        'isCompleted': isCompleted,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        name: json['name'] as String,
        sks: (json['sks'] as num).toInt(),
        lecturer: json['lecturer'] as String? ?? '',
        room: json['room'] as String? ?? '',
        color: Color(json['color'] as int),
        grade: json['grade'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        // field 'code' dari data lama diabaikan otomatis
      );

  @override
  bool operator ==(Object other) => other is Course && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
