import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student_task.dart';
import '../models/class_schedule.dart';

/// Kelas helper untuk mengelola koneksi dan operasi database SQLite 
/// menggunakan pola arsitektur Singleton agar hanya ada satu instance database yang berjalan.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Konstruktor privat untuk Singleton
  DatabaseHelper._init();

  /// Mendapatkan instance database aktif. 
  /// Jika belum ada, fungsi ini akan menginisialisasi database terlebih dahulu.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('student_tasks.db');
    return _database!;
  }

  /// Menentukan path atau lokasi penyimpanan file database di dalam sistem perangkat.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Tingkatkan nilai 'version' jika terdapat perubahan skema database 
    // (misalnya penambahan tabel atau kolom baru) di masa mendatang.
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  /// Mengeksekusi perintah SQL untuk membuat tabel-tabel 
  /// saat database pertama kali diinisialisasi.
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

    // Data awal (seeder) untuk jadwal kuliah reguler
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

    // Memasukkan data jadwal awal ke dalam tabel 'schedules'
    for (var schedule in defaultSchedules) {
      await db.insert('schedules', schedule);
    }
  }

  // ==========================================
  // OPERASI CRUD UNTUK JADWAL KELAS (SCHEDULES)
  // ==========================================
  
  /// Mengambil daftar jadwal kelas berdasarkan semester tertentu.
  Future<List<ClassSchedule>> getSchedulesBySemester(String semester) async {
    final db = await instance.database;
    final result = await db.query(
      'schedules',
      where: 'semester = ?',
      whereArgs: [semester],
      orderBy: 'startTime ASC', // Diurutkan berdasarkan waktu mulai tercepat
    );
    return result.map((json) => ClassSchedule.fromMap(json)).toList();
  }

  /// Menambahkan jadwal kelas baru ke dalam database.
  Future<int> insertSchedule(ClassSchedule schedule) async {
    final db = await instance.database;
    return await db.insert('schedules', schedule.toMap());
  }

  /// Mengambil seluruh data jadwal kelas yang tersimpan.
  Future<List<ClassSchedule>> getAllSchedules() async {
    final db = await instance.database;
    final result = await db.query('schedules', orderBy: 'startTime ASC');
    return result.map((json) => ClassSchedule.fromMap(json)).toList();
  }

  /// Memperbarui data jadwal kelas yang sudah ada berdasarkan ID.
  Future<int> updateSchedule(ClassSchedule schedule) async {
    final db = await instance.database;
    return await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  /// Menghapus jadwal kelas dari database berdasarkan ID.
  Future<int> deleteSchedule(int id) async {
    final db = await instance.database;
    return await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // OPERASI CRUD UNTUK TUGAS MAHASISWA (TASKS)
  // ==========================================
  
  /// Menambahkan tugas baru ke dalam database.
  Future<int> insertTask(StudentTask task) async {
    final db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  /// Mengambil seluruh tugas, diurutkan berdasarkan tenggat waktu terdekat.
  Future<List<StudentTask>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', orderBy: 'deadline ASC');
    return result.map((json) => StudentTask.fromMap(json)).toList();
  }

  /// Menghapus tugas dari database berdasarkan ID.
  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // OPERASI CRUD UNTUK MATERI KULIAH (MATERIALS)
  // ==========================================
  
  /// Menambahkan rujukan atau file materi perkuliahan baru.
  Future<int> insertMaterial(String title, String course, String category, String filePath) async {
    final db = await instance.database;
    return await db.insert('materials', {
      'title': title,
      'course': course,
      'category': category,
      'filePath': filePath,
    });
  }

  /// Mengambil seluruh data materi, diurutkan dari yang terbaru (ID tertinggi).
  Future<List<Map<String, dynamic>>> getAllMaterials() async {
    final db = await instance.database;
    return await db.query('materials', orderBy: 'id DESC');
  }

  /// Menghapus data materi dari database berdasarkan ID.
  Future<int> deleteMaterial(int id) async {
    final db = await instance.database;
    return await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }
}