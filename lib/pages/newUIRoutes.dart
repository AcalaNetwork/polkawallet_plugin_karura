import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/homaPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

Map<String, WidgetBuilder> getNewUiRoutes(
    PluginKarura plugin, Keyring keyring) {
  return {
    HomaPage.route: (_) => HomaPage(plugin, keyring),
    LoanPage.route: (_) => LoanPage(plugin, keyring),
  };
}
