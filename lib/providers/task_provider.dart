import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/tasks.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Task> _tasks = [];
  TaskPriority? _filterPriority;
  bool? _filterCompleted;

  List<Task> get tasks {
    // Start with all tasks
    var filteredTasks = [..._tasks];

    // Apply priority filter if specified
    if (_filterPriority != null) {
      filteredTasks = filteredTasks
          .where((task) => task.priority == _filterPriority)
          .toList();
    }

    // Apply completion filter if specified
    if (_filterCompleted != null) {
      filteredTasks = filteredTasks
          .where((task) => task.isCompleted == _filterCompleted)
          .toList();
    }

    return filteredTasks;
  }

  Future<void> loadTasks(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      _tasks = snapshot.docs
          .map((doc) => Task.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error loading tasks: $e");
      }
    }
  }

  Future<void> addTask(Task task) async {
    try {
      final docRef = await _firestore.collection('tasks').add(task.toJson());
      _tasks.add(Task.fromJson({...task.toJson(), 'id': docRef.id}));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error adding task: $e");
      }
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).update(task.toJson());
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error updating task: $e");
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting task: $e");
      }
    }
  }

  void setFilters({TaskPriority? priority, bool? completed}) {
    if (_filterPriority == priority) {
      _filterPriority = null;
    } else {
      _filterPriority = priority;
    }

    _filterCompleted = completed;
    notifyListeners();
  }

  // Reset all filters to show all tasks
  void clearFilters() {
    _filterPriority = null;
    _filterCompleted = null;
    notifyListeners();
  }

  // Getter for current filter priority
  TaskPriority? get currentPriorityFilter => _filterPriority;

  // Getter for current completion filter
  bool? get currentCompletionFilter => _filterCompleted;
}
