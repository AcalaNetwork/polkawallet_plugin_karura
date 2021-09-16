// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$LoanStore on _LoanStore, Store {
  final _$loanTypesAtom = Atom(name: '_LoanStore.loanTypes');

  @override
  List<LoanType> get loanTypes {
    _$loanTypesAtom.reportRead();
    return super.loanTypes;
  }

  @override
  set loanTypes(List<LoanType> value) {
    _$loanTypesAtom.reportWrite(value, super.loanTypes, () {
      super.loanTypes = value;
    });
  }

  final _$totalCDPsAtom = Atom(name: '_LoanStore.totalCDPs');

  @override
  Map<String, TotalCDPData> get totalCDPs {
    _$totalCDPsAtom.reportRead();
    return super.totalCDPs;
  }

  @override
  set totalCDPs(Map<String, TotalCDPData> value) {
    _$totalCDPsAtom.reportWrite(value, super.totalCDPs, () {
      super.totalCDPs = value;
    });
  }

  final _$loansAtom = Atom(name: '_LoanStore.loans');

  @override
  Map<String, LoanData> get loans {
    _$loansAtom.reportRead();
    return super.loans;
  }

  @override
  set loans(Map<String, LoanData> value) {
    _$loansAtom.reportWrite(value, super.loans, () {
      super.loans = value;
    });
  }

  final _$collateralIncentivesAtom =
      Atom(name: '_LoanStore.collateralIncentives');

  @override
  Map<String, double> get collateralIncentives {
    _$collateralIncentivesAtom.reportRead();
    return super.collateralIncentives;
  }

  @override
  set collateralIncentives(Map<String, double> value) {
    _$collateralIncentivesAtom.reportWrite(value, super.collateralIncentives,
        () {
      super.collateralIncentives = value;
    });
  }

  final _$collateralRewardsAtom = Atom(name: '_LoanStore.collateralRewards');

  @override
  Map<String, CollateralRewardData> get collateralRewards {
    _$collateralRewardsAtom.reportRead();
    return super.collateralRewards;
  }

  @override
  set collateralRewards(Map<String, CollateralRewardData> value) {
    _$collateralRewardsAtom.reportWrite(value, super.collateralRewards, () {
      super.collateralRewards = value;
    });
  }

  final _$collateralRewardsV2Atom =
      Atom(name: '_LoanStore.collateralRewardsV2');

  @override
  Map<String, CollateralRewardDataV2> get collateralRewardsV2 {
    _$collateralRewardsV2Atom.reportRead();
    return super.collateralRewardsV2;
  }

  @override
  set collateralRewardsV2(Map<String, CollateralRewardDataV2> value) {
    _$collateralRewardsV2Atom.reportWrite(value, super.collateralRewardsV2, () {
      super.collateralRewardsV2 = value;
    });
  }

  final _$loyaltyBonusAtom = Atom(name: '_EarnStore.loyaltyBonus');

  @override
  Map<String, double> get loyaltyBonus {
    _$loyaltyBonusAtom.reportRead();
    return super.loyaltyBonus;
  }

  @override
  set loyaltyBonus(Map<String, double> value) {
    _$loyaltyBonusAtom.reportWrite(value, super.loyaltyBonus, () {
      super.loyaltyBonus = value;
    });
  }

  final _$loansLoadingAtom = Atom(name: '_LoanStore.loansLoading');

  @override
  bool get loansLoading {
    _$loansLoadingAtom.reportRead();
    return super.loansLoading;
  }

  @override
  set loansLoading(bool value) {
    _$loansLoadingAtom.reportWrite(value, super.loansLoading, () {
      super.loansLoading = value;
    });
  }

  final _$_LoanStoreActionController = ActionController(name: '_LoanStore');

  @override
  void setLoanTypes(List<LoanType> list) {
    final _$actionInfo = _$_LoanStoreActionController.startAction(
        name: '_LoanStore.setLoanTypes');
    try {
      return super.setLoanTypes(list);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setTotalCDPs(List<TotalCDPData> list) {
    final _$actionInfo = _$_LoanStoreActionController.startAction(
        name: '_LoanStore.setTotalCDPs');
    try {
      return super.setTotalCDPs(list);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCollateralIncentives(
      Map<String, double> data, Map<String, double> bonus) {
    final _$actionInfo = _$_LoanStoreActionController.startAction(
        name: '_LoanStore.setCollateralIncentives');
    try {
      return super.setCollateralIncentives(data, bonus);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCollateralRewards(List<CollateralRewardData> data) {
    final _$actionInfo = _$_LoanStoreActionController.startAction(
        name: '_LoanStore.setCollateralRewards');
    try {
      return super.setCollateralRewards(data);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCollateralRewardsV2(List<CollateralRewardDataV2> data) {
    final _$actionInfo = _$_LoanStoreActionController.startAction(
        name: '_LoanStore.setCollateralRewardsV2');
    try {
      return super.setCollateralRewardsV2(data);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAccountLoans(Map<String, LoanData> data) {
    final _$actionInfo = _$_LoanStoreActionController.startAction(
        name: '_LoanStore.setAccountLoans');
    try {
      return super.setAccountLoans(data);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLoansLoading(bool loading) {
    final _$actionInfo = _$_LoanStoreActionController.startAction(
        name: '_LoanStore.setLoansLoading');
    try {
      return super.setLoansLoading(loading);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void loadCache(String pubKey) {
    final _$actionInfo =
        _$_LoanStoreActionController.startAction(name: '_LoanStore.loadCache');
    try {
      return super.loadCache(pubKey);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
loanTypes: ${loanTypes},
totalCDPs: ${totalCDPs},
loans: ${loans},
collateralIncentives: ${collateralIncentives},
collateralRewards: ${collateralRewards},
loyaltyBonus: ${loyaltyBonus},
loansLoading: ${loansLoading}
    ''';
  }
}
