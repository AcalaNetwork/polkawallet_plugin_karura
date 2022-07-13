// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'historys.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$HistoryStore on _HistoryStore, Store {
  final _$transfersMapAtom = Atom(name: '_HistoryStore.transfersMap');

  @override
  Map<String?, List<HistoryData>> get transfersMap {
    _$transfersMapAtom.reportRead();
    return super.transfersMap;
  }

  @override
  set transfersMap(Map<String?, List<HistoryData>> value) {
    _$transfersMapAtom.reportWrite(value, super.transfersMap, () {
      super.transfersMap = value;
    });
  }

  final _$swapsAtom = Atom(name: '_HistoryStore.swaps');

  @override
  List<HistoryData>? get swaps {
    _$swapsAtom.reportRead();
    return super.swaps;
  }

  @override
  set swaps(List<HistoryData>? value) {
    _$swapsAtom.reportWrite(value, super.swaps, () {
      super.swaps = value;
    });
  }

  final _$earnsAtom = Atom(name: '_HistoryStore.earns');

  @override
  List<HistoryData>? get earns {
    _$earnsAtom.reportRead();
    return super.earns;
  }

  @override
  set earns(List<HistoryData>? value) {
    _$earnsAtom.reportWrite(value, super.earns, () {
      super.earns = value;
    });
  }

  final _$loansAtom = Atom(name: '_HistoryStore.loans');

  @override
  List<HistoryData>? get loans {
    _$loansAtom.reportRead();
    return super.loans;
  }

  @override
  set loans(List<HistoryData>? value) {
    _$loansAtom.reportWrite(value, super.loans, () {
      super.loans = value;
    });
  }

  final _$homasAtom = Atom(name: '_HistoryStore.homas');

  @override
  List<HistoryData>? get homas {
    _$homasAtom.reportRead();
    return super.homas;
  }

  @override
  set homas(List<HistoryData>? value) {
    _$homasAtom.reportWrite(value, super.homas, () {
      super.homas = value;
    });
  }

  final _$_HistoryStoreActionController =
      ActionController(name: '_HistoryStore');

  @override
  void setTransfersMap(String token, List<HistoryData> list) {
    final _$actionInfo = _$_HistoryStoreActionController.startAction(
        name: '_HistoryStore.setTransfersMap');
    try {
      return super.setTransfersMap(token, list);
    } finally {
      _$_HistoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSwaps(List<HistoryData> list) {
    final _$actionInfo = _$_HistoryStoreActionController.startAction(
        name: '_HistoryStore.setSwaps');
    try {
      return super.setSwaps(list);
    } finally {
      _$_HistoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEarns(List<HistoryData> list) {
    final _$actionInfo = _$_HistoryStoreActionController.startAction(
        name: '_HistoryStore.setEarns');
    try {
      return super.setEarns(list);
    } finally {
      _$_HistoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLoans(List<HistoryData> list) {
    final _$actionInfo = _$_HistoryStoreActionController.startAction(
        name: '_HistoryStore.setLoans');
    try {
      return super.setLoans(list);
    } finally {
      _$_HistoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setHomas(List<HistoryData> list) {
    final _$actionInfo = _$_HistoryStoreActionController.startAction(
        name: '_HistoryStore.setHomas');
    try {
      return super.setHomas(list);
    } finally {
      _$_HistoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void loadCache(String? pubKey) {
    final _$actionInfo = _$_HistoryStoreActionController.startAction(
        name: '_HistoryStore.loadCache');
    try {
      return super.loadCache(pubKey);
    } finally {
      _$_HistoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
transfersMap: ${transfersMap},
swaps: ${swaps},
earns: ${earns},
loans: ${loans},
homas: ${homas}
    ''';
  }
}
