import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PkcePair {
  const PkcePair({required this.codeVerifier, required this.codeChallenge});

  final String codeVerifier;
  final String codeChallenge;
}

class PkceUtil {
  static PkcePair generate() {
    final verifier = _randomCodeVerifier();
    final challenge = _toBase64UrlNoPadding(
      sha256.convert(ascii.encode(verifier)).bytes,
    );

    return PkcePair(codeVerifier: verifier, codeChallenge: challenge);
  }

  static String randomState() {
    return _toBase64UrlNoPadding(_randomBytes(24));
  }

  static String _randomCodeVerifier() {
    return _toBase64UrlNoPadding(_randomBytes(64));
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static String _toBase64UrlNoPadding(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
