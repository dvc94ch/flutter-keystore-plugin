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

class Account {
  final String name;
  final String ss58;
  final int identicon;
  final int qrcode;

  Account({
    @required this.name,
    @required this.ss58,
    @required this.identicon,
    @required this.qrcode,
  });

  String toString() {
    return '<KeyInfo> { name: $name, ss58: $ss58, identicon: $identicon, qrcode: $qrcode }';
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

  Future<bool> paperBackup() {
    return channel.invokeMethod('paper_backup');
  }

  Future<Null> setPaperBackup() {
    return channel.invokeMethod('set_paper_backup');
  }

  Future<String> phrase(String password) {
    final Map<String, dynamic> args = {
      "password": password,
    };
    return channel.invokeMethod('phrase', args);
  }

  Future<Account> account() async {
    final account = await channel.invokeMethod('account');
    return Account(
      name: account['name'],
      ss58: account['ss58'],
      identicon: account['identicon'],
      qrcode: account['qrcode'],
    );
  }
}
