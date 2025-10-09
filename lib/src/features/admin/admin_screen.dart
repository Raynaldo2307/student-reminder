import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/services/firebase_data.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showStudentList = false;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> getUserCount() async {
    final snapshot = await FirebaseData().readStudents();
    final attendancesnap = await FirebaseData().getAttendance(uid);

    // No student data
    if (snapshot.docs.isEmpty) {
      _mocData = {
        'totalStudents': 0,
        'mobileStudents': 0,
        'webStudents': 0,
        'avgAttendance': 0,
        'activeToday': 0,
      };
      return;
    }

    // Student data
    final studentDocs = snapshot.docs;
    int mobileCount = 0;
    int webCount = 0;
    int totalAttendance = 0;
    int activeToday = 0;
    final now = DateTime.now();

    // Count mobile/web
    for (final doc in studentDocs) {
      final data = doc.data();

      final platform = data['courseGroup']?.toString().toLowerCase();
      if (platform == 'mobile') {
        mobileCount++;
      } else if (platform == 'web') {
        webCount++;
      }
    }

    // Attendance data
    if (attendancesnap.docs.isNotEmpty) {
      final attendanceDocs = attendancesnap.docs;

      for (final attDoc in attendanceDocs) {
        final data = attDoc.data();

        // Attendance count
        if (data['attendance'] is int) {
          totalAttendance += attendanceDocs.length;
        } else if (data['attendance'] is List) {
          totalAttendance += (data['attendance'] as List).length;
        }

        // Active today
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          if (createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day) {
            activeToday++;
          }
        }
      }
    }

    // Calculate average attendance
    final avgAttendance = (totalAttendance / (studentDocs.length)).toDouble();

    _mocData = {
      'totalStudents': studentDocs.length,
      'mobileStudents': mobileCount,
      'webStudents': webCount,
      'avgAttendance': avgAttendance.isFinite ? avgAttendance : 0,
      'activeToday': activeToday,
    };
  }

  final List<Map<String, dynamic>> _mockStudents = [
    {'name': 'John Smith', 'course': 'mobile', 'attendance': 92, 'id': '1'},
    {'name': 'Sarah Johnson', 'course': 'web', 'attendance': 88, 'id': '2'},
    {'name': 'Michael Brown', 'course': 'mobile', 'attendance': 95, 'id': '3'},
    {'name': 'Emily Davis', 'course': 'web', 'attendance': 78, 'id': '4'},
    {'name': 'David Wilson', 'course': 'mobile', 'attendance': 85, 'id': '5'},
    {'name': 'Jessica Martinez', 'course': 'web', 'attendance': 91, 'id': '6'},
    {'name': 'Chris Anderson', 'course': 'mobile', 'attendance': 82, 'id': '7'},
    {'name': 'Amanda Taylor', 'course': 'web', 'attendance': 89, 'id': '8'},
  ];
  Map<String, dynamic> _mocData = {};

  @override
  void initState() {
    super.initState();
    getUserCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _mockStudents;
    return _mockStudents.where((student) {
      return student['name'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [_buildHeader("Admin"), SizedBox(height: 20)],
                ),
              ),
            ),

            // Analytics Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildAnalyticsCards(),
                  ],
                ),
              ),
            ),

            // Students Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Students',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showStudentList = !_showStudentList;
                            });
                          },
                          icon: AnimatedRotation(
                            turns: _showStudentList ? 0.5 : 0,
                            duration: Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 32,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showStudentList) ...[
                      SizedBox(height: 12),
                      _buildSearchBar(),
                    ],
                  ],
                ),
              ),
            ),

            // Student List
            if (_showStudentList)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= _filteredStudents.length) return null;
                    return _buildStudentCard(_filteredStudents[index], index);
                  }, childCount: _filteredStudents.length),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String displayName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Administrator',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF34C759).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Color(0xFF34C759),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Active',
                        style: GoogleFonts.poppins(
                          color: Color(0xFF34C759),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => showLogoutModal(
              context,
              onLogout: () => AuthService.instance.logout(),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.person_rounded,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnalyticCard(
                'Total Students',
                '${_mocData['totalStudents']}',
                Icons.people_rounded,
                Color(0xFF007AFF),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticCard(
                'Avg Attendance',
                '${_mocData['avgAttendance']}%',
                Icons.trending_up_rounded,
                Color(0xFF34C759),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticCard(
                'Mobile Dev',
                '${_mocData['mobileStudents']}',
                Icons.phone_iphone_rounded,
                Color(0xFFFF9500),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticCard(
                'Web Dev',
                '${_mocData['webStudents']}',
                Icons.laptop_mac_rounded,
                Color(0xFF5856D6),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildWideAnalyticCard(
          'Active Today',
          '${_mocData['activeToday']} students checked in',
          Icons.check_circle_rounded,
          Color(0xFF34C759),
        ),
      ],
    );
  }

  Widget _buildAnalyticCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideAnalyticCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: GoogleFonts.poppins(fontSize: 17),
        decoration: InputDecoration(
          hintText: 'Search students',
          hintStyle: GoogleFonts.poppins(fontSize: 17, color: Colors.black38),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.black38,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.cancel_rounded,
                    color: Colors.black38,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    final color = student['course'] == 'mobile'
        ? Color(0xFFFF9500)
        : Color(0xFF5856D6);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to student detail
            print('Tapped on ${student['name']}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      student['name']
                          .split(' ')
                          .map((n) => n[0])
                          .take(2)
                          .join(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            student['course'] == 'mobile'
                                ? Icons.phone_iphone_rounded
                                : Icons.laptop_mac_rounded,
                            size: 14,
                            color: Colors.black38,
                          ),
                          SizedBox(width: 4),
                          Text(
                            student['course'] == 'mobile'
                                ? 'Mobile Development'
                                : 'Web Development',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getAttendanceColor(
                          student['attendance'],
                        ).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${student['attendance']}%',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getAttendanceColor(student['attendance']),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.black26,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAttendanceColor(int attendance) {
    if (attendance >= 90) return Color(0xFF34C759);
    if (attendance >= 75) return Color(0xFFFF9500);
    return Color(0xFFFF3B30);
  }

  void showLogoutModal(BuildContext context, {required VoidCallback onLogout}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(height: 24),
              Icon(
                Icons.power_settings_new_rounded,
                size: 56,
                color: Color(0xFFFF3B30),
              ),
              SizedBox(height: 16),
              Text(
                'Sign Out?',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You will need to sign in again to access admin features.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54),
              ),
              SizedBox(height: 24),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Sign Out',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF007AFF),
                        side: BorderSide.none,
                        backgroundColor: Color(0xFFF5F5F7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
