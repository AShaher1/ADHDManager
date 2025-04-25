import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to add a task for the currently authenticated user
  Future<void> addTask(Task task) async {
    if (_auth.currentUser == null) return; // Ensure user is logged in

    final userId = _auth.currentUser!.uid; // Get current user's UID

    await _firestore
        .collection('users') // Collection of users
        .doc(userId) // User document
        .collection('tasks') // Tasks sub-collection
        .add(task.toMap()); // Add task to this sub-collection
  }

  // Function to get tasks of the current user
  Future<List<Task>> getUserTasks(String userId) async {
    if (_auth.currentUser == null) return []; // Ensure user is logged in

    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks') // Fetch tasks for the current user
        .get();

    return query.docs
        .map((doc) => Task.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  // Function to update a task for the current user
  Future<void> updateTask(Task task) async {
    if (_auth.currentUser == null || task.id == null) return;

    final userId = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id) // Specify the task document to update
        .update(task.toMap()); // Update task
  }

  // Method to delete a task by its ID
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore
          .collection('users') // Corrected collection path for user tasks
          .doc(_auth.currentUser!.uid) // User document
          .collection('tasks') // Tasks sub-collection
          .doc(taskId) // Task document ID
          .delete(); // Delete task
    } catch (e) {
      print("Error deleting task: $e");
      throw Exception("Error deleting task");
    }
  }
}
