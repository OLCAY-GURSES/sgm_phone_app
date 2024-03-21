import 'package:flutter/material.dart';
import 'doctor-dashboard.dart';
import 'login.dart';
import 'package:flutter_localizations/flutter_localizations.dart';



void main() {
  runApp(MyApp());
}

class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({required WidgetBuilder builder, RouteSettings? settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mon application',

      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],


      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/doctor-dashboard': (context) => PatientListPage(),



      },
      builder: (context, child) {
        return Navigator(
          observers: [
            HeroController(),
          ],
          onGenerateRoute: (settings) {
            return NoAnimationMaterialPageRoute(
              builder: (context) => child!,
              settings: settings,
            );
          },
        );

      },
    );
  }
}