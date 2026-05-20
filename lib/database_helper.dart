import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/student_task.dart';
import 'models/class_schedule.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('student_tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Kalau lu mau nambah tabel/kolom lagi besok-besok, version-nya dinaikin
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        course TEXT NOT NULL,
        deadline TEXT NOT NULL,
        filePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course TEXT NOT NULL,
        day TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        room TEXT NOT NULL,
        semester TEXT NOT NULL,
        isMakeup INTEGER NOT NULL,
        isCancelled INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        course TEXT NOT NULL,
        category TEXT NOT NULL, 
        filePath TEXT NOT NULL
      )
    ''');

    final defaultSchedules = [
      {
        "course": "Probabilitas & Variabel Acak",
        "day": "Senin",
        "startTime": "09:30",
        "endTime": "12:00",
        "room": "Ruang 6B2 - Lt.6",
        "semester": "Semester 2",
        "isMakeup": 0,
        "isCancelled": 0,
      },
      {
        "course": "Praktikum Pemrograman Dasar",
        "day": "Selasa",
        "startTime": "13:00",
        "endTime": "15:30",
        "room": "Lab. Instrumentasi",
        "semester": "Semester 2",
        "isMakeup": 0,
        "isCancelled": 0,
      },
      {
        "course": "Konsep Keteknikan",
        "day": "Rabu",
        "startTime": "07:00",
        "endTime": "08:40",
        "room": "Ruang 8B2 - Lt.8",
        "semester": "Semester 2",
        "isMakeup": 0,
        "isCancelled": 0,
      },
      {
        "course": "Aljabar Linear",
        "day": "Rabu",
        "startTime": "09:30",
        "endTime": "12:00",
        "room": "Ruang 11B1 - Lt.11",
        "semester": "Semester 2",
        "isMakeup": 0,
        "isCancelled": 0,
      },
      {
        "course": "Analisis Variabel Kompleks",
        "day": "Rabu",
        "startTime": "13:00",
        "endTime": "15:30",
        "room": "Ruang 7B1 - Lt.7",
        "semester": "Semester 2",
        "isMakeup": 0,
        "isCancelled": 0,
      },
      {
        "course": "Fisika Listrik dan Magnet",
        "day": "Kamis",
        "startTime": "13:00",
        "endTime": "15:30",
        "room": "Ruang 6B1 - Lt.6",
        "semester": "Semester 2",
        "isMakeup": 0,
        "isCancelled": 0,
      },
      {
        "course": "Kalkulus Variabel Jamak",
        "day": "Jumat",
        "startTime": "09:00",
        "endTime": "11:30",
        "room": "Ruang 9B3 - Lt.9",
        "semester": "Semester 2",
        "isMakeup": 0,
        "isCancelled": 0,
      },
      {
        "course": "Algoritme dan Struktur Data",
        "day": "Jumat",
        "startTime": "13:00",
        "endTime": "15:30",
        "room": "Ruang 9B3 - Lt.9",
        "semester": "Semester 2",
        "isMakeup": 0,
        "isCancelled": 0,
      },
    ];

    for (var schedule in defaultSchedules) {
      await db.insert('schedules', schedule);
    }
  }

  // --- OPERATIONS FOR SCHEDULES ---
  Future<List<ClassSchedule>> getSchedulesBySemester(String semester) async {
    final db = await instance.database;
    final result = await db.query(
      'schedules',
      where: 'semester = ?',
      whereArgs: [semester],
      orderBy: 'startTime ASC',
    );
    return result.map((json) => ClassSchedule.fromMap(json)).toList();
  }

  Future<int> insertSchedule(ClassSchedule schedule) async {
    final db = await instance.database;
    return await db.insert('schedules', schedule.toMap());
  }

  Future<List<ClassSchedule>> getAllSchedules() async {
    final db = await instance.database;
    final result = await db.query('schedules', orderBy: 'startTime ASC');
    return result.map((json) => ClassSchedule.fromMap(json)).toList();
  }

  Future<int> updateSchedule(ClassSchedule schedule) async {
    final db = await instance.database;
    return await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSchedule(int id) async {
    final db = await instance.database;
    return await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  // --- OPERATIONS FOR TASKS ---
  Future<int> insertTask(StudentTask task) async {
    final db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<StudentTask>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', orderBy: 'deadline ASC');
    return result.map((json) => StudentTask.fromMap(json)).toList();
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // --- OPERATIONS FOR MATERIALS ---
  Future<int> insertMaterial(String title, String course, String category, String filePath) async {
    final db = await instance.database;
    return await db.insert('materials', {
      'title': title,
      'course': course,
      'category': category,
      'filePath': filePath,
    });
  }

  Future<List<Map<String, dynamic>>> getAllMaterials() async {
    final db = await instance.database;
    return await db.query('materials', orderBy: 'id DESC');
  }

  Future<int> deleteMaterial(int id) async {
    final db = await instance.database;
    return await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }
}