import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TaskPage.dart';
import 'completed_tasks_page.dart';
import 'registration&Login/login.dart';
import '../util/dialog_box.dart';
import '../util/todo_tile.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime selectedDate = DateTime.now();
  String userEmail = 'To Do List';
  Map<DateTime, List<dynamic>> tasksByDate = {};
  Map<DateTime, bool> hasTasks = {};

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _loadTasks();
  }

  void _loadUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userEmail = userDoc['email'];
      });
    }
  }

  void _loadTasks() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .get();

      Map<DateTime, List<dynamic>> loadedTasks = {};
      Map<DateTime, bool> loadedHasTasks = {};

      for (var doc in snapshot.docs) {
        DateTime date = (doc['date'] as Timestamp).toDate();
        DateTime taskDate = DateTime(date.year, date.month, date.day);
        String task = doc['task'];
        bool completed = doc['completed'];

        if (loadedTasks[taskDate] == null) {
          loadedTasks[taskDate] = [];
        }
        loadedTasks[taskDate]!.add([task, completed]);
        loadedHasTasks[taskDate] = true;
      }

      setState(() {
        tasksByDate = loadedTasks;
        hasTasks = loadedHasTasks;
        print("Loaded tasks: $tasksByDate"); // Логирование загруженных задач
      });
    }
  }

  void checkBoxChanged(bool? value, DocumentSnapshot task) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(task.id)
          .update({'completed': value}).then((_) {
        _loadTasks();
      });
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
          .delete().then((_) {
        _loadTasks();
      });
    }
  }

  void createNewTask() {
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          onAdd: (newTask) {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('tasks')
                  .add({
                'task': newTask,
                'date': Timestamp.fromDate(selectedDate),
                'completed': false,
              }).then((value) {
                _loadTasks();
              }).catchError((error) => print("Failed to add task: $error"));
            }
          },
        );
      },
    );
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

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      selectedDate = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 134, 78, 96),
      appBar: AppBar(
        title: Text(userEmail),
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.calendar_today),
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      DateFormat('d').format(selectedDate),
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: Container(
                    width: double.maxFinite,
                    height: 400,
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: selectedDate,
                      selectedDayPredicate: (day) {
                        return isSameDay(day, selectedDate);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        _onDaySelected(selectedDay, focusedDay);
                        Navigator.of(context).pop(); // Закрываем календарь сразу после выбора даты
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (hasTasks.containsKey(date) && hasTasks[date]!) {
                            print('Date $date has tasks'); // Логирование проверки дат с задачами
                            return Positioned(
                              right: 1,
                              bottom: 1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTask,
        child: Icon(Icons.add),
      ),
      body: user == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('tasks')
                  .where('completed', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var tasks = snapshot.data!.docs.where((doc) {
                  DateTime taskDate = (doc['date'] as Timestamp).toDate();
                  return taskDate.year == selectedDate.year &&
                      taskDate.month == selectedDate.month &&
                      taskDate.day == selectedDate.day;
                }).toList();

                if (tasks.isEmpty) {
                  return Center(
                      child: Text("Здесь пока ничего",
                          style: TextStyle(color: Colors.white, fontSize: 18)));
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    return TodoTile(
                      index: index+1,
                      taskName: task['task'],
                      taskCompleted: task['completed'],
                      onChanged: (value) => checkBoxChanged(value, task),
                      onDelete: () => _showDeleteConfirmationDialog(task),
                    );
                  },
                );
              },
            ),
    );
  }
}
