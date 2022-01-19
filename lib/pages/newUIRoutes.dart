import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/homaPage.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/mintPage.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/redeemPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

Map<String, WidgetBuilder> getNewUiRoutes(
    PluginKarura plugin, Keyring keyring) {
  /// use new pages in testnet for now.
  final isTest = true;
  return isTest
      ? {
          //homa
          HomaPage.route: (_) => HomaPage(plugin, keyring),
          MintPage.route: (_) => MintPage(plugin, keyring),
          RedeemPage.route: (_) => RedeemPage(plugin, keyring),

          //loan
          LoanPage.route: (_) => LoanPage(plugin, keyring),
        }
      : {};
}
