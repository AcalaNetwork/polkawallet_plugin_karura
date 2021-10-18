// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earn.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$EarnStore on _EarnStore, Store {
  final _$incentivesAtom = Atom(name: '_EarnStore.incentives');

  @override
  IncentivesData get incentives {
    _$incentivesAtom.reportRead();
    return super.incentives;
  }

  @override
  set incentives(IncentivesData value) {
    _$incentivesAtom.reportWrite(value, super.incentives, () {
      super.incentives = value;
    });
  }

  final _$dexPoolsAtom = Atom(name: '_EarnStore.dexPools');

  @override
  List<DexPoolData> get dexPools {
    _$dexPoolsAtom.reportRead();
    return super.dexPools;
  }

  @override
  set dexPools(List<DexPoolData> value) {
    _$dexPoolsAtom.reportWrite(value, super.dexPools, () {
      super.dexPools = value;
    });
  }

  final _$bootstrapsAtom = Atom(name: '_EarnStore.bootstraps');

  @override
  List<DexPoolData> get bootstraps {
    _$bootstrapsAtom.reportRead();
    return super.bootstraps;
  }

  @override
  set bootstraps(List<DexPoolData> value) {
    _$bootstrapsAtom.reportWrite(value, super.bootstraps, () {
      super.bootstraps = value;
    });
  }

  final _$dexPoolInfoMapAtom = Atom(name: '_EarnStore.dexPoolInfoMap');

  @override
  ObservableMap<String, DexPoolInfoData> get dexPoolInfoMap {
    _$dexPoolInfoMapAtom.reportRead();
    return super.dexPoolInfoMap;
  }

  @override
  set dexPoolInfoMap(ObservableMap<String, DexPoolInfoData> value) {
    _$dexPoolInfoMapAtom.reportWrite(value, super.dexPoolInfoMap, () {
      super.dexPoolInfoMap = value;
    });
  }

  final _$dexPoolInfoMapV2Atom = Atom(name: '_EarnStore.dexPoolInfoMapV2');

  @override
  ObservableMap<String, DexPoolInfoDataV2> get dexPoolInfoMapV2 {
    _$dexPoolInfoMapV2Atom.reportRead();
    return super.dexPoolInfoMapV2;
  }

  @override
  set dexPoolInfoMapV2(ObservableMap<String, DexPoolInfoDataV2> value) {
    _$dexPoolInfoMapV2Atom.reportWrite(value, super.dexPoolInfoMapV2, () {
      super.dexPoolInfoMapV2 = value;
    });
  }

  final _$_EarnStoreActionController = ActionController(name: '_EarnStore');

  @override
  void setDexPools(List<DexPoolData> list) {
    final _$actionInfo = _$_EarnStoreActionController.startAction(
        name: '_EarnStore.setDexPools');
    try {
      return super.setDexPools(list);
    } finally {
      _$_EarnStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setBootstraps(List<DexPoolData> list) {
    final _$actionInfo = _$_EarnStoreActionController.startAction(
        name: '_EarnStore.setBootstraps');
    try {
      return super.setBootstraps(list);
    } finally {
      _$_EarnStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDexPoolInfo(Map<String, DexPoolInfoData> data) {
    final _$actionInfo = _$_EarnStoreActionController.startAction(
        name: '_EarnStore.setDexPoolInfo');
    try {
      return super.setDexPoolInfo(data);
    } finally {
      _$_EarnStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDexPoolInfoV2(Map<String, DexPoolInfoDataV2> data) {
    final _$actionInfo = _$_EarnStoreActionController.startAction(
        name: '_EarnStore.setDexPoolInfoV2');
    try {
      return super.setDexPoolInfoV2(data);
    } finally {
      _$_EarnStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setIncentives(IncentivesData data) {
    final _$actionInfo = _$_EarnStoreActionController.startAction(
        name: '_EarnStore.setIncentives');
    try {
      return super.setIncentives(data);
    } finally {
      _$_EarnStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void loadCache(String pubKey) {
    final _$actionInfo =
        _$_EarnStoreActionController.startAction(name: '_EarnStore.loadCache');
    try {
      return super.loadCache(pubKey);
    } finally {
      _$_EarnStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
incentives: ${incentives},
dexPools: ${dexPools},
bootstraps: ${bootstraps},
dexPoolInfoMap: ${dexPoolInfoMap},
dexPoolInfoMapV2: ${dexPoolInfoMapV2}
    ''';
  }
}
