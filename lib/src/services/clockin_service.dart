import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:students_reminder/src/core/distance_util.dart'
    as distance_utils;
import 'package:students_reminder/src/models/attendance_model.dart';
import 'package:students_reminder/src/services/firebase_data.dart';
import 'package:students_reminder/src/shared/misc.dart';

class ClockinService {
  //bool to get time, whether before or after 8
  bool isBefore8AM() {
    final now = DateTime.now();
    return now.hour < 8; // before 8 AM
  }

  bool isExactly8AM() {
    final now = DateTime.now();
    return now.hour == 8 && now.minute == 0; // exactly 8:00 AM
  }

  bool isAfter4AM() {
    final now = DateTime.now();
    return now.hour >= 4; // at or after 8 AM
  }

  Future<bool> performCheck({
    required bool isCheckIn,
    required BuildContext context,
    required double posLat,
    required double posLng,
  }) async {
    final now = DateTime.now();
    final isRestrictedDay =
        now.weekday == DateTime.wednesday || now.weekday == DateTime.thursday;

    //if its not the restricted days and u press checkin then it will sign u in without checking the location at stony hill
    if (!isRestrictedDay && isCheckIn) {
      if (isExactly8AM() && isBefore8AM()) {
        FirebaseData().saveAttendance(
          AttendanceDay(
            date: DateTime.now().toIso8601String(),
            status: "On Time",
            clockInAt: DateTime.now(),
            clockInLat: posLat,
            clockInLng: posLng,
          ),
        );
        return true;
      } else if (isAfter4AM()) {
        displaySnackBar(context, "Class is already over");
        return false;
      } else {
        displaySnackBar(
          context,
          "You are either not at stony hill or something went wrong",
        );
        return false;
      }
    } else if (isCheckIn && isRestrictedDay) {
      const stonyHillLat = 18.0937;
      const stonyHillLng = -76.7880;
      const allowedRadiusMeters = 200;
      final distance = distance_utils.calculateDistanceMeters(
        posLat,
        posLng,
        stonyHillLat,
        stonyHillLng,
      );
      bool isAtStonyHill = distance <= allowedRadiusMeters;

      if (isExactly8AM() && isBefore8AM() && isAtStonyHill) {
        FirebaseData().saveAttendance(
          AttendanceDay(
            date: DateTime.now().toIso8601String(),
            status: "On Time",
            clockInAt: DateTime.now(),
            clockInLat: posLat,
            clockInLng: posLng,
          ),
        );
        return true;
      } else if (isAfter4AM()) {
        displaySnackBar(context, "Class is already over");
        return false;
      } else {
        displaySnackBar(
          context,
          "You are either not at stony hill or something went wrong",
        );
        return false;
      }
    } else {
      return false;
    }
  }
}
