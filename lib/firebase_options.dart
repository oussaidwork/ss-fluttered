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
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAMPx-kaKzBr2hhDbFUXeNlsDpnGiRaMeE',
    appId: '1:488576150560:web:b2d0c031eea5f121afa045',
    messagingSenderId: '488576150560',
    projectId: 'gen-lang-client-0557342357',
    authDomain: 'gen-lang-client-0557342357.firebaseapp.com',
    databaseURL: 'https://gen-lang-client-0557342357-default-rtdb.firebaseio.com',
    storageBucket: 'gen-lang-client-0557342357.firebasestorage.app',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'ss-ragraga',
    storageBucket: 'ss-ragraga.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'ss-ragraga',
    storageBucket: 'ss-ragraga.appspot.com',
    iosBundleId: 'com.example.ssFluttered',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:000000000000:macos:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'ss-ragraga',
    storageBucket: 'ss-ragraga.appspot.com',
    iosBundleId: 'com.example.ssFluttered',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'ss-ragraga',
    storageBucket: 'ss-ragraga.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'ss-ragraga',
    storageBucket: 'ss-ragraga.appspot.com',
  );
}
