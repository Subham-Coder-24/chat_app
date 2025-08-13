// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'blocs/auth/auth_bloc.dart';
// import 'blocs/auth/auth_event.dart';
// import 'blocs/auth/auth_state.dart';
// import 'blocs/users/users_bloc.dart';
// import 'views/auth/login_screen.dart';
// import 'views/home/home_screen.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider(
//           create: (context) => AuthBloc()..add(AuthStarted()),
//         ),
//         BlocProvider(
//           create: (context) => UsersBloc(),
//         ),
//       ],
//       child: MaterialApp(
//         title: 'Real-Time Chat',
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
//           useMaterial3: true,
//         ),
//         home: BlocBuilder<AuthBloc, AuthState>(
//           builder: (context, state) {
//             switch (state.status) {
//               case AuthStatus.authenticated:
//                 return const HomeScreen();
//               case AuthStatus.unauthenticated:
//                 return const LoginScreen();
//               case AuthStatus.unknown:
//               default:
//                 return const Scaffold(
//                   body: Center(
//                     child: CircularProgressIndicator(),
//                   ),
//                 );
//             }
//           },
//         ),
//         debugShowCheckedModeBanner: false,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/users/users_bloc.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(AuthStarted()),
        ),
        BlocProvider(
          create: (context) => UsersBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Real-Time Chat',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            switch (state.status) {
              case AuthStatus.authenticated:
                // Provide UsersBloc specifically for HomeScreen
                return BlocProvider(
                  create: (context) => UsersBloc(),
                  child: const HomeScreen(),
                );
              case AuthStatus.unauthenticated:
                return const LoginScreen();
              case AuthStatus.unknown:
              default:
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
            }
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}