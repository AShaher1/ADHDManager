import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  // Fetch all tasks for the logged-in user
  Future<List<Task>> fetchTasks() async {
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .get();

    return snapshot.docs
        .map((doc) => Task.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .add(task.toMap());
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    if (uid == null || task.id == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(task.id)  // Use task.id to specify which task to update
        .update(task.toMap());  // Update with the new task data
  }

  // Toggle the status of a subtask
  Future<void> toggleSubtask(Task task, int index) async {
    if (uid == null || task.id == null) return;

    task.isDoneList[index] = !task.isDoneList[index];

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(task.id)
        .update(task.toMap());
  }

  // Delete a single task
  Future<void> deleteTask(String taskId) async {
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // Delete all completed tasks
  Future<void> deleteAllCompletedTasks() async {
    if (uid == null) return;

    // Fetch all tasks for the logged-in user
    final tasksSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .get();

    // Filter completed tasks (where all subtasks are completed)
    final completedTasks = tasksSnapshot.docs.where((doc) {
      final task = Task.fromMap(doc.data(), id: doc.id);
      return task.isDoneList.every((done) => done); // All subtasks must be done
    }).toList();

    // Delete each completed task
    for (var task in completedTasks) {
      await deleteTask(task.id);
    }
  }
}
