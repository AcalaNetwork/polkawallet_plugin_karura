// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homa.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$HomaStore on _HomaStore, Store {
  final _$envAtom = Atom(name: '_HomaStore.env');

  @override
  HomaNewEnvData? get env {
    _$envAtom.reportRead();
    return super.env;
  }

  @override
  set env(HomaNewEnvData? value) {
    _$envAtom.reportWrite(value, super.env, () {
      super.env = value;
    });
  }

  final _$userInfoAtom = Atom(name: '_HomaStore.userInfo');

  @override
  HomaPendingRedeemData? get userInfo {
    _$userInfoAtom.reportRead();
    return super.userInfo;
  }

  @override
  set userInfo(HomaPendingRedeemData? value) {
    _$userInfoAtom.reportWrite(value, super.userInfo, () {
      super.userInfo = value;
    });
  }

  final _$_HomaStoreActionController = ActionController(name: '_HomaStore');

  @override
  void setHomaEnv(HomaNewEnvData data) {
    final _$actionInfo =
        _$_HomaStoreActionController.startAction(name: '_HomaStore.setHomaEnv');
    try {
      return super.setHomaEnv(data);
    } finally {
      _$_HomaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setUserInfo(HomaPendingRedeemData? data) {
    final _$actionInfo = _$_HomaStoreActionController.startAction(
        name: '_HomaStore.setUserInfo');
    try {
      return super.setUserInfo(data);
    } finally {
      _$_HomaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
env: ${env},
userInfo: ${userInfo}
    ''';
  }
}
