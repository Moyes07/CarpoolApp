// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCJCTVkqt728gUZRvaAwVZ_NJCeXx2ZgBM',
    appId: '1:335186189685:web:063fe531261b79b9cd873c',
    messagingSenderId: '335186189685',
    projectId: 'carpollappfyp',
    authDomain: 'carpollappfyp.firebaseapp.com',
    storageBucket: 'carpollappfyp.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD1rOFWo6stMPXafJOQGro_uiCgnD6TEEE',
    appId: '1:335186189685:android:6d9f977c6d3cbef5cd873c',
    messagingSenderId: '335186189685',
    projectId: 'carpollappfyp',
    storageBucket: 'carpollappfyp.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB7D3gCYjRoZ6i4FcidTE-N-Ytc_NKluKA',
    appId: '1:335186189685:ios:c9a5a26bba72fe47cd873c',
    messagingSenderId: '335186189685',
    projectId: 'carpollappfyp',
    storageBucket: 'carpollappfyp.appspot.com',
    iosBundleId: 'com.example.carpoolFypApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB7D3gCYjRoZ6i4FcidTE-N-Ytc_NKluKA',
    appId: '1:335186189685:ios:c9a5a26bba72fe47cd873c',
    messagingSenderId: '335186189685',
    projectId: 'carpollappfyp',
    storageBucket: 'carpollappfyp.appspot.com',
    iosBundleId: 'com.example.carpoolFypApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCJCTVkqt728gUZRvaAwVZ_NJCeXx2ZgBM',
    appId: '1:335186189685:web:97a0ef9b904c609fcd873c',
    messagingSenderId: '335186189685',
    projectId: 'carpollappfyp',
    authDomain: 'carpollappfyp.firebaseapp.com',
    storageBucket: 'carpollappfyp.appspot.com',
  );
}
