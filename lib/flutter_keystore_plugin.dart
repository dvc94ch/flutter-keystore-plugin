library flutter_keystore_plugin;

import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:flutter/services.dart';

enum Status {
  Uninitialized,
  Locked,
  Unlocked,
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

  Future<Status> status() async {
    final int status = await channel.invokeMethod('status');
    if (status == 0) {
      return Status.Uninitialized;
    }
    if (status == 1) {
      return Status.Locked;
    }
    if (status == 2) {
      return Status.Unlocked;
    }
    throw "Unknown status code";
  }

  Future<Null> generate(String password) {
    final Map<String, dynamic> args = {
      "password": password,
    };
    return channel.invokeMethod('generate', args);
  }

  Future<Null> import(String phrase, String password) {
    final Map<String, dynamic> args = {
      "phrase": phrase,
      "password": password,
    };
    return channel.invokeMethod('import', args);
  }

  Future<Null> unlock(String password) {
    final Map<String, dynamic> args = {
      "password": password,
    };
    return channel.invokeMethod('unlock', args);
  }

  Future<Null> lock() {
    return channel.invokeMethod('lock');
  }

  Future<String> phrase(String password) {
    final Map<String, dynamic> args = {
      "password": password,
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
