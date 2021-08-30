// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earn.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$EarnStore on _EarnStore, Store {
  final _$swapPoolRewardsAtom = Atom(name: '_EarnStore.swapPoolRewards');

  @override
  ObservableMap<String, double> get swapPoolRewards {
    _$swapPoolRewardsAtom.reportRead();
    return super.swapPoolRewards;
  }

  @override
  set swapPoolRewards(ObservableMap<String, double> value) {
    _$swapPoolRewardsAtom.reportWrite(value, super.swapPoolRewards, () {
      super.swapPoolRewards = value;
    });
  }

  final _$swapPoolSavingRewardsAtom =
      Atom(name: '_EarnStore.swapPoolSavingRewards');

  @override
  ObservableMap<String, double> get swapPoolSavingRewards {
    _$swapPoolSavingRewardsAtom.reportRead();
    return super.swapPoolSavingRewards;
  }

  @override
  set swapPoolSavingRewards(ObservableMap<String, double> value) {
    _$swapPoolSavingRewardsAtom.reportWrite(value, super.swapPoolSavingRewards,
        () {
      super.swapPoolSavingRewards = value;
    });
  }

  final _$loyaltyBonusAtom = Atom(name: '_EarnStore.loyaltyBonus');

  @override
  ObservableMap<String, double> get loyaltyBonus {
    _$loyaltyBonusAtom.reportRead();
    return super.loyaltyBonus;
  }

  @override
  set loyaltyBonus(ObservableMap<String, double> value) {
    _$loyaltyBonusAtom.reportWrite(value, super.loyaltyBonus, () {
      super.loyaltyBonus = value;
    });
  }

  final _$savingLoyaltyBonusAtom = Atom(name: '_EarnStore.savingLoyaltyBonus');

  @override
  ObservableMap<String, double> get savingLoyaltyBonus {
    _$savingLoyaltyBonusAtom.reportRead();
    return super.savingLoyaltyBonus;
  }

  @override
  set savingLoyaltyBonus(ObservableMap<String, double> value) {
    _$savingLoyaltyBonusAtom.reportWrite(value, super.savingLoyaltyBonus, () {
      super.savingLoyaltyBonus = value;
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
  void setDexPoolRewards(Map<String, Map<String, double>> data) {
    final _$actionInfo = _$_EarnStoreActionController.startAction(
        name: '_EarnStore.setDexPoolRewards');
    try {
      return super.setDexPoolRewards(data);
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
swapPoolRewards: ${swapPoolRewards},
swapPoolSavingRewards: ${swapPoolSavingRewards},
loyaltyBonus: ${loyaltyBonus},
savingLoyaltyBonus: ${savingLoyaltyBonus},
dexPools: ${dexPools},
bootstraps: ${bootstraps},
dexPoolInfoMap: ${dexPoolInfoMap}
    ''';
  }
}
