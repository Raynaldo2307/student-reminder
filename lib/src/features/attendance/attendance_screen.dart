import 'package:flutter/material.dart';
import 'package:students_reminder/src/services/clockin_service.dart';
import 'package:students_reminder/src/services/others.dart';
import 'package:students_reminder/src/shared/misc.dart';
import 'package:students_reminder/src/widgets/google_map_comp.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int index = 0;

  //for history
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<Map<String, dynamic>>> _attendanceEvents = {};

  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    clockIn() async {
      final check = await ClockinService().performCheck(
        isCheckIn: true,
        posLat: 18.1,
        context: context,
        posLng: -77.1,
      );
      if (check) {
        displaySnackBar(context, "Clocked in");
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text("Attendance"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 20,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      index = 0;
                    });
                  },
                  child: Text("Attendance"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      index = 1;
                    });
                  },
                  child: Text("History"),
                ),
              ],
            ),
            index == 0
                ? _buildAttendance(context)
                : _buildHistory(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'clock-fab',
        onPressed: clockIn,
        icon: Icon(Icons.login),
        label: Text("Clock In"),
      ),
    );
  }

  Column _buildHistory() {
    return Column(
                  children: [
                    TableCalendar(
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      eventLoader: (day) {
                        return _attendanceEvents[normalizeDate(day)] ?? [];
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return const SizedBox();

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: events.take(3).map((event) {
                              if (event is! Map<String, dynamic>) {
                                return const SizedBox();
                              }
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.yellow,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                );
  }

  Column _buildAttendance(BuildContext context) {
    return Column(
      children: [
        //clockin info
        Text("Clock in"),
        Text("Todays Status: "),
        //map comp
        ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(10),
          child: Container(height: 400, child: GoogleMapComp()),
        ),
        const SizedBox(height: 20),
        //card comp
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatDate(DateTime.now())),
              Text(TimeOfDay.fromDateTime(DateTime.now()).format(context)),
            ],
          ),
        ),
      ],
    );
  }
}
