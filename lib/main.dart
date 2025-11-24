import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ importa as localizações
import 'cadastro_e_login/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AwesomeNotifications().initialize(
    'resource://mipmap/ic_launcher',
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Notificações Básicas',
        channelDescription: 'Canal de notificação para testes básicos',
        defaultColor: Colors.redAccent,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        vibrationPattern: Int64List.fromList([500, 1000, 500, 1000]),
        playSound: true,
      )
    ],
    debug: true,
  );

  runApp(const MyApp());
}

// ✅ classe de opções do Firebase (substitua pela gerada pelo FlutterFire)
class DefaultFirebaseOptions {
  static var currentPlatform;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saúde+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),

      // ✅ Adiciona suporte de idioma e localização do Material
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Português Brasil
        Locale('en', 'US'), // Inglês (opcional)
      ],
    );
  }
}

