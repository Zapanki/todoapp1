import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../util/todo_tile.dart';
import 'package:intl/intl.dart';

class CompletedTasksPage extends StatefulWidget {
  @override
  _CompletedTasksPageState createState() => _CompletedTasksPageState();
}

class _CompletedTasksPageState extends State<CompletedTasksPage> {
  void checkBoxChanged(bool? value, DocumentSnapshot task) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(task.id)
          .update({'completed': value});
    }
  }

  void _deleteTask(DocumentSnapshot task) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(task.id)
          .delete();
    }
  }

  void _showDeleteConfirmationDialog(DocumentSnapshot task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Подтверждение удаления"),
          content: Text("Точно ли вы хотите удалить задачу?"),
          actions: <Widget>[
            TextButton(
              child: Text("Нет"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Да"),
              onPressed: () {
                _deleteTask(task);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 134, 78, 96),
      appBar: AppBar(
        title: Text("Выполненные задачи"),
      ),
      body: user == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('tasks')
                  .where('completed', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var tasks = snapshot.data!.docs;

                if (tasks.isEmpty) {
                  return Center(
                    child: Text("Нет выполненных задач",
                        style: TextStyle(fontSize: 18)),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    DateTime taskDate = (task['date'] as Timestamp).toDate();
                    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(taskDate);
                    return ListTile(
                      title: TodoTile(
                        index: index+1,
                        taskName: task['task'],
                        taskCompleted: task['completed'],
                        onChanged: (value) => checkBoxChanged(value, task),
                        onDelete: () => _showDeleteConfirmationDialog(task),
                      ),
                      subtitle: Text(
                        'Создано: $formattedDate',
                        style: TextStyle(fontSize: 10, color: Colors.brown),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
