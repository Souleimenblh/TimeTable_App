import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Class {
  final int id;
  final String name;

  Class({required this.id, required this.name});

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Professor {
  final int id;
  final String name;

  Professor({required this.id, required this.name});

  factory Professor.fromJson(Map<String, dynamic> json) {
    return Professor(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Seance {
  final int id;
  final String day;
  final String time;
  final int? classId;
  final int? professorId;
  final String? room;

  Seance({
    required this.id,
    required this.day,
    required this.time,
    this.classId,
    this.professorId,
    this.room,
  });

  factory Seance.fromJson(Map<String, dynamic> json) {
    return Seance(
      id: json['id'],
      day: json['day'],
      time: json['time'],
      classId: json['classId'],
      professorId: json['professorId'],
      room: json['room'],
    );
  }
}

void main() => runApp(ScheduleApp());

class ScheduleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Schedule',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SchedulePage(),
    );
  }
}

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Seance> seances = [];
  List<Class> classes = [];
  List<Professor> professors = [];
  List<String> daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday"
  ];
  List<String> timeSlots = [
    "08:00 - 10:00",
    "10:00 - 12:00",
    "12:00 - 14:00",
    "14:00 - 16:00",
    "16:00 - 18:00"
  ];

  @override
  void initState() {
    super.initState();
    fetchClasses();
    fetchProfessors();
    fetchSeances();
  }

  Future<void> fetchClasses() async {
    final response =
        await http.get(Uri.parse('http://192.168.107.101:3000/classes'));
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      setState(() {
        classes =
            jsonResponse.map((classJson) => Class.fromJson(classJson)).toList();
      });
    } else {
      throw Exception('Failed to load classes');
    }
  }

  Future<void> fetchProfessors() async {
    final response =
        await http.get(Uri.parse('http://192.168.107.101:3000/professors'));
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      setState(() {
        professors = jsonResponse
            .map((profJson) => Professor.fromJson(profJson))
            .toList();
      });
    } else {
      throw Exception('Failed to load professors');
    }
  }

  Future<void> fetchSeances() async {
    final response =
        await http.get(Uri.parse('http://192.168.107.101:3000/seances'));
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      setState(() {
        seances =
            jsonResponse.map((seance) => Seance.fromJson(seance)).toList();
      });
    } else {
      throw Exception('Failed to load seances');
    }
  }

  String getClassName(int? classId) {
    if (classId != null) {
      final classItem = classes.firstWhere(
        (classItem) => classItem.id == classId,
        orElse: () => Class(id: 0, name: "Unknown"),
      );
      return classItem.name;
    }
    return "No Class";
  }

  Future<bool> isRoomAvailable(String day, String time, String room) async {
    for (var seance in seances) {
      if (seance.day == day && seance.time == time && seance.room == room) {
        return false;
      }
    }
    return true;
  }

  Future<void> addSeance(String day, String time, int? classId,
      int? professorId, String room) async {
    final isAvailable = await isRoomAvailable(day, time, room);
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Room $room is not available for $day at $time')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://192.168.107.101:3000/seances'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'day': day,
        'time': time,
        'classId': classId,
        'professorId': professorId,
        'room': room,
      }),
    );

    if (response.statusCode == 201) {
      fetchSeances();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seance added successfully!')),
      );
    } else {
      throw Exception('Failed to add seance');
    }
  }

  void showAddSeanceDialog() {
    String selectedClassId = '';
    String selectedProfessorId = '';
    String room = '';
    String day = daysOfWeek[0];
    String time = timeSlots[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Seance'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButton<String>(
                  hint: Text("Select Class"),
                  value: selectedClassId,
                  items: classes.map((classItem) {
                    return DropdownMenuItem<String>(
                      value: classItem.id.toString(),
                      child: Text(classItem.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClassId = value!;
                    });
                  },
                ),
                DropdownButton<String>(
                  hint: Text("Select Professor"),
                  value: selectedProfessorId,
                  items: professors.map((professor) {
                    return DropdownMenuItem<String>(
                      value: professor.id.toString(),
                      child: Text(professor.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProfessorId = value!;
                    });
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Room'),
                  onChanged: (value) {
                    room = value;
                  },
                ),
                DropdownButton<String>(
                  value: day,
                  items: daysOfWeek.map((dayOption) {
                    return DropdownMenuItem<String>(
                      value: dayOption,
                      child: Text(dayOption),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      day = value!;
                    });
                  },
                ),
                DropdownButton<String>(
                  value: time,
                  items: timeSlots.map((timeOption) {
                    return DropdownMenuItem<String>(
                      value: timeOption,
                      child: Text(timeOption),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      time = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                addSeance(
                    day,
                    time,
                    selectedClassId.isNotEmpty
                        ? int.parse(selectedClassId)
                        : null,
                    selectedProfessorId.isNotEmpty
                        ? int.parse(selectedProfessorId)
                        : null,
                    room);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('University Schedule'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: [
              DataColumn(label: Text('Time/Day')),
              for (var day in daysOfWeek) DataColumn(label: Text(day)),
            ],
            rows: timeSlots.map((time) {
              return DataRow(cells: [
                DataCell(Text(time)),
                ...daysOfWeek.map((day) {
                  var seance = seances.firstWhere(
                      (s) => s.day == day && s.time == time,
                      orElse: () => Seance(
                          id: 0,
                          day: day,
                          time: time,
                          classId: null,
                          professorId: null,
                          room: null));
                  return DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getClassName(seance.classId),
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          seance.room != null
                              ? "Room: ${seance.room}"
                              : "No Room",
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ]);
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddSeanceDialog,
        tooltip: 'Add Seance',
        child: Icon(Icons.add),
      ),
    );
  }
}
