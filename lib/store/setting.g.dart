// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$SettingStore on _SettingStore, Store {
  final _$liveModulesAtom = Atom(name: '_SettingStore.liveModules');

  @override
  Map<dynamic, dynamic> get liveModules {
    _$liveModulesAtom.reportRead();
    return super.liveModules;
  }

  @override
  set liveModules(Map<dynamic, dynamic> value) {
    _$liveModulesAtom.reportWrite(value, super.liveModules, () {
      super.liveModules = value;
    });
  }

  final _$_SettingStoreActionController =
      ActionController(name: '_SettingStore');

  @override
  void setLiveModules(Map<dynamic, dynamic> value) {
    final _$actionInfo = _$_SettingStoreActionController.startAction(
        name: '_SettingStore.setLiveModules');
    try {
      return super.setLiveModules(value);
    } finally {
      _$_SettingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
liveModules: ${liveModules}
    ''';
  }
}
