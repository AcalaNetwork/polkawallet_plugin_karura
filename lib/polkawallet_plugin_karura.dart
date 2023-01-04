library polkawallet_plugin_karura;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_karura/api/acalaApi.dart';
import 'package:polkawallet_plugin_karura/api/acalaService.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/common/constants/nodeList.dart';
import 'package:polkawallet_plugin_karura/pages/acalaEntry.dart';
import 'package:polkawallet_plugin_karura/pages/assets/nativeTokenTransfers.dart';
import 'package:polkawallet_plugin_karura/pages/assets/tokenDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/assets/transferDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/assets/transferPage.dart';
import 'package:polkawallet_plugin_karura/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_karura/pages/governanceNew/governancePage.dart';
import 'package:polkawallet_plugin_karura/pages/multiply/multiplyCreatePage.dart';
import 'package:polkawallet_plugin_karura/pages/multiply/multiplyPage.dart';
import 'package:polkawallet_plugin_karura/pages/newUIRoutes.dart';
import 'package:polkawallet_plugin_karura/pages/nftNew/nftPage.dart';
import 'package:polkawallet_plugin_karura/service/index.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';
import 'package:polkawallet_plugin_karura/store/index.dart';
import 'package:polkawallet_plugin_karura/utils/InstrumentItemWidget.dart';
import 'package:polkawallet_plugin_karura/utils/InstrumentWidget.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_plugin_karura/utils/types/aggregatedAssetsData.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/pages/v3/xcmTxConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

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
          jsCodeVersion: 33803,
        );

  @override
  final PluginBasicData basic;

  @override
  List<NetworkParams> get nodeList {
    return node_list.map((e) => NetworkParams.fromJson(e)).toList();
  }

  Map<String, Widget> _getTokenIcons() {
    final Map<String, Widget> all = {};
    // store?.assets.allTokens.map((e) => e.symbol).forEach((symbol) {
    //   all[symbol!] = Image.network(
    //       'https://cdn.subdao.com/tokens/${symbol}_128_128.png');
    // });
    acala_token_ids.forEach((token) {
      all[token] = Image.asset(
          'packages/polkawallet_plugin_karura/assets/images/tokens/$token.png');
    });
    return all;
  }

  @override
  Map<String, Widget> tokenIcons = {};

  @override
  List<String> get defaultTokens {
    return List<String>.from(
        (store?.setting.remoteConfig['tokens'] ?? {})['default'] ??
            default_tokens);
  }

  @override
  List<TokenBalanceData> get noneNativeTokensAll {
    return store?.assets.tokenBalanceMap.values.toList() ?? [];
  }

  @override
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common')!;
    return [
      HomeNavItem(
        text: "Defi",
        icon: Container(),
        iconActive: Container(),
        isAdapter: true,
        content: DefiWidget(this),
      ),
      HomeNavItem(
        text: "NFT",
        icon: Container(),
        iconActive: Container(),
        // isAdapter: true,
        // content: NFTWidget(this),
        content: Container(),
        onTap: () => Navigator.of(context).pushNamed(NftPage.route),
      ),
      HomeNavItem(
        text: dic['governance']!,
        icon: Container(),
        iconActive: Container(),
        // isAdapter: true,
        // content: GovernanceWidget(this),
        content: Container(),
        onTap: () => Navigator.of(context).pushNamed(GovernancePage.route),
      )
    ];
  }

  @override
  Widget? getAggregatedAssetsWidget(
      {String priceCurrency = 'USD',
      bool hideBalance = false,
      double rate = 1.0,
      @required Function? onSwitchBack,
      @required Function? onSwitchHideBalance}) {
    if (store == null) return null;

    return Observer(builder: (context) {
      if (store!.assets.aggregatedAssets!.keys.length == 0)
        return InstrumentWidget(
          [InstrumentData(0, []), InstrumentData(0, []), InstrumentData(0, [])],
          onSwitchBack,
          onSwitchHideBalance,
          hideBalance: hideBalance,
        );

      final data = AssetsUtils.aggregatedAssetsDataFromJson(
          this, store!.assets.aggregatedAssets!, balances);
      // // data.forEach((element) => print(element));
      // final total = data.map((e) => e.value).reduce((a, b) => a + b);
      // return Text('total: ${hideBalance ? '***' : total}');
      return InstrumentWidget(
        instrumentData(data, context, priceCurrency: priceCurrency, rate: rate),
        onSwitchBack,
        onSwitchHideBalance,
        hideBalance: hideBalance,
      );
    });
  }

  List<InstrumentData> instrumentData(
      List<AggregatedAssetsData> data, BuildContext context,
      {String priceCurrency = 'USD', double rate = 1.0}) {
    final List<InstrumentData> datas = [];
    InstrumentData totalBalance1 = InstrumentData(0, [],
        title: I18n.of(context)!
            .getDic(i18n_full_dic_karura, 'acala')!["v3.myDefi"]);
    datas.add(totalBalance1);

    final total = data.map((e) => e.value).reduce((a, b) => a! + b!);
    InstrumentData totalBalance = InstrumentData((total ?? 0) * rate, [],
        currencySymbol: Fmt.priceCurrencySymbol(priceCurrency),
        title: I18n.of(context)!
            .getDic(i18n_full_dic_karura, 'acala')!["v3.myDefi"]);
    data.forEach((element) {
      totalBalance.items.add(InstrumentItemData(
          _instrumentColor(element.category),
          element.category == "LP Staking" ? "LP Stake" : element.category,
          (element.value ?? 0) * rate));
    });
    datas.add(totalBalance);
    datas.add(totalBalance1);
    return datas;
  }

  Color _instrumentColor(String? category) {
    switch (category) {
      case "Tokens":
        return Color(0xFF5E5C59);
      case "Vaults":
        return Color(0xFFFF7647);
      case "LP Staking":
        return Color(0xFF7D97EE);
      case "Rewards":
        return Color(0xFFFFC952);
      default:
        return Color(0xFFFFC952);
    }
  }

  @override
  Widget? getNativeTokenTransfers(
      {required String address, int transferType = 0}) {
    return NativeTokenTransfers(this, address, transferType);
  }

  @override
  Map<String, WidgetBuilder> getRoutes(Keyring keyring) {
    return {
      TxConfirmPage.route: (_) =>
          TxConfirmPage(this, keyring, _service!.getPassword),
      XcmTxConfirmPage.route: (_) =>
          XcmTxConfirmPage(this, keyring, _service!.getPassword),
      CurrencySelectPage.route: (_) => CurrencySelectPage(this),
      AccountQrCodePage.route: (_) => AccountQrCodePage(this, keyring),

      TokenDetailPage.route: (_) => TokenDetailPage(this, keyring),
      TransferPage.route: (_) => TransferPage(this, keyring),
      TransferDetailPage.route: (_) => TransferDetailPage(this, keyring),

      //new ui
      ...getNewUiRoutes(this, keyring),

      //multiply
      MultiplyPage.route: (_) => MultiplyPage(this, keyring),
      MultiplyCreatePage.route: (_) => MultiplyCreatePage(this, keyring),
    };
  }

  @override
  Future<String> loadJSCode() => rootBundle.loadString(
      'packages/polkawallet_plugin_karura/lib/js_service_karura/dist/main.js');

  AcalaApi? _api;
  AcalaApi? get api => _api;

  StoreCache? _cache;
  PluginStore? _store;
  PluginService? _service;
  PluginStore? get store => _store;
  PluginService? get service => _service;

  Future<void> _subscribeTokenBalances(KeyPairData acc) async {
    _api!.assets.subscribeTokenBalances(acc.address, (data) {
      _store!.assets.setTokenBalanceMap(data, acc.pubKey);

      balances.setTokens(data);
    });

    _service!.assets.queryAggregatedAssets();

    final nft = await _api!.assets.queryNFTs(acc.address);
    _store!.assets.setNFTs(nft);
  }

  void _loadCacheData(KeyPairData acc) {
    balances.setExtraTokens([]);
    _store!.assets.setNFTs([]);

    try {
      loadBalances(acc);

      _store!.assets.loadCache(acc.pubKey);
      final tokens = _store!.assets.tokenBalanceMap.values.toList();
      final tokensConfig =
          service!.plugin.store!.setting.remoteConfig['tokens'] ?? {};
      if (tokensConfig['invisible'] != null) {
        final invisible = List.of(tokensConfig['invisible']);
        if (invisible.length > 0) {
          tokens.removeWhere(
              (token) => invisible.contains(token.symbol?.toUpperCase()));
        }
      }
      balances.setTokens(tokens, isFromCache: true);

      _store!.loan.loadCache(acc.pubKey);
      _store!.swap.loadCache(acc.pubKey);
      _store!.earn.setDexPoolInfo({}, reset: true);
      _store!.earn.setBootstraps([]);
      _store!.homa.setUserInfo(null);
      _store!.history.loadCache(acc.pubKey);
      _store!.accounts.loadCache(acc);
      print('acala plugin cache data loaded');
    } catch (err) {
      print(err);
      print('load acala cache data failed');
    }
  }

  @override
  Future<void> onWillStart(Keyring keyring) async {
    tokenIcons = _getTokenIcons();

    _api = AcalaApi(AcalaService(this));

    await GetStorage.init(plugin_cache_key);

    _cache = StoreCache();
    _store = PluginStore(_cache);
    _service = PluginService(this, keyring);

    _loadCacheData(keyring.current);

    // fetch tokens config here for subscribe all tokens balances
    _service!.fetchRemoteConfig();
    _service!.assets.queryIconsSrc();

    _service!.earn.getBlockDuration();
  }

  @override
  Future<void> onStarted(Keyring keyring) async {
    _service!.connected = true;

    if (keyring.current.address != null) {
      _store?.swap.initDexTokens(this);
      _subscribeTokenBalances(keyring.current);
      _getEvmAccount(keyring.current);
    }
  }

  @override
  Future<void> onAccountChanged(KeyPairData acc) async {
    store!.accounts.setEthWalletData(null, acc);
    _loadCacheData(acc);

    if (_service!.connected) {
      _api!.assets.unsubscribeTokenBalances(acc.address);
      _subscribeTokenBalances(acc);
      _getEvmAccount(acc);
    }
  }

  Future<void> _getEvmAccount(KeyPairData acc) async {
    if (store?.accounts.ethWalletData != null) return;
    final data = await sdk.api.service.webView!
        .evalJavascript('api.query.evmAccounts.evmAddresses("${acc.address}")');
    if (data != null) {
      try {
        final icons = await sdk.api.eth.account.service.getAddressIcons([data]);
        store!.accounts.setEthWalletData(
            EthWalletData()
              ..address = data
              ..icon = (icons!.last as List).last.toString(),
            acc);
      } catch (_) {}
    }
  }
}
