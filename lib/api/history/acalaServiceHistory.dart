import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';

class AcalaServiceHistory {
  AcalaServiceHistory(this.plugin);

  final PluginKarura plugin;

  Future<List?> queryHistory(
      String type, String? address, Map<String, dynamic> params) async {
    final List? list = await plugin.sdk.webView!.evalJavascript(
        'acala.getHistory(api,"$type","$address",${jsonEncode(params)})');
    return list;
  }
}
