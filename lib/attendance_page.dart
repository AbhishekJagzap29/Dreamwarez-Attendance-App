import 'package:dw_attendance_app/Services/api_service.dart';
import 'package:dw_attendance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import '/models/attendance.dart';
import '/models/attendance_report.dart';
import '/services/attendance_services.dart';
import '/services/employee_service.dart';

class AttendancePage extends StatefulWidget {
  final bool isAdmin;
  final String currentUserName;

  const AttendancePage({
    super.key,
    required this.isAdmin,
    required this.currentUserName,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // coordinates
  final double targetLatitude = 18.5937255;
  final double targetLongitude = 73.7861112;
  final double allowedRadiusInMeters = 100000;

  List<Attendance> users = [];
  List<Attendance> filteredUsers = [];
  final AttendanceService _attendanceService = AttendanceService();
  final EmployeeService _employeeService = EmployeeService();
  bool _isLoading = true;
  bool _isFabVisible = true;
  Timer? _fabTimer;
  final TextEditingController _searchController = TextEditingController();

  String formatTime(DateTime? time) {
    if (time == null) return 'Not Recorded';
    final istLocation = tz.getLocation('Asia/Kolkata');
    final istTime =
        time is tz.TZDateTime ? time : tz.TZDateTime.from(time, istLocation);
    return '${istTime.day.toString().padLeft(2, '0')}-'
        '${istTime.month.toString().padLeft(2, '0')}-'
        '${istTime.year}  '
        '${istTime.hour.toString().padLeft(2, '0')}:'
        '${istTime.minute.toString().padLeft(2, '0')}:'
        '${istTime.second.toString().padLeft(2, '0')}';
  }

  void _showCustomSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 0,
        duration: duration,
      ),
    );
  }

  void _handleSessionExpired() {
    // Optional: show a message before logout
    _showCustomSnackBar(
      context: context,
      message: "Session expired. Please log in again.",
      backgroundColor: Colors.redAccent,
      icon: Icons.logout,
      duration: const Duration(seconds: 2),
    );

    // Navigate to MyApp (login/root)
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyApp()),
        (route) => false,
      );
    });
  }

  // Future<void> fetchAttendanceData() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final attendanceList = await _attendanceService.fetchAttendance();
  //     setState(() {
  //       if (widget.isAdmin) {
  //         users = attendanceList;
  //         filteredUsers = users;
  //       } else {
  //         users = attendanceList
  //             .where(
  //               (record) =>
  //                   record.name.toLowerCase() ==
  //                   widget.currentUserName.toLowerCase(),
  //             )
  //             .toList();
  //         if (users.isEmpty) {
  //           users = [
  //             Attendance(
  //               name: widget.currentUserName,
  //               checkIn: null,
  //               checkOut: null,
  //               lunchIn: null,
  //               lunchOut: null,
  //               daysPresent: 0,
  //               totalHours: '00:00:00',
  //               lunchDurationDisplay: '00:00:00',
  //             ),
  //           ];
  //         }
  //         filteredUsers = users;
  //       }
  //     });
  //   } catch (e) {
  //     _showCustomSnackBar(
  //       context: context,
  //       message: "Failed to load attendance data: $e",
  //       backgroundColor: Colors.redAccent,
  //       icon: Icons.error_outline,
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }
  Future<void> fetchAttendanceData() async {
    setState(() => _isLoading = true);
    try {
      final attendanceList = await _attendanceService.fetchAttendance();
      setState(() {
        if (widget.isAdmin) {
          users = attendanceList;
          filteredUsers = users;
        } else {
          users = attendanceList
              .where(
                (record) =>
                    record.name.toLowerCase() ==
                    widget.currentUserName.toLowerCase(),
              )
              .toList();

          if (users.isEmpty) {
            users = [
              Attendance(
                name: widget.currentUserName,
                checkIn: null,
                checkOut: null,
                lunchIn: null,
                lunchOut: null,
                daysPresent: 0,
                totalHours: '00:00:00',
                lunchDurationDisplay: '00:00:00',
              ),
            ];
          }
          filteredUsers = users;
        }
      });
    } on SessionExpiredException {
      _handleSessionExpired();
    } catch (e) {
      _showCustomSnackBar(
        context: context,
        message: "Failed to load attendance data: $e",
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    _fabTimer?.cancel();
    super.dispose();
  }

  Future<bool> isWithinAllowedRadius() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLatitude,
      targetLongitude,
    );

    return distanceInMeters <= allowedRadiusInMeters;
  }

  void markCheckIn(int index) async {
    if (users.isEmpty || index >= users.length) return;
    try {
      bool isNearby = await isWithinAllowedRadius();
      if (!isNearby) {
        _showCustomSnackBar(
          context: context,
          message: "Please be within the designated check-in area.",
          backgroundColor: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      final istLocation = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime.now(istLocation);
      final today = DateTime(now.year, now.month, now.day);
      final lastCheckIn = users[index].checkIn;
      final lastCheckInDate = lastCheckIn != null
          ? DateTime(lastCheckIn.year, lastCheckIn.month, lastCheckIn.day)
          : null;

      if (lastCheckInDate == today) {
        _showCustomSnackBar(
          context: context,
          message: "You have already checked in today.",
          backgroundColor: Colors.orangeAccent,
          icon: Icons.check_circle_outline,
        );
        return;
      }

      final attendance = users[index].copyWith(checkIn: now);
      await _attendanceService.checkIn(attendance);

      setState(() {
        users[index] = attendance;
        filteredUsers = users;
      });

      _showCustomSnackBar(
        context: context,
        message: "Check-in recorded successfully.",
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );
    } catch (e) {
      String errorMessage = "Failed to record check-in: $e";
      if (e.toString().contains("Please create an attendance record first")) {
        errorMessage = "Please create an attendance record before checking in.";
      }
      _showCustomSnackBar(
        context: context,
        message: errorMessage,
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  void markCheckOut(int index) async {
    if (users.isEmpty || index >= users.length) return;

    try {
      bool isNearby = await isWithinAllowedRadius();
      if (!isNearby) {
        _showCustomSnackBar(
          context: context,
          message: "Please be within the designated check-out area.",
          backgroundColor: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      final istLocation = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime.now(istLocation);
      final today = DateTime(now.year, now.month, now.day);
      final checkIn = users[index].checkIn;

      final checkInIst = checkIn is tz.TZDateTime
          ? checkIn
          : tz.TZDateTime.from(checkIn!, istLocation);
      final checkInDate = DateTime(
        checkInIst.year,
        checkInIst.month,
        checkInIst.day,
      );
      if (checkInDate != today) {
        _showCustomSnackBar(
          context: context,
          message: "Cannot check out for a different day.",
          backgroundColor: Colors.redAccent,
          icon: Icons.calendar_today,
        );
        return;
      }

      if (users[index].checkOut == null) {
        final duration = now.difference(checkInIst);
        final totalSeconds = duration.inSeconds;
        final hours = totalSeconds ~/ 3600;
        final minutes = (totalSeconds % 3600) ~/ 60;
        final seconds = totalSeconds % 60;
        final totalHoursDisplay =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        final updatedAttendance = users[index].copyWith(
          checkOut: now,
          totalHours: totalHoursDisplay,
        );

        await _attendanceService.checkOut(updatedAttendance);

        setState(() {
          users[index] = updatedAttendance;
          filteredUsers = users;
        });

        _showCustomSnackBar(
          context: context,
          message: "Check-out recorded successfully.",
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      _showCustomSnackBar(
        context: context,
        message: "Failed to record check-out: $e",
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  void markLunchOut(int index) async {
    if (users.isEmpty || index >= users.length) return;

    try {
      bool isNearby = await isWithinAllowedRadius();
      if (!isNearby) {
        _showCustomSnackBar(
          context: context,
          message: "Please be within the designated lunch-out area.",
          backgroundColor: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      final istLocation = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime.now(istLocation);
      final today = DateTime(now.year, now.month, now.day);
      final checkIn = users[index].checkIn;

      final checkInIst = checkIn is tz.TZDateTime
          ? checkIn
          : tz.TZDateTime.from(checkIn!, istLocation);
      final checkInDate = DateTime(
        checkInIst.year,
        checkInIst.month,
        checkInIst.day,
      );
      if (checkInDate != today) {
        _showCustomSnackBar(
          context: context,
          message: "Cannot mark lunch out for a different day.",
          backgroundColor: Colors.redAccent,
          icon: Icons.calendar_today,
        );
        return;
      }

      if (users[index].lunchOut != null) {
        _showCustomSnackBar(
          context: context,
          message: "Lunch out already recorded for today.",
          backgroundColor: Colors.orangeAccent,
          icon: Icons.warning_amber,
        );
        return;
      }

      final updatedAttendance = users[index].copyWith(lunchOut: now);
      await _attendanceService.lunchOut(updatedAttendance);

      setState(() {
        users[index] = updatedAttendance;
        filteredUsers = users;
      });

      _showCustomSnackBar(
        context: context,
        message: "Lunch out recorded successfully.",
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );
    } catch (e) {
      _showCustomSnackBar(
        context: context,
        message: "Failed to record lunch out: $e",
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  void markLunchIn(int index) async {
    if (users.isEmpty || index >= users.length) return;

    try {
      bool isNearby = await isWithinAllowedRadius();
      if (!isNearby) {
        _showCustomSnackBar(
          context: context,
          message: "Please be within the designated lunch-in area.",
          backgroundColor: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      final istLocation = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime.now(istLocation);
      final today = DateTime(now.year, now.month, now.day);
      final lunchOut = users[index].lunchOut;

      final lunchOutIst = lunchOut is tz.TZDateTime
          ? lunchOut
          : tz.TZDateTime.from(lunchOut!, istLocation);
      final lunchOutDate = DateTime(
        lunchOutIst.year,
        lunchOutIst.month,
        lunchOutIst.day,
      );
      if (lunchOutDate != today) {
        _showCustomSnackBar(
          context: context,
          message: "Cannot mark lunch in for a different day.",
          backgroundColor: Colors.redAccent,
          icon: Icons.calendar_today,
        );
        return;
      }

      if (users[index].lunchIn == null) {
        final duration = now.difference(lunchOutIst);
        final totalSeconds = duration.inSeconds;
        final hours = totalSeconds ~/ 3600;
        final minutes = (totalSeconds % 3600) ~/ 60;
        final seconds = totalSeconds % 60;
        final lunchDurationDisplay =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        final updatedAttendance = users[index].copyWith(
          lunchIn: now,
          lunchDurationDisplay: lunchDurationDisplay,
        );

        await _attendanceService.lunchIn(updatedAttendance);

        setState(() {
          users[index] = updatedAttendance;
          filteredUsers = users;
        });

        _showCustomSnackBar(
          context: context,
          message: "Lunch in recorded successfully.",
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      _showCustomSnackBar(
        context: context,
        message: "Failed to record lunch in: $e",
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  void createAttendanceRecord() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showCustomSnackBar(
          context: context,
          message: "Please turn on your location services.",
          backgroundColor: Colors.orangeAccent,
          icon: Icons.gps_off,
        );
        return;
      }

      bool isNearby = await isWithinAllowedRadius();
      if (!isNearby) {
        _showCustomSnackBar(
          context: context,
          message: "Please be within the designated area to create a record.",
          backgroundColor: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      final istLocation = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime.now(istLocation);
      final today = DateTime(now.year, now.month, now.day);

      // Check for existing records for today
      final todayRecords = users.where((user) {
        if (user.name.toLowerCase() != widget.currentUserName.toLowerCase()) {
          return false;
        }
        if (user.checkIn == null) {
          return false;
        }
        final checkInDate = DateTime(
          user.checkIn!.year,
          user.checkIn!.month,
          user.checkIn!.day,
        );
        return checkInDate == today;
      }).toList();

      // Count records for today
      final recordCount = todayRecords.length;

      if (recordCount >= 1) {
        _showCustomSnackBar(
          context: context,
          message: "Attendance record already created for today.",
          backgroundColor: Colors.green,
          icon: Icons.warning_amber,
        );
        return;
      }

      // Create new attendance record
      await _attendanceService.markAttendance(widget.currentUserName);
      await fetchAttendanceData();

      // Hide FAB and start 25-minute timer
      setState(() {
        _isFabVisible = false;
      });
      _fabTimer?.cancel(); // Cancel any existing timer
      _fabTimer = Timer(const Duration(minutes: 25), () {
        setState(() {
          _isFabVisible = true;
        });
      });

      _showCustomSnackBar(
        context: context,
        message: "Attendance record created successfully.",
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );
    } catch (e) {
      _showCustomSnackBar(
        context: context,
        message: "Failed to create attendance record: $e",
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  void _filterUsers() {
    setState(() {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users
            .where(
              (user) => user.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Attendance Hub",
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        elevation: 4,
        centerTitle: true,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF1F6F9),
              Color(0xFFE5EAF0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 7, 56, 80)),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isAdmin
                          ? "Team Attendance Overview"
                          : "Your Attendance Tracker",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.isAdmin)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search team members...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterUsers();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: filteredUsers.isEmpty
                          ? const Center(
                              child: Text(
                                "No attendance records available. Start by creating one.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  color: Colors.white,
                                  shadowColor: Colors.black.withOpacity(0.1),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                255,
                                                7,
                                                56,
                                                80,
                                              ),
                                              child: Text(
                                                user.name[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                user.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildInfoRow(
                                          icon: Icons.login,
                                          color: Colors.green,
                                          label: "Check-In",
                                          value: formatTime(user.checkIn),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          icon: Icons.restaurant_menu,
                                          color: Colors.orange,
                                          label: "Lunch Out",
                                          value: formatTime(user.lunchOut),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          icon: Icons.restaurant,
                                          color: Colors.blue,
                                          label: "Lunch In",
                                          value: formatTime(user.lunchIn),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          icon: Icons.logout,
                                          color: Colors.red,
                                          label: "Check-Out",
                                          value: formatTime(user.checkOut),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          icon: Icons.timer,
                                          color: Colors.black54,
                                          label: "Lunch Duration",
                                          value: user.lunchDurationDisplay,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          icon: Icons.access_time,
                                          color: Colors.black54,
                                          label: "Total Hours",
                                          value: user.totalHours,
                                        ),
                                        const SizedBox(height: 24),
                                        if (!widget.isAdmin)
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: user.daysPresent ==
                                                              0 ||
                                                          user.checkIn != null
                                                      ? null
                                                      : () =>
                                                          markCheckIn(index),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green[700],
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    elevation: 2,
                                                  ),
                                                  child: const Text(
                                                    'Check In',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: user.checkIn ==
                                                              null ||
                                                          user.lunchOut != null
                                                      ? null
                                                      : () =>
                                                          markLunchOut(index),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.orange[700],
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    elevation: 2,
                                                  ),
                                                  child: const Text(
                                                    'Lunch Out',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: user.lunchOut ==
                                                              null ||
                                                          user.lunchIn != null
                                                      ? null
                                                      : () =>
                                                          markLunchIn(index),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue[700],
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    elevation: 2,
                                                  ),
                                                  child: const Text(
                                                    'Lunch In',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: user.lunchIn ==
                                                              null ||
                                                          user.checkOut != null
                                                      ? null
                                                      : () =>
                                                          markCheckOut(index),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red[700],
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    elevation: 2,
                                                  ),
                                                  child: const Text(
                                                    'Check Out',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              if (widget.isAdmin) {
                                                final reports =
                                                    await _attendanceService
                                                        .fetchAllEmployeesAttendanceReport(
                                                  month: DateTime.now()
                                                      .month
                                                      .toString()
                                                      .padLeft(
                                                        2,
                                                        '0',
                                                      ),
                                                  year: DateTime.now().year,
                                                );

                                                final userReport =
                                                    reports.firstWhere(
                                                  (report) =>
                                                      report.employeeName
                                                          .toLowerCase() ==
                                                      user.name.toLowerCase(),
                                                  orElse: () =>
                                                      AttendanceReport(
                                                    employeeId: 0,
                                                    employeeName: user.name,
                                                    month: DateTime.now()
                                                        .month
                                                        .toString()
                                                        .padLeft(
                                                          2,
                                                          '0',
                                                        ),
                                                    year: DateTime.now().year,
                                                    daysPresent: 0,
                                                    totalHours: '00:00:00',
                                                    fullLeaveDays: 0,
                                                    halfLeaveDays: 0,
                                                    wfhDays: 0,
                                                    department: '',
                                                    totalLunchDuration: '',
                                                  ),
                                                );

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (
                                                      context,
                                                    ) =>
                                                        UserReportPage(
                                                      attendanceReport:
                                                          userReport,
                                                      currentUserName:
                                                          user.name,
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                final reports =
                                                    await _attendanceService
                                                        .fetchAllEmployeesAttendanceReport(
                                                  month: DateTime.now()
                                                      .month
                                                      .toString()
                                                      .padLeft(
                                                        2,
                                                        '0',
                                                      ),
                                                  year: DateTime.now().year,
                                                );

                                                final userReport =
                                                    reports.firstWhere(
                                                  (report) =>
                                                      report.employeeName
                                                          .toLowerCase() ==
                                                      widget.currentUserName
                                                          .toLowerCase(),
                                                  orElse: () => throw Exception(
                                                    'Report not found for ${widget.currentUserName}',
                                                  ),
                                                );

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (
                                                      context,
                                                    ) =>
                                                        UserReportPage(
                                                      attendanceReport:
                                                          userReport,
                                                      currentUserName: widget
                                                          .currentUserName,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              _showCustomSnackBar(
                                                context: context,
                                                message:
                                                    "Failed to load report: $e",
                                                backgroundColor:
                                                    Colors.redAccent,
                                                icon: Icons.error_outline,
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 7, 56, 80),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            elevation: 2,
                                            minimumSize:
                                                const Size(double.infinity, 0),
                                          ),
                                          child: const Text(
                                            'View Report',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: !widget.isAdmin && _isFabVisible
          ? FloatingActionButton(
              onPressed: createAttendanceRecord,
              backgroundColor: const Color.fromARGB(255, 7, 56, 80),
              tooltip: 'Create Attendance Record',
              child: const Icon(Icons.add, color: Colors.orange),
            )
          : null,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          "$label: $value",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class UserReportPage extends StatefulWidget {
  final AttendanceReport attendanceReport;
  final String currentUserName;

  const UserReportPage({
    super.key,
    required this.attendanceReport,
    required this.currentUserName,
  });

  @override
  State<UserReportPage> createState() => _UserReportPageState();
}

class _UserReportPageState extends State<UserReportPage> {
  final AttendanceService _attendanceService = AttendanceService();
  AttendanceReport? _currentReport;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  void _showCustomSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 0,
        duration: duration,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentReport = widget.attendanceReport;
    try {
      _selectedMonth = int.parse(widget.attendanceReport.month);
      _selectedYear = widget.attendanceReport.year;
    } catch (e) {
      _selectedMonth = DateTime.now().month;
      _selectedYear = DateTime.now().year;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  bool _hasNoData(AttendanceReport? report) {
    if (report == null) return true;
    return report.daysPresent == 0 &&
        report.totalHours == '00:00:00' &&
        report.fullLeaveDays == 0 &&
        report.halfLeaveDays == 0 &&
        report.wfhDays == 0;
  }

  Future<void> _showMonthPicker() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Month'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = month == _selectedMonth;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _updateMonth(month);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromARGB(255, 7, 56, 80)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromARGB(255, 7, 56, 80)
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getMonthName(month).substring(0, 3),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showYearPicker() async {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - 5;
    final endYear = currentYear + 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: endYear - startYear + 1,
              itemBuilder: (context, index) {
                final year = startYear + index;
                final isSelected = year == _selectedYear;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _updateYear(year);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromARGB(255, 7, 56, 80)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromARGB(255, 7, 56, 80)
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        year.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _updateMonth(int month) {
    if (month != _selectedMonth) {
      setState(() {
        _selectedMonth = month;
      });
      _fetchReportForSelectedDate();
    }
  }

  void _updateYear(int year) {
    if (year != _selectedYear) {
      setState(() {
        _selectedYear = year;
      });
      _fetchReportForSelectedDate();
    }
  }

  Future<void> _fetchReportForSelectedDate() async {
    setState(() => _isLoading = true);
    try {
      final month = _selectedMonth.toString().padLeft(2, '0');
      final year = _selectedYear;

      final reports = await _attendanceService
          .fetchAllEmployeesAttendanceReport(month: month, year: year);

      final userReport = reports.firstWhere(
        (report) =>
            report.employeeName.toLowerCase() ==
            widget.currentUserName.toLowerCase(),
        orElse: () => AttendanceReport(
          employeeId: 0,
          employeeName: widget.currentUserName,
          month: month,
          year: year,
          daysPresent: 0,
          totalHours: '00:00:00',
          fullLeaveDays: 0,
          halfLeaveDays: 0,
          wfhDays: 0,
          department: '',
          totalLunchDuration: '',
        ),
      );

      setState(() {
        _currentReport = userReport;
      });
    } catch (e) {
      _showCustomSnackBar(
        context: context,
        message:
            "Unable to load report for ${_getMonthName(_selectedMonth)} $_selectedYear: $e",
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      setState(() {
        final month = _selectedMonth.toString().padLeft(2, '0');
        _currentReport = AttendanceReport(
          employeeId: 0,
          employeeName: widget.currentUserName,
          month: month,
          year: _selectedYear,
          daysPresent: 0,
          totalHours: '00:00:00',
          fullLeaveDays: 0,
          halfLeaveDays: 0,
          wfhDays: 0,
          department: '',
          totalLunchDuration: '',
        );
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${_currentReport?.employeeName ?? widget.currentUserName}'s Performance",
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        elevation: 4,
        centerTitle: true,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F6F9), Color(0xFFE5EAF0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 7, 56, 80)),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _showMonthPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_month,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getMonthName(_selectedMonth),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showYearPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedYear.toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _hasNoData(_currentReport)
                          ? Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.inbox_outlined,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No attendance data available',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'for ${_getMonthName(_selectedMonth)} $_selectedYear',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        7,
                                        56,
                                        80,
                                      ),
                                      child: Text(
                                        (_currentReport?.employeeName ??
                                                widget.currentUserName)[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _currentReport?.employeeName ??
                                          widget.currentUserName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_currentReport?.department.isNotEmpty ??
                                        false)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _currentReport!.department,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black54,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    const SizedBox(height: 24),
                                    _buildReportItem(
                                      icon: Icons.check_circle,
                                      color: Colors.green[700]!,
                                      label: "Days Present",
                                      value: (_currentReport?.daysPresent ?? 0)
                                          .toString(),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildReportItem(
                                      icon: Icons.access_time,
                                      color: Colors.orange[700]!,
                                      label: "Total Hours",
                                      value: _currentReport?.totalHours ??
                                          '00:00:00',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildReportItem(
                                      icon: Icons.home_work,
                                      color: Colors.purple[700]!,
                                      label: "Work From Home",
                                      value: (_currentReport?.wfhDays ?? 0)
                                          .toString(),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildReportItem(
                                      icon: Icons.timelapse,
                                      color: Colors.teal[700]!,
                                      label: "Half Days",
                                      value:
                                          (_currentReport?.halfLeaveDays ?? 0)
                                              .toString(),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildReportItem(
                                      icon: Icons.event_busy,
                                      color: Colors.red[700]!,
                                      label: "Full Leave Days",
                                      value:
                                          (_currentReport?.fullLeaveDays ?? 0)
                                              .toString(),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildReportItem(
                                      icon: Icons.lunch_dining,
                                      color: Colors.blueGrey,
                                      label: "Total Lunch Duration",
                                      value:
                                          _currentReport?.totalLunchDuration ??
                                              '00:00:00',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 20),
                        label: const Text(
                          "Back to Dashboard",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 7, 56, 80),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildReportItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
