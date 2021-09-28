// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homa.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$HomaStore on _HomaStore, Store {
  final _$poolInfoAtom = Atom(name: '_HomaStore.poolInfo');

  @override
  HomaLitePoolInfoData get poolInfo {
    _$poolInfoAtom.reportRead();
    return super.poolInfo;
  }

  @override
  set poolInfo(HomaLitePoolInfoData value) {
    _$poolInfoAtom.reportWrite(value, super.poolInfo, () {
      super.poolInfo = value;
    });
  }

  final _$userInfoAtom = Atom(name: '_HomaStore.userInfo');

  @override
  HomaUserInfoData get userInfo {
    _$userInfoAtom.reportRead();
    return super.userInfo;
  }

  @override
  set userInfo(HomaUserInfoData value) {
    _$userInfoAtom.reportWrite(value, super.userInfo, () {
      super.userInfo = value;
    });
  }

  final _$txsAtom = Atom(name: '_HomaStore.txs');

  @override
  ObservableList<TxHomaData> get txs {
    _$txsAtom.reportRead();
    return super.txs;
  }

  @override
  set txs(ObservableList<TxHomaData> value) {
    _$txsAtom.reportWrite(value, super.txs, () {
      super.txs = value;
    });
  }

  final _$setHomaUserInfoAsyncAction =
      AsyncAction('_HomaStore.setHomaUserInfo');

  @override
  Future<void> setHomaUserInfo(HomaUserInfoData info) {
    return _$setHomaUserInfoAsyncAction.run(() => super.setHomaUserInfo(info));
  }

  final _$_HomaStoreActionController = ActionController(name: '_HomaStore');

  @override
  void setHomaLitePoolInfoData(HomaLitePoolInfoData data) {
    final _$actionInfo = _$_HomaStoreActionController.startAction(
        name: '_HomaStore.setHomaLitePoolInfoData');
    try {
      return super.setHomaLitePoolInfoData(data);
    } finally {
      _$_HomaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addHomaTx(Map<dynamic, dynamic> tx, String pubKey) {
    final _$actionInfo =
        _$_HomaStoreActionController.startAction(name: '_HomaStore.addHomaTx');
    try {
      return super.addHomaTx(tx, pubKey);
    } finally {
      _$_HomaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void loadCache(String pubKey) {
    final _$actionInfo =
        _$_HomaStoreActionController.startAction(name: '_HomaStore.loadCache');
    try {
      return super.loadCache(pubKey);
    } finally {
      _$_HomaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
poolInfo: ${poolInfo},
userInfo: ${userInfo},
txs: ${txs}
    ''';
  }
}
