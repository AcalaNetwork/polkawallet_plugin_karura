library polkawallet_plugin_karura;

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/api/acalaService.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/common/constants/nodeList.dart';
import 'package:polkawallet_plugin_karura/pages/acalaEntry.dart';
import 'package:polkawallet_plugin_karura/pages/assets/tokenDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/assets/transferDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/assets/transferPage.dart';
import 'package:polkawallet_plugin_karura/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/LPStakePage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/addLiquidityPage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnPage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/earnTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/liquidityDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/earn/withdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_karura/pages/gov/democracy/proposalDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/gov/democracy/referendumVotePage.dart';
import 'package:polkawallet_plugin_karura/pages/gov/democracyPage.dart';
import 'package:polkawallet_plugin_karura/pages/homa/homaHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/homa/homaPage.dart';
import 'package:polkawallet_plugin_karura/pages/homa/homaTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/homa/mintPage.dart';
import 'package:polkawallet_plugin_karura/pages/homa/redeemPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanAdjustPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanCreatePage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanDepositPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_karura/pages/loan/loanTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/nft/nftBurnPage.dart';
import 'package:polkawallet_plugin_karura/pages/nft/nftDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/nft/nftPage.dart';
import 'package:polkawallet_plugin_karura/pages/nft/nftTransferPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapPage.dart';
import 'package:polkawallet_plugin_karura/service/graphql.dart';
import 'package:polkawallet_plugin_karura/service/index.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';

class PluginKarura extends PolkawalletPlugin {
  PluginKarura({String name = plugin_name_karura})
      : basic = PluginBasicData(
          name: name,
          genesisHash: plugin_genesis_hash,
          ss58: ss58_prefix_karura,
          primaryColor: Colors.red,
          gradientColor: Color.fromARGB(255, 255, 76, 59),
          backgroundImage: AssetImage(
              'packages/polkawallet_plugin_karura/assets/images/bg.png'),
          icon: name == plugin_name_karura
              ? Image.asset(
                  'packages/polkawallet_plugin_karura/assets/images/tokens/KAR.png')
              : SvgPicture.asset(
                  'packages/polkawallet_plugin_karura/assets/images/logo.svg'),
          iconDisabled: name == plugin_name_karura
              ? Image.asset(
                  'packages/polkawallet_plugin_karura/assets/images/logo_kar_gray.png')
              : SvgPicture.asset(
                  'packages/polkawallet_plugin_karura/assets/images/logo.svg',
                  color: Color(0xFF9E9E9E),
                  width: 24,
                ),
          isTestNet: name != plugin_name_karura,
          isXCMSupport: name == plugin_name_karura,
          parachainId: '2000',
          jsCodeVersion: 23301,
        );

  @override
  final PluginBasicData basic;

  @override
  List<NetworkParams> get nodeList {
    return _randomList(node_list)
        .map((e) => NetworkParams.fromJson(e))
        .toList();
  }

  Map<String, Widget> _getTokenIcons() {
    final Map<String, Widget> all = {};
    acala_token_ids.forEach((token) {
      all[token] = Image.asset(
          'packages/polkawallet_plugin_karura/assets/images/tokens/$token.png');
    });
    return all;
  }

  @override
  Map<String, Widget> get tokenIcons => _getTokenIcons();

  @override
  List<TokenBalanceData> get noneNativeTokensAll {
    return store?.assets?.tokenBalanceMap?.values?.toList();
  }

