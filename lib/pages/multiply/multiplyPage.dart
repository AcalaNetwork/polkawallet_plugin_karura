import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';

class MultiplyPage extends StatefulWidget {
  MultiplyPage(this.plugin, this.keyring, {Key? key}) : super(key: key);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/multiply';

  @override
  State<MultiplyPage> createState() => _MultiplyPageState();
}

class _MultiplyPageState extends State<MultiplyPage> {
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text(dic!['multiply.title']!),
        ),
        body: Container());
  }
}
