import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:students_reminder/src/models/attendance_model.dart';

class FirebaseData {
  final _attendance = FirebaseFirestore.instance.collection("attendance");
  final _users = FirebaseFirestore.instance.collection("users");

  //save the attandance record
  Future<void> saveAttendance(AttendanceDay attendance) async {
    try {
      _attendance.doc().set(attendance.toMap());
    } catch (e) {
      print(e);
    }
  }

  Future<bool> isAdmin(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return false;
    final userDoc = doc.data();

    if (userDoc?['isAdmin'] == null) return false;

    return userDoc?['isAdmin'] ?? false;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getAttendance(String uid) async {
    final data = await _attendance.where('studentUid', isEqualTo: uid).get();

    print("data here: ${data}");

    return data;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> readStudents() async {
    final data = _users.get();
    return data;
  }
}
