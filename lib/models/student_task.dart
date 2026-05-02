class StudentTask {
  int? id;
  String title;
  String course;
  DateTime deadline;
  String? filePath;

  StudentTask({
    this.id,
    required this.title,
    required this.course,
    required this.deadline,
    this.filePath,
  });

  factory StudentTask.fromMap(Map<String, dynamic> json) => StudentTask(
    id: json['id'],
    title: json['title'],
    course: json['course'],
    deadline: DateTime.parse(json['deadline']),
    filePath: json['filePath'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'course': course,
    'deadline': deadline.toIso8601String(),
    'filePath': filePath,
  };
}