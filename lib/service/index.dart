import 'package:flutter/cupertino.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/service/serviceAssets.dart';
import 'package:polkawallet_plugin_karura/service/serviceEarn.dart';
import 'package:polkawallet_plugin_karura/service/serviceGov.dart';
import 'package:polkawallet_plugin_karura/service/serviceHoma.dart';
import 'package:polkawallet_plugin_karura/service/serviceLoan.dart';
import 'package:polkawallet_plugin_karura/service/walletApi.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/passwordInputDialog.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class PluginService {
  PluginService(PluginKarura plugin, Keyring keyring)
      : assets = ServiceAssets(plugin, keyring),
        loan = ServiceLoan(plugin, keyring),
        earn = ServiceEarn(plugin, keyring),
        homa = ServiceHoma(plugin, keyring),
        gov = ServiceGov(plugin, keyring),
        plugin = plugin;
  final ServiceAssets assets;
  final ServiceLoan loan;
  final ServiceEarn earn;
  final ServiceHoma homa;
  final ServiceGov gov;

  final PluginKarura plugin;

  bool connected = false;

  Future<String?> getPassword(BuildContext context, KeyPairData acc) async {
    final password = await showCupertinoDialog(
      context: context,
      builder: (_) {
        return PasswordInputDialog(
          plugin.sdk.api,
          title: Text(
              I18n.of(context)!.getDic(i18n_full_dic_ui, 'common')!['unlock']!),
          account: acc,
        );
      },
    );
    return password;
  }

  Future<void> fetchRemoteConfig() async {
    final res = await WalletApi.getRemoteConfig();
    if (res != null) {
      plugin.store!.setting.setRemoteConfig(res);
    }
  }
}
