// // example.dart

// import 'package:df_router/df_router.dart'; // Ensure this matches your package structure
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// // 1. Define Your RouteStates
// final class HomeRouteState extends RouteState<String> {
//   HomeRouteState() : super.parse('/home');
// }

// final class ProfileRouteState extends RouteState<int> {
//   ProfileRouteState() : super.parse('/profile');
// }

// // 2. Configure RouteStateManager in your MyApp widget
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'df_router Minimal Example',
//       debugShowCheckedModeBanner: false,
//       // The builder for MaterialApp.
//       // The `child` parameter here is MaterialApp's Navigator,
//       // but df_router manages its own screen stack.
//       builder: (context, child) {
//         return Material(
//           // Provides basic Material theming (optional, but good practice)
//           child: RouteManager(
//             fallbackRouteState: () => HomeRouteState(),
//             // Optional: initialState: HomeRouteState(),

//             // Wrapper for persistent UI (e.g., Scaffold with AppBar)
//             wrapper: (context, child) {
//               // screenContent is the current route's widget
//               final controller = RouteController.of(context);
//               return Material(
//                 child: Column(
//                   children: [
//                     Expanded(child: child),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         FilledButton(
//                           child: const Text('Go to Home'),
//                           onPressed: () {
//                             controller.push(
//                               HomeRouteState().copyWith(
//                                 queryParameters: {'from': 'Go to Home'},
//                                 extra: '<pass extra data here>',
//                               ),
//                             );
//                           },
//                         ),
//                         FilledButton(
//                           child: const Text('Go to Profile'),
//                           onPressed: () {
//                             controller.push(
//                               ProfileRouteState().copyWith(
//                                 queryParameters: {'from': 'Go to Profile'},
//                                 extra: 12345, // Example of passing extra data
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               );
//             },

//             // Define custom transitions (or use the default)
//             transitionBuilder: (context, params) {
//               return HorizontalSlideFadeTransition(
//                 // Or VerticalSlideFadeTransition
//                 prev: params.prevSnapshot,
//                 controller: params.controller,
//                 child: params.child,
//               );
//             },

//             // List of all available routes
//             builders: [
//               RouteBuilder<String>(
//                 routeState: HomeRouteState(),
//                 condition: () {
//                   // Check if the user is logged in or any other condition
//                   return true;
//                 },
//                 shouldPrebuild: true, // Prebuild this route for better performance
//                 shouldPreserve: true, // Preserve this route in the widget cache
//                 builder: (context, state) => HomeScreen(routeState: state),
//               ),
//               RouteBuilder<int>(
//                 routeState: ProfileRouteState(),
//                 condition: () {
//                   // Check if the user is logged in or any other condition
//                   return true;
//                 },
//                 builder: (context, state) => ProfileScreen(routeState: state),
//               ),
//               // Example with typed extra data:
//               // RouteBuilder<String>(
//               //   state: DetailRouteState(), // Or RouteState<String>.parse('/detail')
//               //   builder: (context, prev, state) => DetailScreen(state: state),
//               // ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// // 3. Create Your Screen Widgets

// class HomeScreen extends StatefulWidget with RouteWidgetMixin<String> {
//   @override
//   final RouteState<String?> routeState;

//   const HomeScreen({super.key, required this.routeState});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   void initState() {
//     debugPrint('INIT HomeScreen!!!');
//     super.initState();
//   }

//   @override
//   void dispose() {
//     debugPrint('DISPOSING HomeScreen!!!');
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     debugPrint('BUILDING HomeScreen!!!');
//     final controller = RouteController.of(context);
//     return Container(
//       color: Colors.amber[100],
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Home Screen', style: Theme.of(context).textTheme.headlineMedium),
//             const SizedBox(height: 8),
//             Text('Current Path: ${widget.routeState.path}'),
//             const SizedBox(height: 8),
//             Text('Query Parameters: ${widget.routeState.uri.queryParameters}'),
//             const SizedBox(height: 8),
//             Text('Extra: ${widget.routeState.extra}'),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => controller.push(ProfileRouteState().copyWith(shouldAnimate: true)),
//               child: const Text('Go to Profile'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ProfileScreen extends StatefulWidget with RouteWidgetMixin<int> {
//   @override
//   final RouteState<int?>? routeState;

//   const ProfileScreen({super.key, this.routeState});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   @override
//   void initState() {
//     debugPrint('INIT ProfileScreen!!!');
//     super.initState();
//   }

//   @override
//   void dispose() {
//     debugPrint('DISPOSING ProfileScreen!!!');
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     debugPrint('BUILDING ProfileScreen!!!');
//     final controller = RouteController.of(context);
//     return Container(
//       color: Colors.cyan[100],
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Profile Screen', style: Theme.of(context).textTheme.headlineMedium),
//             const SizedBox(height: 8),
//             Text('Current Path: ${widget.routeState?.path}'),
//             const SizedBox(height: 8),
//             Text('Query Parameters: ${widget.routeState?.uri.queryParameters}'),
//             const SizedBox(height: 8),
//             Text('Extra: ${widget.routeState?.extra}'),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => controller.push(HomeRouteState().copyWith(shouldAnimate: true)),
//               child: const Text('Go to Home'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
