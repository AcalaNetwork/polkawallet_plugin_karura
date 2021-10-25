// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swap.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$SwapStore on _SwapStore, Store {
  final _$_swapPairAtom = Atom(name: '_SwapStore._swapPair');

  @override
  Map<dynamic, dynamic> get _swapPair {
    _$_swapPairAtom.reportRead();
    return super._swapPair;
  }

  @override
  set _swapPair(Map<dynamic, dynamic> value) {
    _$_swapPairAtom.reportWrite(value, super._swapPair, () {
      super._swapPair = value;
    });
  }

  final _$_SwapStoreActionController = ActionController(name: '_SwapStore');

  @override
  void setSwapPair(List<dynamic> value, String pubKey) {
    final _$actionInfo = _$_SwapStoreActionController.startAction(
        name: '_SwapStore.setSwapPair');
    try {
      return super.setSwapPair(value, pubKey);
    } finally {
      _$_SwapStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  List<String> swapPair(String pubKey) {
    final _$actionInfo =
        _$_SwapStoreActionController.startAction(name: '_SwapStore.swapPair');
    try {
      return super.swapPair(pubKey);
    } finally {
      _$_SwapStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void loadCache(String pubKey) {
    final _$actionInfo =
        _$_SwapStoreActionController.startAction(name: '_SwapStore.loadCache');
    try {
      return super.loadCache(pubKey);
    } finally {
      _$_SwapStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''

    ''';
  }
}
