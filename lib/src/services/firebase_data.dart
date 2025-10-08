import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:students_reminder/src/models/attendance_model.dart';

class FirebaseData {
  final _attendance = FirebaseFirestore.instance.collection("attendance");

  //save the attandance record
  Future<void> saveAttendance(AttendanceDay attendance) async {
    try {
      _attendance.doc().set(attendance.toMap());
    } catch (e) {
      print(e);
    }
  }
}
