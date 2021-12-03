import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/nftData.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';

part 'assets.g.dart';

class AssetsStore extends _AssetsStore with _$AssetsStore {
  AssetsStore(StoreCache cache) : super(cache);
}

abstract class _AssetsStore with Store {
  _AssetsStore(this.cache);

  final StoreCache cache;

  @observable
  Map<String, TokenBalanceData> tokenBalanceMap =
      Map<String, TokenBalanceData>();

  @observable
  Map<String, BigInt> prices = {};

  @observable
  ObservableMap<String, double> marketPrices = ObservableMap();

  @observable
  List<NFTData> nft = [];

  @observable
  Map aggregatedAssets = {};

  @action
  void setTokenBalanceMap(List<TokenBalanceData> list, String pubKey,
      {bool shouldCache = true}) {
    final data = Map<String, TokenBalanceData>();
    final dataForCache = {};
    list.forEach((e) {
      data[e.id] = e;

      dataForCache[e.id] = {
        'id': e.id,
        'name': e.name,
        'symbol': e.symbol,
        'decimals': e.decimals,
        'amount': e.amount,
        'detailPageRoute': e.detailPageRoute,
      };
    });
    tokenBalanceMap = data;

    if (shouldCache) {
      final cached = cache.tokens.val;
      cached[pubKey] = dataForCache;
      cache.tokens.val = cached;
    }
  }

  @action
  void setPrices(Map<String, BigInt> data) {
    prices = data;
  }

  @action
  void setMarketPrices(Map<String, double> data) {
    marketPrices.addAll(data);
  }

  @action
  void setNFTs(List<NFTData> list) {
    nft = list;
  }

  @action
  void setAggregatedAssets(Map data, String pubKey) {
    aggregatedAssets = data;

    final cached = cache.aggregatedAssets.val;
    cached[pubKey] = data;
    cache.aggregatedAssets.val = cached;
  }

  @action
  void loadCache(String pubKey) {
    if (pubKey == null || pubKey.isEmpty) return;

    final cachedTokens = cache.tokens.val;
    if (cachedTokens != null && cachedTokens[pubKey] != null) {
      final tokens = cachedTokens[pubKey].values.toList();
      setTokenBalanceMap(
          List<TokenBalanceData>.from(tokens.map((e) => TokenBalanceData(
              id: e['id'],
              name: e['name'],
              symbol: e['symbol'],
              decimals: e['decimals'],
              amount: e['amount'],
              detailPageRoute: e['detailPageRoute']))),
          pubKey,
          shouldCache: false);
    } else {
      tokenBalanceMap = Map<String, TokenBalanceData>();
    }

    final cachedAggregatedAssets = cache.aggregatedAssets.val;
    if (cachedAggregatedAssets != null &&
        cachedAggregatedAssets[pubKey] != null) {
      aggregatedAssets = cachedAggregatedAssets[pubKey];
    } else {
      aggregatedAssets = {};
    }
  }
}
