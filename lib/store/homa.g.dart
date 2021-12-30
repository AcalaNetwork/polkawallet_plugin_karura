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

  final _$envAtom = Atom(name: '_HomaStore.env');

  @override
  HomaNewEnvData get env {
    _$envAtom.reportRead();
    return super.env;
  }

  @override
  set env(HomaNewEnvData value) {
    _$envAtom.reportWrite(value, super.env, () {
      super.env = value;
    });
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
  String toString() {
    return '''
poolInfo: ${poolInfo},
env: ${env},
    ''';
  }
}
