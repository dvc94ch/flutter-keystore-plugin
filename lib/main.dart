import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter_keystore_plugin/flutter_keystore_plugin.dart';

void main() {
  // Override is necessary to prevent Unknown platform' flutter startup error.
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(FlutterKeystorePlugin()),
    );
  }
}

class HomePage extends StatelessWidget {

  final FlutterKeystorePlugin keystore;

  HomePage(this.keystore);

  Future<dynamic> load() async {
    final status = await keystore.status();
    if (status == Status.Uninitialized) {
      await keystore.generate('password');
    } else {
      try {
        await keystore.unlock('password');
      } catch(e) {}
    }
    final phrase = await keystore.phrase('password');
    final account = await keystore.account();
    return account as dynamic;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final account = snapshot.data as Account;
            print(account);
            return Column(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Texture(textureId: account.identicon),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Texture(textureId: account.qrcode),
                ),
                Text(account.ss58),
              ],
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
