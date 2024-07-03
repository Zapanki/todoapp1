import 'package:flutter/material.dart';
import 'package:todoapp1/util/todo_tile.dart';

class TaskPage extends StatelessWidget {
  final DateTime date;
  final List tasks;
  final Function(List) onSave;
  final Function(int) onDelete;

  TaskPage({required this.date, required this.tasks, required this.onSave, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tasks for ${date.toLocal().toIso8601String().substring(0, 10)}"),
      ),
      body: tasks.isEmpty
          ? Center(child: Text("Здесь пока ничего", style: TextStyle(fontSize: 18)))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return TodoTile(
                  index: index + 1, // Передаем индекс задачи, начиная с 1
                  taskName: tasks[index][0],
                  taskCompleted: tasks[index][1],
                  onChanged: (value) {
                    tasks[index][1] = value;
                    onSave(tasks);
                  },
                  onDelete: () {
                    tasks.removeAt(index);
                    onSave(tasks);
                    onDelete(index);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new task
          showDialog(
            context: context,
            builder: (context) {
              final TextEditingController _controller = TextEditingController();
              return AlertDialog(
                title: Text("Add a new task"),
                content: TextField(
                  controller: _controller,
                  decoration: InputDecoration(hintText: "Enter task"),
                ),
                actions: [
                  TextButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text("Add"),
                    onPressed: () {
                      tasks.add([_controller.text, false]);
                      onSave(tasks);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
