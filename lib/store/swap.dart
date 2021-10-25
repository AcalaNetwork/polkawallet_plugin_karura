import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_karura/store/cache/storeCache.dart';

part 'swap.g.dart';

class SwapStore extends _SwapStore with _$SwapStore {
  SwapStore(StoreCache cache) : super(cache);
}

abstract class _SwapStore with Store {
  _SwapStore(this.cache);

  final StoreCache cache;

  @observable
  Map<String, List<String>> _swapPair = Map<String, List<String>>();

  @action
  void setSwapPair(List<String> value, String pubKey) {
    _swapPair[pubKey] = value;
    if (value != cache.swapPair.val[pubKey]) {
      final cached = cache.swapPair.val;
      cached[pubKey] = jsonEncode(value);
      cache.swapPair.val = cached;
    }
  }

  @action
  List<String> swapPair(String pubKey) {
    return _swapPair[pubKey] ?? [];
  }

  @action
  void loadCache(String pubKey) {
    if (pubKey == null || pubKey.isEmpty) return;

    final _swapPair = cache.swapPair.val;
    if (_swapPair != null && _swapPair[pubKey] != null) {
      var data = jsonDecode(_swapPair[pubKey]).cast<String>();
      setSwapPair([data[0], data[1]], pubKey);
    }
  }
}