  @override
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) {
    return [
      HomeNavItem(
        text: 'Karura',
        icon: SvgPicture.asset(
            'packages/polkawallet_plugin_karura/assets/images/logo_kar_empty.svg',
            color: Theme.of(context).disabledColor),
        iconActive: Image.asset(
            'packages/polkawallet_plugin_karura/assets/images/tokens/KAR.png'),
        content: AcalaEntry(this, keyring),
      )
    ];
  }

  @override
  Map<String, WidgetBuilder> getRoutes(Keyring keyring) {
    return {
      TxConfirmPage.route: (_) =>
          TxConfirmPage(this, keyring, _service.getPassword),
      CurrencySelectPage.route: (_) => CurrencySelectPage(this),
      AccountQrCodePage.route: (_) => AccountQrCodePage(this, keyring),

      TokenDetailPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => TokenDetailPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri'],
          ),
      TransferPage.route: (_) => TransferPage(this, keyring),
      TransferDetailPage.route: (_) => TransferDetailPage(this, keyring),

      // loan pages
      LoanPage.route: (_) => LoanPage(this, keyring),
      LoanDetailPage.route: (_) => LoanDetailPage(this, keyring),
      LoanTxDetailPage.route: (_) => LoanTxDetailPage(this, keyring),
      LoanCreatePage.route: (_) => LoanCreatePage(this, keyring),
      LoanAdjustPage.route: (_) => LoanAdjustPage(this, keyring),
      LoanDepositPage.route: (_) => LoanDepositPage(this, keyring),
      LoanHistoryPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => LoanHistoryPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri'],
          ),
      // swap pages
      SwapPage.route: (_) => SwapPage(this, keyring),
      SwapHistoryPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => SwapHistoryPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri'],
          ),
      SwapDetailPage.route: (_) => SwapDetailPage(this, keyring),
      BootstrapPage.route: (_) => BootstrapPage(this, keyring),
      // earn pages
      EarnPage.route: (_) => EarnPage(this, keyring),
      EarnDetailPage.route: (_) => EarnDetailPage(this, keyring),
      EarnHistoryPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => EarnHistoryPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri'],
          ),
      EarnLiquidityDetailPage.route: (_) =>
          EarnLiquidityDetailPage(this, keyring),
      EarnTxDetailPage.route: (_) => EarnTxDetailPage(this, keyring),
      LPStakePage.route: (_) => LPStakePage(this, keyring),
      AddLiquidityPage.route: (_) => AddLiquidityPage(this, keyring),
      WithdrawLiquidityPage.route: (_) => WithdrawLiquidityPage(this, keyring),
      // homa pages
      HomaPage.route: (_) => HomaPage(this, keyring),
      MintPage.route: (_) => MintPage(this, keyring),
      RedeemPage.route: (_) => RedeemPage(this, keyring),
      HomaHistoryPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => HomaHistoryPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri'],
          ),
      HomaTxDetailPage.route: (_) => HomaTxDetailPage(this, keyring),
      // NFT pages
      NFTPage.route: (_) => NFTPage(this, keyring),
      NFTDetailPage.route: (_) => NFTDetailPage(this, keyring),
      NFTTransferPage.route: (_) => NFTTransferPage(this, keyring),
      NFTBurnPage.route: (_) => NFTBurnPage(this, keyring),
      // Gov pages
      DemocracyPage.route: (_) => DemocracyPage(this, keyring),
      ReferendumVotePage.route: (_) => ReferendumVotePage(this, keyring),
      ProposalDetailPage.route: (_) => ProposalDetailPage(this, keyring),
    };
  }

  @override
  Future<String> loadJSCode() => rootBundle.loadString(
      'packages/polkawallet_plugin_karura/lib/js_service_karura/dist/main.js');

  AcalaApi _api;
  AcalaApi get api => _api;

  StoreCache _cache;
  PluginStore _store;
  PluginService _service;
  PluginStore get store => _store;
  PluginService get service => _service;

  Future<void> _subscribeTokenBalances(KeyPairData acc) async {
    // todo: fix this after new acala online
    final enabled = basic.name == 'acala'
        ? _store.setting.liveModules['assets']['enabled']
        : true;

    _api.assets.subscribeTokenBalances(basic.name, acc.address, (data) {
      _store.assets.setTokenBalanceMap(data, acc.pubKey);

      balances.setTokens(data);
    }, transferEnabled: enabled);

    final nft = await _api.assets.queryNFTs(acc.address);
    if (nft != null) {
      _store.assets.setNFTs(nft);
    }
  }

  void _loadCacheData(KeyPairData acc) {
    balances.setExtraTokens([]);
    _store.assets.setNFTs([]);

    try {
      loadBalances(acc);

      _store.assets.loadCache(acc.pubKey);
      final tokens = _store.assets.tokenBalanceMap.values.toList();
      if (service.plugin.store.setting.tokensConfig['invisible'] != null) {
        final invisible =
            List.of(service.plugin.store.setting.tokensConfig['invisible']);
        if (invisible.length > 0) {
          tokens.removeWhere((token) => invisible.contains(token.id));
        }
      }
      balances.setTokens(tokens, isFromCache: true);

      _store.loan.loadCache(acc.pubKey);
      _store.swap.loadCache(acc.pubKey);
      print('acala plugin cache data loaded');
    } catch (err) {
      print(err);
      print('load acala cache data failed');
    }
  }

  @override
  Future<void> onWillStart(Keyring keyring) async {
    _api = AcalaApi(AcalaService(this));

    await GetStorage.init(plugin_cache_key);

    _cache = StoreCache();
    _store = PluginStore(_cache);
    _service = PluginService(this, keyring);

    _loadCacheData(keyring.current);

    _service.fetchLiveModules();

    // wait tokens config here for subscribe all tokens balances
    await _service.fetchTokensConfig();
  }

  @override
  Future<void> onStarted(Keyring keyring) async {
    _service.connected = true;

    if (keyring.current.address != null) {
      _subscribeTokenBalances(keyring.current);
    }
  }

  @override
  Future<void> onAccountChanged(KeyPairData acc) async {
    _loadCacheData(acc);

    if (_service.connected) {
      _api.assets.unsubscribeTokenBalances(basic.name, acc.address);
      _subscribeTokenBalances(acc);
    }
  }

  List _randomList(List input) {
    final data = input.toList();
    final res = [];
    final _random = Random();
    for (var i = 0; i < input.length; i++) {
      final item = data[_random.nextInt(data.length)];
      res.add(item);
      data.remove(item);
    }
    return res;
  }
}
