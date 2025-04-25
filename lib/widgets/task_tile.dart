import 'package:flutter/material.dart';
import '../models/task_model.dart';  // Ensure the path is correct

class TaskTile extends StatelessWidget {
  final Task task;
  final Function(int) onToggle;
  final Function() onEdit;
  final Function() onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(task.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < task.subtasks.length && i < task.isDoneList.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: task.isDoneList[i],
                        onChanged: (value) {
                          onToggle(i);  // Trigger toggleSubtask in home screen
                        },
                      ),
                      Expanded(
                        child: Text(
                          task.subtasks[i],
                          style: TextStyle(
                            decoration: task.isDoneList[i]
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,  // Edit task action
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,  // Delete task action
            ),
          ],
        ),
      ),
    );
  }
}
