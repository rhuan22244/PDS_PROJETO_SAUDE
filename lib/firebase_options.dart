import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  // Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAZFPvD9v3JTUQ3V7ixA8BuDWkSMrntEb0',
    authDomain: 'meu-projeto-da2fe.firebaseapp.com',
    projectId: 'meu-projeto-da2fe',
    storageBucket: 'meu-projeto-da2fe.appspot.com',
    messagingSenderId: '255104020271',
    appId: '1:255104020271:web:COLOQUE_SEU_APP_ID_WEB_AQUI',
  );

  // Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZFPvD9v3JTUQ3V7ixA8BuDWkSMrntEb0',
    appId: '1:255104020271:android:702353f4f0f7402270bbda',
    messagingSenderId: '255104020271',
    projectId: 'meu-projeto-da2fe',
    storageBucket: 'meu-projeto-da2fe.appspot.com',
  );

  // iOS (precisa pegar o App ID real)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAZFPvD9v3JTUQ3V7ixA8BuDWkSMrntEb0',
    appId: 'COLOQUE_SEU_APP_ID_IOS_AQUI',
    messagingSenderId: '255104020271',
    projectId: 'meu-projeto-da2fe',
    storageBucket: 'meu-projeto-da2fe.appspot.com',
    iosBundleId: 'com.example.projeto_final',
    iosClientId: 'COLOQUE_SEU_CLIENT_ID_IOS_AQUI',
  );

  // MacOS, Windows, Linux podem usar os mesmos dados do Android temporariamente
  static const FirebaseOptions macos = android;
  static const FirebaseOptions windows = android;
  static const FirebaseOptions linux = android;
}


