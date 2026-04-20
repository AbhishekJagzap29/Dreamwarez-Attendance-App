// // import 'package:dw_attendance_app/models/employee.dart';
// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import '/services/api_service.dart';
// // import '/services/employee_service.dart';
// // import '/services/onesignal_service.dart';
// // import 'home_page.dart';
// // import 'package:timezone/data/latest.dart' as tz;
// // import 'package:connectivity_plus/connectivity_plus.dart';
// // import 'package:onesignal_flutter/onesignal_flutter.dart';
// // import 'dart:convert';
// // import 'register_page.dart';

// // void main() {
// //   tz.initializeTimeZones();
// //   runApp(const MyApp());
// // }

// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});

// //   Future<Widget> _getInitialPage() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
// //     final sessionId = prefs.getString('sessionId');
// //     final email = prefs.getString('email') ?? 'Unknown';
// //     final employeeId = prefs.getString('employeeId') ?? 'N/A';
// //     final address = prefs.getString('address') ?? 'N/A';
// //     final mobile = prefs.getString('mobile') ?? 'N/A';
// //     final numericId = prefs.getInt('numericId') ?? 0;
// //     final employeeName = prefs.getString('employeeName') ?? email;
// //     final groupsJson = prefs.getString('groups') ?? '[]';
// //     final groups = List<String>.from(jsonDecode(groupsJson));

// //     if (isLoggedIn && sessionId != null && sessionId.isNotEmpty) {
// //       debugPrint('Using stored session data for user: $email, groups: $groups');
// //       return HomePage(
// //         name: employeeName,
// //         employeeId: employeeId,
// //         numericId: numericId,
// //         groups: groups,
// //         address: address,
// //         mobile: mobile,
// //         jobTitle: '',
// //       );
// //     } else {
// //       debugPrint('No valid session found or cleared, redirecting to login');
// //       await prefs.clear();
// //       return const MyHomePage(title: 'Login');
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       title: 'Employee Attendance',
// //       theme: ThemeData(
// //         scaffoldBackgroundColor: const Color.fromARGB(255, 241, 246, 249),
// //         appBarTheme: const AppBarTheme(
// //           backgroundColor: Color.fromARGB(255, 205, 214, 219),
// //           iconTheme: IconThemeData(color: Colors.white),
// //           titleTextStyle: TextStyle(
// //             color: Colors.white,
// //             fontSize: 20,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         colorScheme: const ColorScheme.light(
// //           primary: Color.fromARGB(255, 207, 214, 217),
// //         ),
// //       ),
// //       routes: {
// //         '/login': (context) => const MyHomePage(title: 'Login'),
// //         '/register': (context) => const RegisterPage(),
// //       },
// //       home: FutureBuilder<Widget>(
// //         future: _getInitialPage(),
// //         builder: (context, snapshot) {
// //           if (snapshot.connectionState == ConnectionState.waiting) {
// //             return const Scaffold(
// //               body: Center(child: CircularProgressIndicator()),
// //             );
// //           } else if (snapshot.hasError) {
// //             debugPrint('Error in _getInitialPage: ${snapshot.error}');
// //             return const MyHomePage(title: 'Login');
// //           } else {
// //             return snapshot.data!;
// //           }
// //         },
// //       ),
// //     );
// //   }
// // }

// // class MyHomePage extends StatefulWidget {
// //   const MyHomePage({super.key, required this.title});
// //   final String title;

// //   @override
// //   State<MyHomePage> createState() => _MyHomePageState();
// // }

// // class _MyHomePageState extends State<MyHomePage>
// //     with SingleTickerProviderStateMixin {
// //   bool _isObscure = true;
// //   bool _isLoading = false;
// //   final _formKey = GlobalKey<FormState>();
// //   final TextEditingController _emailController = TextEditingController();
// //   final TextEditingController _passwordController = TextEditingController();
// //   final ApiService _apiService = ApiService();
// //   final EmployeeService _employeeService = EmployeeService();
// //   late AnimationController _animationController;
// //   late Animation<double> _logoAnimation;
// //   late Animation<double> _buttonAnimation;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _animationController = AnimationController(
// //       duration: const Duration(milliseconds: 1000),
// //       vsync: this,
// //     )..repeat(reverse: true);
// //     _logoAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
// //       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
// //     );
// //     _buttonAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
// //       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _emailController.dispose();
// //     _passwordController.dispose();
// //     _animationController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _handleLogin() async {
// //     if (!_formKey.currentState!.validate()) return;

