import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not configured.');
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:           'AIzaSyCtAPp9Utq0pmLMRm72JqfKNthUmS7AcZ8',
    appId:            '1:299423691247:ios:96865d164fe6a8a481c61a',
    messagingSenderId: '299423691247',
    projectId:        'projects-696e9',
    storageBucket:    'projects-696e9.firebasestorage.app',
    iosBundleId:      'jp.kyogen.kyogen',
  );
}
