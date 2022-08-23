import 'package:polkawallet_plugin_karura/store/accounts.dart';
import 'package:polkawallet_plugin_karura/store/assets.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';
import 'package:polkawallet_plugin_karura/store/earn.dart';
import 'package:polkawallet_plugin_karura/store/gov/governance.dart';
import 'package:polkawallet_plugin_karura/store/historys.dart';
import 'package:polkawallet_plugin_karura/store/homa.dart';
import 'package:polkawallet_plugin_karura/store/loan.dart';
import 'package:polkawallet_plugin_karura/store/setting.dart';
import 'package:polkawallet_plugin_karura/store/swap.dart';

class PluginStore {
  PluginStore(StoreCache? cache)
      : setting = SettingStore(cache),
        gov = GovernanceStore(cache),
        assets = AssetsStore(cache),
        loan = LoanStore(cache),
        earn = EarnStore(cache),
        swap = SwapStore(cache),
        homa = HomaStore(cache),
        history = HistoryStore(cache),
        accounts = AccountsStore(cache);

  final AccountsStore accounts;

  final SettingStore setting;
  final AssetsStore assets;
  final LoanStore loan;
  final EarnStore earn;
  final HomaStore homa;
  final GovernanceStore gov;
  final SwapStore swap;
  final HistoryStore history;
}