// //     setState(() => _isLoading = true);

// //     try {
// //       final connectivityResult = await Connectivity().checkConnectivity();
// //       if (!connectivityResult.contains(ConnectivityResult.mobile) &&
// //           !connectivityResult.contains(ConnectivityResult.wifi)) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           _buildSnackBar("You're Offline", Colors.red),
// //         );
// //         setState(() => _isLoading = false);
// //         return;
// //       }

// //       final prefs = await SharedPreferences.getInstance();
// //       final email = _emailController.text.trim().toLowerCase();
// //       final password = _passwordController.text.trim();

// //       final sessionData = await _apiService.authenticateUser(
// //         email: email,
// //         password: password,
// //       );

// //       // Fetch user groups if not included in auth response
// //       List<String> groups = sessionData['groups'];
// //       if (groups.isEmpty) {
// //         groups = await _apiService.getUserGroups(
// //           sessionId: sessionData['sessionId'],
// //           userId: sessionData['user_id'].toString(),
// //         );
// //         if (groups.isEmpty) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             _buildSnackBar(
// //                 'Warning: Could not fetch user permissions. Limited access granted.',
// //                 Colors.orange),
// //           );
// //         }
// //       }

// //       // Initialize OneSignal
// //       final oneSignalService = OneSignalService(context: context);
// //       await oneSignalService.initOneSignal(sessionData['user_id'].toString());

// //       // Get player_id from OneSignal and send to backend
// //       try {
// //         final status = await OneSignal.shared.getDeviceState();
// //         final playerId = status?.userId;
// //         if (playerId != null) {
// //           await _apiService.savePlayerId(
// //             playerId: playerId,
// //             sessionId: sessionData['sessionId'],
// //           );
// //           await prefs.setString('player_id', playerId);
// //         } else {
// //           debugPrint('No valid player ID received from OneSignal');
// //         }
// //       } catch (e) {
// //         debugPrint('Player ID save failed: $e');
// //       }

// //       // Fetch employee info
// //       final employees = await _employeeService.getEmployees();
// //       final employee = employees.firstWhere(
// //         (e) => e.email.toLowerCase() == email.toLowerCase(),
// //         orElse: () => Employee(
// //           id: sessionData['user_id'],
// //           name: sessionData['name'],
// //           employeeId: 'N/A',
// //           jobTitle: '',
// //           dob: '',
// //           address: 'N/A',
// //           mobile: 'N/A',
// //           email: email,
// //           roleType: sessionData['role'] ?? '',
// //           gender: '',
// //         ),
// //       );

// //       // Save session data
// //       await prefs.setString('email', email);
// //       await prefs.setString('employeeId', employee.employeeId ?? 'N/A');
// //       await prefs.setString('address', employee.address);
// //       await prefs.setString('mobile', employee.mobile);
// //       await prefs.setBool('isLoggedIn', true);
// //       await prefs.setString('sessionId', sessionData['sessionId']);
// //       await prefs.setInt('numericId', employee.id);
// //       await prefs.setString('employeeName', employee.name);
// //       await prefs.setString('device_id', sessionData['device_id']);
// //       await prefs.setString('groups', jsonEncode(groups));

// //       debugPrint('handleLogin: groups = $groups');

// //       if (!mounted) return;

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         _buildSnackBar('Login Successful!', Colors.green),
// //       );

// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(
// //           builder: (context) => HomePage(
// //             name: employee.name,
// //             numericId: employee.id,
// //             employeeId: employee.employeeId ?? 'N/A',
// //             groups: groups,
// //             address: employee.address,
// //             mobile: employee.mobile,
// //             jobTitle: employee.jobTitle,
// //           ),
// //         ),
// //       );
// //     } catch (e) {
// //       String errorMessage = _mapError(e.toString());
// //       debugPrint('Login error: $errorMessage');
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         _buildSnackBar(errorMessage, Colors.red),
// //       );
// //     } finally {
// //       if (mounted) {
// //         setState(() => _isLoading = false);
// //       }
// //     }
// //   }

