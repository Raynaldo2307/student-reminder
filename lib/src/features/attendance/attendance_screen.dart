import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/services/clockin_service.dart';
import 'package:students_reminder/src/services/firebase_data.dart';
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
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  final uid = AuthService.instance.currentUser?.uid ?? '';

  Future<void> _loadAttendanceData() async {
    try {
      final userId = AuthService.instance.currentUser?.uid;

      if (userId == null) {
        displaySnackBar(context, 'User not logged in');
        return;
      }

      // Use your existing method
      final snapshot = await FirebaseData().getAttendance(userId);

      // Check if empty
      if (snapshot.docs.isEmpty) {
        print('No attendance records found for user');
        return;
      }

      final Map<DateTime, List<Map<String, dynamic>>> events = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;

        if (timestamp != null) {
          final date = normalizeDate(timestamp.toDate());
          if (!events.containsKey(date)) {
            events[date] = [];
          }
          events[date]!.add(data);
        }
      }

      setState(() {
        _attendanceEvents.addAll(events);
      });
    } catch (e) {
      print('Error loading attendance: $e');
      if (mounted) {
        displaySnackBar(context, 'Failed to load attendance: $e');
      }
    }
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
        // Reload attendance data after clocking in
        await _loadAttendanceData();
      }
    }

    return Scaffold(
      backgroundColor: Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.1),
        centerTitle: true,
        title: Text(
          'Attendance',
          style: TextStyle(
            color: Color(0xFF1877F2),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Selector
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Check In', Icons.login_rounded, 0),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton('History', Icons.history_rounded, 1),
                ),
              ],
            ),
          ),

          Container(height: 8, color: Color(0xFFF0F2F5)),

          Expanded(
            child: index == 0 ? _buildAttendance(context) : _buildHistory(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'clock-fab',
        onPressed: clockIn,
        backgroundColor: Color(0xFF42B72A),
        icon: Icon(Icons.login_rounded, color: Colors.white),
        label: Text(
          'Clock In',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int tabIndex) {
    final isSelected = index == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => index = tabIndex),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1877F2) : Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: Color(0xFF1877F2), size: 24),
                SizedBox(width: 8),
                Text(
                  'Attendance Calendar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TableCalendar(
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Color(0xFF1877F2),
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Color(0xFF1877F2),
                ),
              ),
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Color(0xFF1877F2),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF42B72A),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                selectedTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                weekendTextStyle: TextStyle(color: Colors.red.shade400),
              ),
              eventLoader: (day) {
                return _attendanceEvents[normalizeDate(day)] ?? [];
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox();

                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: events.take(3).map((event) {
                        if (event is! Map<String, dynamic>) {
                          return const SizedBox();
                        }
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF42B72A),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            if (_selectedDay != null &&
                _attendanceEvents[normalizeDate(_selectedDay!)]?.isNotEmpty ==
                    true) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text(
                'Records for ${formatDate(_selectedDay!)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              ..._attendanceEvents[normalizeDate(_selectedDay!)]!.map((record) {
                final timestamp = (record['timestamp'] as Timestamp?)?.toDate();
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF42B72A),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        timestamp != null
                            ? TimeOfDay.fromDateTime(timestamp).format(context)
                            : 'Unknown time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendance(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 48,
                    color: Color(0xFF1877F2),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ready to Clock In',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Today\'s Status',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Map Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Color(0xFF1877F2),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Your Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Container(height: 300, child: GoogleMapComp()),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Time Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Color(0xFF1877F2),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        formatDate(DateTime.now()),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Color(0xFF42B72A),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        TimeOfDay.fromDateTime(DateTime.now()).format(context),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF42B72A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }
}
