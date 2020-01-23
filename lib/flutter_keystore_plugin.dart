library flutter_keystore_plugin;

import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:flutter/services.dart';

enum KeystoreStatus {
  Empty,
  KeyFile
}

class KeyInfo {
  final String ss58;
  final int blocky;
  final int qr;

  KeyInfo({@required this.ss58, @required this.blocky, @required this.qr});

  String toString() {
    return '<KeyInfo> { ss58: $ss58, blocky: $blocky, qr: $qr }';
  }
}

class FlutterKeystorePlugin {
  MethodChannel channel = MethodChannel('rust/keystore');

  Future<KeystoreStatus> status() async {
    final int status = await channel.invokeMethod('status');
    if (status == 0) {
      return KeystoreStatus.Empty;
    }
    if (status > 1) {
      throw "Unknown status code";
    }
    return KeystoreStatus.KeyFile;
  }

  Future<Null> generate(String password) {
    final Map<String, dynamic> args = {
      password: password,
    };
    return channel.invokeMethod('generate', args);
  }

  Future<Null> import(String phrase, String password) {
    final Map<String, dynamic> args = {
      phrase: phrase,
      password: password,
    };
    return channel.invokeMethod('import', args);
  }

  Future<Null> load(String password) {
    final Map<String, dynamic> args = {
      password: password,
    };
    return channel.invokeMethod('load', args);
  }

  Future<String> phrase(String password) {
    final Map<String, dynamic> args = {
      password: password,
    };
    return channel.invokeMethod('phrase', args);
  }

  Future<KeyInfo> info() async {
    final info = await channel.invokeMethod('info');
    return KeyInfo(
      ss58: info['ss58'],
      blocky: info['blocky'],
      qr: info['qr'],
    );
  }
}