// //   SnackBar _buildSnackBar(String message, Color color) {
// //     return SnackBar(
// //       behavior: SnackBarBehavior.floating,
// //       backgroundColor: Colors.transparent,
// //       elevation: 0,
// //       duration: const Duration(seconds: 3),
// //       content: Center(
// //         child: Container(
// //           padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 13.0),
// //           decoration: BoxDecoration(
// //             color: color,
// //             borderRadius: BorderRadius.circular(20),
// //           ),
// //           child: Text(
// //             message,
// //             textAlign: TextAlign.center,
// //             style: const TextStyle(color: Colors.white),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   String _mapError(String error) {
// //     if (error.contains('Device is already associated')) {
// //       return 'This device is already associated with another account. Contact your administrator.';
// //     } else if (error.contains('Account is locked to another device')) {
// //       return 'Your account is locked to another device. Contact your administrator.';
// //     } else if (error.contains('Invalid email or password') ||
// //         error.toLowerCase().contains('access denied')) {
// //       return 'Invalid email or password';
// //     } else if (error.contains('SocketException') ||
// //         error.contains('Connection refused') ||
// //         error.contains('Network is unreachable')) {
// //       return 'Unable to reach server';
// //     }
// //     return error.replaceFirst('Exception: ', '');
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: SafeArea(
// //         child: Center(
// //           child: SingleChildScrollView(
// //             padding:
// //                 const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
// //             child: Container(
// //               constraints: const BoxConstraints(maxWidth: 400),
// //               padding: const EdgeInsets.all(32.0),
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(20),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.grey.withOpacity(0.3),
// //                     blurRadius: 15,
// //                     offset: const Offset(0, 8),
// //                   ),
// //                 ],
// //               ),
// //               child: Form(
// //                 key: _formKey,
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     ScaleTransition(
// //                       scale: _logoAnimation,
// //                       child: Image.asset(
// //                         'assets/images/logo1.png',
// //                         height: 120,
// //                         fit: BoxFit.contain,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 32),
// //                     const Text(
// //                       'Welcome Back',
// //                       style: TextStyle(
// //                         fontSize: 28,
// //                         fontWeight: FontWeight.bold,
// //                         color: Color(0xFF073850),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Text(
// //                       'Sign in to your account',
// //                       style: TextStyle(
// //                         fontSize: 16,
// //                         color: Colors.grey[600],
// //                       ),
// //                     ),
// //                     const SizedBox(height: 32),
// //                     TextFormField(
// //                       controller: _emailController,
// //                       keyboardType: TextInputType.emailAddress,
// //                       decoration: InputDecoration(
// //                         labelText: 'Email',
// //                         hintText: 'Enter your email',
// //                         prefixIcon: const Icon(Icons.email_outlined,
// //                             color: Color(0xFF073850)),
// //                         filled: true,
// //                         fillColor: Colors.grey[50],
// //                         border: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(12),
// //                           borderSide: BorderSide.none,
// //                         ),
// //                         focusedBorder: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(12),
// //                           borderSide: const BorderSide(
// //                             color: Color(0xFF073850),
// //                             width: 2,
// //                           ),
// //                         ),
// //                       ),
// //                       validator: (value) =>
// //                           value == null || value.isEmpty ? 'Enter email' : null,
// //                     ),
// //                     const SizedBox(height: 16),
// //                     TextFormField(
// //                       controller: _passwordController,
// //                       obscureText: _isObscure,
// //                       decoration: InputDecoration(
// //                         labelText: 'Password',
// //                         hintText: 'Enter your password',
// //                         prefixIcon: const Icon(Icons.lock_outline,
// //                             color: Color(0xFF073850)),
// //                         suffixIcon: IconButton(
// //                           icon: Icon(
// //                             _isObscure
// //                                 ? Icons.visibility_off
// //                                 : Icons.visibility,
// //                             color: const Color(0xFF073850),
// //                           ),
// //                           onPressed: () =>
// //                               setState(() => _isObscure = !_isObscure),
// //                         ),
// //                         filled: true,
// //                         fillColor: Colors.grey[50],
// //                         border: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(12),
// //                           borderSide: BorderSide.none,
// //                         ),
// //                         focusedBorder: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(12),
// //                           borderSide: const BorderSide(
// //                             color: Color(0xFF073850),
// //                             width: 2,
// //                           ),
// //                         ),
// //                       ),
// //                       validator: (value) => value == null || value.isEmpty
// //                           ? 'Enter password'
// //                           : null,
// //                     ),
// //                     const SizedBox(height: 32),
// //                     ScaleTransition(
// //                       scale: _buttonAnimation,
// //                       child: ElevatedButton(
// //                         onPressed: _isLoading ? null : _handleLogin,
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: const Color(0xFF073850),
// //                           foregroundColor: Colors.white,
// //                           minimumSize: const Size(double.infinity, 56),
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                           ),
// //                           elevation: 5,
// //                           shadowColor: Colors.grey.withOpacity(0.4),
// //                         ),
// //                         child: _isLoading
// //                             ? const SizedBox(
// //                                 width: 24,
// //                                 height: 24,
// //                                 child: CircularProgressIndicator(
// //                                   color: Colors.white,
// //                                   strokeWidth: 2,
// //                                 ),
// //                               )
// //                             : const Text(
// //                                 'Sign In',
// //                                 style: TextStyle(
// //                                   fontSize: 18,
// //                                   fontWeight: FontWeight.bold,
// //                                 ),
// //                               ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 16),
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         Text(
// //                           "Don't have an account? ",
// //                           style: TextStyle(
// //                             fontSize: 16,
// //                             color: Colors.grey[600],
// //                           ),
// //                         ),
// //                         GestureDetector(
// //                           onTap: () {
// //                             Navigator.pushNamed(context, '/register');
// //                           },
// //                           child: const Text(
// //                             'Sign Up',
// //                             style: TextStyle(
// //                               fontSize: 16,
// //                               fontWeight: FontWeight.bold,
// //                               color: Color(0xFF073850),
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'package:dw_attendance_app/models/employee.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '/services/api_service.dart';
// import '/services/employee_service.dart';
// import '/services/onesignal_service.dart';
// import 'home_page.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'dart:convert';
// import 'register_page.dart';

// void main() {
//   tz.initializeTimeZones();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   Future<Widget> _getInitialPage() async {
//     final prefs = await SharedPreferences.getInstance();
//     final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//     final sessionId = prefs.getString('sessionId');
//     final email = prefs.getString('email') ?? 'Unknown';
//     final employeeId = prefs.getString('employeeId') ?? 'N/A';
//     final address = prefs.getString('address') ?? 'N/A';
//     final mobile = prefs.getString('mobile') ?? 'N/A';
//     final numericId = prefs.getInt('numericId') ?? 0;
//     final employeeName = prefs.getString('employeeName') ?? email;
//     final groupsJson = prefs.getString('groups') ?? '[]';
//     final groups = List<String>.from(jsonDecode(groupsJson));

//     if (isLoggedIn && sessionId != null && sessionId.isNotEmpty) {
//       debugPrint('Using stored session data for user: $email, groups: $groups');
//       return HomePage(
//         name: employeeName,
//         employeeId: employeeId,
//         numericId: numericId,
//         groups: groups,
//         address: address,
//         mobile: mobile,
//         jobTitle: '',
//       );
//     } else {
//       debugPrint('No valid session found or cleared, redirecting to login');
//       await prefs.clear();
//       return const MyHomePage(title: 'Login');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Employee Attendance',
//       theme: ThemeData(
//         scaffoldBackgroundColor: const Color.fromARGB(255, 241, 246, 249),
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Color.fromARGB(255, 205, 214, 219),
//           iconTheme: IconThemeData(color: Colors.white),
//           titleTextStyle: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         colorScheme: const ColorScheme.light(
//           primary: Color.fromARGB(255, 207, 214, 217),
//         ),
//       ),
//       routes: {
//         '/login': (context) => const MyHomePage(title: 'Login'),
//         '/register': (context) => const RegisterPage(),
//         '/task_details': (context) => const TaskDetailsPage(),
//       },
//       home: FutureBuilder<Widget>(
//         future: _getInitialPage(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           } else if (snapshot.hasError) {
//             debugPrint('Error in _getInitialPage: ${snapshot.error}');
//             return const MyHomePage(title: 'Login');
//           } else {
//             return snapshot.data!;
//           }
//         },
//       ),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage>
//     with SingleTickerProviderStateMixin {
//   bool _isObscure = true;
//   bool _isLoading = false;
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final ApiService _apiService = ApiService();
//   final EmployeeService _employeeService = EmployeeService();
//   late AnimationController _animationController;
//   late Animation<double> _logoAnimation;
//   late Animation<double> _buttonAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     )..repeat(reverse: true);
//     _logoAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//     _buttonAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleLogin() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       final connectivityResult = await Connectivity().checkConnectivity();
//       if (!connectivityResult.contains(ConnectivityResult.mobile) &&
//           !connectivityResult.contains(ConnectivityResult.wifi)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           _buildSnackBar("You're Offline", Colors.red),
//         );
//         setState(() => _isLoading = false);
//         return;
//       }

//       final prefs = await SharedPreferences.getInstance();
//       final email = _emailController.text.trim().toLowerCase();
//       final password = _passwordController.text.trim();

//       final sessionData = await _apiService.authenticateUser(
//         email: email,
//         password: password,
//       );

//       // Fetch user groups if not included in auth response
//       List<String> groups = sessionData['groups'];
//       if (groups.isEmpty) {
//         groups = await _apiService.getUserGroups(
//           sessionId: sessionData['sessionId'],
//           userId: sessionData['user_id'].toString(),
//         );
//         if (groups.isEmpty) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             _buildSnackBar(
//                 'Warning: Could not fetch user permissions. Limited access granted.',
//                 Colors.orange),
//           );
//         }
//       }

//       // Initialize OneSignal
//       final oneSignalService = OneSignalService(context: context);
//       await oneSignalService.initOneSignal(sessionData['user_id'].toString());

//       // Get player_id from OneSignal and send to backend
//       try {
//         final status = await OneSignal.shared.getDeviceState();
//         final playerId = status?.userId;
//         if (playerId != null) {
//           await _apiService.savePlayerId(
//             playerId: playerId,
//             sessionId: sessionData['sessionId'],
//           );
//           await prefs.setString('player_id', playerId);
//         } else {
//           debugPrint('No valid player ID received from OneSignal');
//         }
//       } catch (e) {
//         debugPrint('Player ID save failed: $e');
//       }

//       // Fetch employee info
//       final employees = await _employeeService.getEmployees();
//       final employee = employees.firstWhere(
//         (e) => e.email.toLowerCase() == email.toLowerCase(),
//         orElse: () => Employee(
//           id: sessionData['user_id'],
//           name: sessionData['name'],
//           employeeId: 'N/A',
//           jobTitle: '',
//           dob: '',
//           address: 'N/A',
//           mobile: 'N/A',
//           email: email,
//           roleType: sessionData['role'] ?? '',
//           gender: '',
//         ),
//       );

//       // Save session data
//       await prefs.setString('email', email);
//       await prefs.setString('employeeId', employee.employeeId ?? 'N/A');
//       await prefs.setString('address', employee.address);
//       await prefs.setString('mobile', employee.mobile);
//       await prefs.setBool('isLoggedIn', true);
//       await prefs.setString('sessionId', sessionData['sessionId']);
//       await prefs.setInt('numericId', employee.id);
//       await prefs.setString('employeeName', employee.name);
//       await prefs.setString('device_id', sessionData['device_id']);
//       await prefs.setString('groups', jsonEncode(groups));

//       debugPrint('handleLogin: groups = $groups');

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         _buildSnackBar('Login Successful!', Colors.green),
//       );

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => HomePage(
//             name: employee.name,
//             numericId: employee.id,
//             employeeId: employee.employeeId ?? 'N/A',
//             groups: groups,
//             address: employee.address,
//             mobile: employee.mobile,
//             jobTitle: employee.jobTitle,
//           ),
//         ),
//       );
//     } catch (e) {
//       String errorMessage = _mapError(e.toString());
//       debugPrint('Login error: $errorMessage');
//       ScaffoldMessenger.of(context).showSnackBar(
//         _buildSnackBar(errorMessage, Colors.red),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   SnackBar _buildSnackBar(String message, Color color) {
//     return SnackBar(
//       behavior: SnackBarBehavior.floating,
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       duration: const Duration(seconds: 3),
//       content: Center(
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 13.0),
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             message,
//             textAlign: TextAlign.center,
//             style: const TextStyle(color: Colors.white),
//           ),
//         ),
//       ),
//     );
//   }

//   String _mapError(String error) {
//     if (error.contains('Device is already associated')) {
//       return 'This device is already associated with another account. Contact your administrator.';
//     } else if (error.contains('Account is locked to another device')) {
//       return 'Your account is locked to another device. Contact your administrator.';
//     } else if (error.contains('Invalid email or password') ||
//         error.toLowerCase().contains('access denied')) {
//       return 'Invalid email or password';
//     } else if (error.contains('SocketException') ||
//         error.contains('Connection refused') ||
//         error.contains('Network is unreachable')) {
//       return 'Unable to reach server';
//     }
//     return error.replaceFirst('Exception: ', '');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
//             child: Container(
//               constraints: const BoxConstraints(maxWidth: 400),
//               padding: const EdgeInsets.all(32.0),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.3),
//                     blurRadius: 15,
//                     offset: const Offset(0, 8),
//                   ),
//                 ],
//               ),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     ScaleTransition(
//                       scale: _logoAnimation,
//                       child: Image.asset(
//                         'assets/images/logo1.png',
//                         height: 120,
//                         fit: BoxFit.contain,
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                     const Text(
//                       'Welcome Back',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF073850),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Sign in to your account',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                     TextFormField(
//                       controller: _emailController,
//                       keyboardType: TextInputType.emailAddress,
//                       decoration: InputDecoration(
//                         labelText: 'Email',
//                         hintText: 'Enter your email',
//                         prefixIcon: const Icon(Icons.email_outlined,
//                             color: Color(0xFF073850)),
//                         filled: true,
//                         fillColor: Colors.grey[50],
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide.none,
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(
//                             color: Color(0xFF073850),
//                             width: 2,
//                           ),
//                         ),
//                       ),
//                       validator: (value) =>
//                           value == null || value.isEmpty ? 'Enter email' : null,
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _passwordController,
//                       obscureText: _isObscure,
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         hintText: 'Enter your password',
//                         prefixIcon: const Icon(Icons.lock_outline,
//                             color: Color(0xFF073850)),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _isObscure
//                                 ? Icons.visibility_off
//                                 : Icons.visibility,
//                             color: const Color(0xFF073850),
//                           ),
//                           onPressed: () =>
//                               setState(() => _isObscure = !_isObscure),
//                         ),
//                         filled: true,
//                         fillColor: Colors.grey[50],
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide.none,
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(
//                             color: Color(0xFF073850),
//                             width: 2,
//                           ),
//                         ),
//                       ),
//                       validator: (value) => value == null || value.isEmpty
//                           ? 'Enter password'
//                           : null,
//                     ),
//                     const SizedBox(height: 32),
//                     ScaleTransition(
//                       scale: _buttonAnimation,
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _handleLogin,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF073850),
//                           foregroundColor: Colors.white,
//                           minimumSize: const Size(double.infinity, 56),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 5,
//                           shadowColor: Colors.grey.withOpacity(0.4),
//                         ),
//                         child: _isLoading
//                             ? const SizedBox(
//                                 width: 24,
//                                 height: 24,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : const Text(
//                                 'Sign In',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           "Don't have an account? ",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             Navigator.pushNamed(context, '/register');
//                           },
//                           child: const Text(
//                             'Sign Up',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF073850),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class TaskDetailsPage extends StatelessWidget {
//   const TaskDetailsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final taskId = ModalRoute.of(context)?.settings.arguments as String?;
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Task Details'),
//       ),
//       body: Center(
//         child: Text('Task ID: ${taskId ?? "Unknown"}'),
//       ),
//     );
//   }
// }

import 'package:dw_attendance_app/models/employee.dart';
import 'package:dw_attendance_app/nointernet.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/api_service.dart';
import '/services/employee_service.dart';
import '/services/onesignal_service.dart';
import 'home_page.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:convert';
import 'register_page.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialPage() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final sessionId = prefs.getString('sessionId');
    final email = prefs.getString('email') ?? 'Unknown';
    final employeeId = prefs.getString('employeeId') ?? 'N/A';
    final address = prefs.getString('address') ?? 'N/A';
    final mobile = prefs.getString('mobile') ?? 'N/A';
    final numericId = prefs.getInt('numericId') ?? 0;
    final employeeName = prefs.getString('employeeName') ?? email;
    final groupsJson = prefs.getString('groups') ?? '[]';
    final groups = List<String>.from(jsonDecode(groupsJson));

    if (isLoggedIn && sessionId != null && sessionId.isNotEmpty) {
      debugPrint('Using stored session data for user: $email, groups: $groups');
      return HomePage(
        name: employeeName,
        employeeId: employeeId,
        numericId: numericId,
        groups: groups,
        address: address,
        mobile: mobile,
        jobTitle: '',
      );
    } else {
      debugPrint('No valid session found or cleared, redirecting to login');
      await prefs.clear();
      return const MyHomePage(title: 'Login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Employee Attendance',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 241, 246, 249),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 205, 214, 219),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: const ColorScheme.light(
          primary: Color.fromARGB(255, 207, 214, 217),
        ),
      ),
      routes: {
        '/login': (context) => const MyHomePage(title: 'Login'),
        '/register': (context) => const RegisterPage(),
        '/no_internet': (context) => const NoInternetPage(),
      },
      home: FutureBuilder<Widget>(
        future: _getInitialPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            debugPrint('Error in _getInitialPage: ${snapshot.error}');
            return const MyHomePage(title: 'Login');
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  bool _isObscure = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final EmployeeService _employeeService = EmployeeService();
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _logoAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.mobile) &&
          !connectivityResult.contains(ConnectivityResult.wifi)) {
        Navigator.pushNamed(context, '/no_internet');
        setState(() => _isLoading = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      final sessionData = await _apiService.authenticateUser(
        email: email,
        password: password,
      );

      List<String> groups = sessionData['groups'];
      if (groups.isEmpty) {
        groups = await _apiService.getUserGroups(
          sessionId: sessionData['sessionId'],
          userId: sessionData['user_id'].toString(),
        );
      }

      final oneSignalService = OneSignalService(context: context);
      await oneSignalService.initOneSignal(sessionData['user_id'].toString());

      try {
        final status = await OneSignal.shared.getDeviceState();
        final playerId = status?.userId;
        if (playerId != null) {
          await _apiService.savePlayerId(
            playerId: playerId,
            sessionId: sessionData['sessionId'],
          );
          await prefs.setString('player_id', playerId);
        }
      } catch (e) {
        debugPrint('Player ID save failed: $e');
      }

      final employees = await _employeeService.getEmployees();
      final employee = employees.firstWhere(
        (e) => e.email.toLowerCase() == email.toLowerCase(),
        orElse: () => Employee(
          id: sessionData['user_id'],
          name: sessionData['name'],
          employeeId: 'N/A',
          jobTitle: '',
          dob: '',
          address: 'N/A',
          mobile: 'N/A',
          email: email,
          roleType: sessionData['role'] ?? '',
          gender: '',
        ),
      );

      await prefs.setString('email', email);
      await prefs.setString('employeeId', employee.employeeId ?? 'N/A');
      await prefs.setString('address', employee.address);
      await prefs.setString('mobile', employee.mobile);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('sessionId', sessionData['sessionId']);
      await prefs.setInt('numericId', employee.id);
      await prefs.setString('employeeName', employee.name);
      await prefs.setString('device_id', sessionData['device_id']);
      await prefs.setString('groups', jsonEncode(groups));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          'Login Successful!',
          Color.fromARGB(255, 107, 186, 110),
          isError: false,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            name: employee.name,
            numericId: employee.id,
            employeeId: employee.employeeId ?? 'N/A',
            groups: groups,
            address: employee.address,
            mobile: employee.mobile,
            jobTitle: employee.jobTitle,
          ),
        ),
      );
    } catch (e) {
      String errorMessage = _mapError(e.toString());
      debugPrint('Login error: $errorMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(errorMessage, Colors.red, isError: true),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  SnackBar _buildSnackBar(String message, Color color, {bool isError = false}) {
    final contentType = isError ? ContentType.failure : ContentType.success;

    return SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color.fromARGB(0, 14, 13, 13),
      content: AwesomeSnackbarContent(
        title: isError ? 'Login Failed' : 'Success',
        message: message,
        contentType: contentType,
      ),
    );
  }

  String _mapError(String error) {
    if (error.contains('Internal Server Error')) {
      return 'Server Down';
    } else if (error.contains('Device is already associated')) {
      return 'This device is already associated with another account. Contact your administrator.';
    } else if (error.contains('Account is locked to another device')) {
      return 'Your account is locked to another device. Contact your administrator.';
    } else if (error.contains('Invalid email or password') ||
        error.toLowerCase().contains('access denied')) {
      return 'Invalid email or password';
    } else if (error.contains('SocketException') ||
        error.contains('Connection refused') ||
        error.contains('Network is unreachable')) {
      return 'Unable to reach server';
    }
    return error.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _logoAnimation,
                      child: Image.asset(
                        'assets/images/logo1.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 3, 4, 4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Color(0xFF073850)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF073850), width: 2),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF073850)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF073850),
                          ),
                          onPressed: () =>
                              setState(() => _isObscure = !_isObscure),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF073850), width: 2),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter password'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    ScaleTransition(
                      scale: _buttonAnimation,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 5, 5, 6),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.grey.withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 14, 17, 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
