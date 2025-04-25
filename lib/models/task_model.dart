class Task {
  final String? id; // Firestore uses String IDs
  final String title;
  final List<String> subtasks;
  final List<bool> isDoneList;

  Task({
    this.id,
    required this.title,
    required this.subtasks,
    required this.isDoneList,
  });

  // Convert Task to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtasks': subtasks,
      'isDoneList': isDoneList,
    };
  }

  // Create Task from Firestore Map
  factory Task.fromMap(Map<String, dynamic> map, {String? id}) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      subtasks: List<String>.from(map['subtasks'] ?? []),
      isDoneList: List<bool>.from(map['isDoneList'] ?? []),
    );
  }
}
