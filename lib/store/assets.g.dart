// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assets.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$AssetsStore on _AssetsStore, Store {
  final _$tokenBalanceMapAtom = Atom(name: '_AssetsStore.tokenBalanceMap');

  @override
  Map<String?, TokenBalanceData> get tokenBalanceMap {
    _$tokenBalanceMapAtom.reportRead();
    return super.tokenBalanceMap;
  }

  @override
  set tokenBalanceMap(Map<String?, TokenBalanceData> value) {
    _$tokenBalanceMapAtom.reportWrite(value, super.tokenBalanceMap, () {
      super.tokenBalanceMap = value;
    });
  }

  final _$pricesAtom = Atom(name: '_AssetsStore.prices');

  @override
  Map<String?, BigInt> get prices {
    _$pricesAtom.reportRead();
    return super.prices;
  }

  @override
  set prices(Map<String?, BigInt> value) {
    _$pricesAtom.reportWrite(value, super.prices, () {
      super.prices = value;
    });
  }

  final _$marketPricesAtom = Atom(name: '_AssetsStore.marketPrices');

  @override
  ObservableMap<String, num> get marketPrices {
    _$marketPricesAtom.reportRead();
    return super.marketPrices;
  }

  @override
  set marketPrices(ObservableMap<String, num> value) {
    _$marketPricesAtom.reportWrite(value, super.marketPrices, () {
      super.marketPrices = value;
    });
  }

  final _$dexPricesAtom = Atom(name: '_AssetsStore.dexPrices');

  @override
  Map<String, double> get dexPrices {
    _$dexPricesAtom.reportRead();
    return super.dexPrices;
  }

  @override
  set dexPrices(Map<String, double> value) {
    _$dexPricesAtom.reportWrite(value, super.dexPrices, () {
      super.dexPrices = value;
    });
  }

  final _$nftAtom = Atom(name: '_AssetsStore.nft');

  @override
  List<NFTData> get nft {
    _$nftAtom.reportRead();
    return super.nft;
  }

  @override
  set nft(List<NFTData> value) {
    _$nftAtom.reportWrite(value, super.nft, () {
      super.nft = value;
    });
  }

  final _$aggregatedAssetsAtom = Atom(name: '_AssetsStore.aggregatedAssets');

  @override
  Map<dynamic, dynamic>? get aggregatedAssets {
    _$aggregatedAssetsAtom.reportRead();
    return super.aggregatedAssets;
  }

  @override
  set aggregatedAssets(Map<dynamic, dynamic>? value) {
    _$aggregatedAssetsAtom.reportWrite(value, super.aggregatedAssets, () {
      super.aggregatedAssets = value;
    });
  }

  final _$_AssetsStoreActionController = ActionController(name: '_AssetsStore');

  @override
  void setTokenBalanceMap(List<TokenBalanceData> list, String? pubKey,
      {bool shouldCache = true}) {
    final _$actionInfo = _$_AssetsStoreActionController.startAction(
        name: '_AssetsStore.setTokenBalanceMap');
    try {
      return super.setTokenBalanceMap(list, pubKey, shouldCache: shouldCache);
    } finally {
      _$_AssetsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPrices(Map<String?, BigInt> data) {
    final _$actionInfo = _$_AssetsStoreActionController.startAction(
        name: '_AssetsStore.setPrices');
    try {
      return super.setPrices(data);
    } finally {
      _$_AssetsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setMarketPrices(Map<String, num> data) {
    final _$actionInfo = _$_AssetsStoreActionController.startAction(
        name: '_AssetsStore.setMarketPrices');
    try {
      return super.setMarketPrices(data);
    } finally {
      _$_AssetsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDexPrices(Map<String, double> data) {
    final _$actionInfo = _$_AssetsStoreActionController.startAction(
        name: '_AssetsStore.setDexPrices');
    try {
      return super.setDexPrices(data);
    } finally {
      _$_AssetsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNFTs(List<NFTData> list) {
    final _$actionInfo = _$_AssetsStoreActionController.startAction(
        name: '_AssetsStore.setNFTs');
    try {
      return super.setNFTs(list);
    } finally {
      _$_AssetsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAggregatedAssets(Map<dynamic, dynamic>? data, String? pubKey) {
    final _$actionInfo = _$_AssetsStoreActionController.startAction(
        name: '_AssetsStore.setAggregatedAssets');
    try {
      return super.setAggregatedAssets(data, pubKey);
    } finally {
      _$_AssetsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void loadCache(String? pubKey) {
    final _$actionInfo = _$_AssetsStoreActionController.startAction(
        name: '_AssetsStore.loadCache');
    try {
      return super.loadCache(pubKey);
    } finally {
      _$_AssetsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
tokenBalanceMap: ${tokenBalanceMap},
prices: ${prices},
marketPrices: ${marketPrices},
dexPrices: ${dexPrices},
nft: ${nft},
aggregatedAssets: ${aggregatedAssets}
    ''';
  }
}
