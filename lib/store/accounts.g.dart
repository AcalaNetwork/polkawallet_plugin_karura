// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$AccountsStore on _AccountsStore, Store {
  final _$addressIndexMapAtom = Atom(name: '_AccountsStore.addressIndexMap');

  @override
  ObservableMap<String?, Map<dynamic, dynamic>?> get addressIndexMap {
    _$addressIndexMapAtom.reportRead();
    return super.addressIndexMap;
  }

  @override
  set addressIndexMap(ObservableMap<String?, Map<dynamic, dynamic>?> value) {
    _$addressIndexMapAtom.reportWrite(value, super.addressIndexMap, () {
      super.addressIndexMap = value;
    });
  }

  final _$addressIconsMapAtom = Atom(name: '_AccountsStore.addressIconsMap');

  @override
  ObservableMap<String?, String?> get addressIconsMap {
    _$addressIconsMapAtom.reportRead();
    return super.addressIconsMap;
  }

  @override
  set addressIconsMap(ObservableMap<String?, String?> value) {
    _$addressIconsMapAtom.reportWrite(value, super.addressIconsMap, () {
      super.addressIconsMap = value;
    });
  }

  final _$_AccountsStoreActionController =
      ActionController(name: '_AccountsStore');

  @override
  void setAddressIconsMap(List<dynamic> list) {
    final _$actionInfo = _$_AccountsStoreActionController.startAction(
        name: '_AccountsStore.setAddressIconsMap');
    try {
      return super.setAddressIconsMap(list);
    } finally {
      _$_AccountsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAddressIndex(List<dynamic> list) {
    final _$actionInfo = _$_AccountsStoreActionController.startAction(
        name: '_AccountsStore.setAddressIndex');
    try {
      return super.setAddressIndex(list);
    } finally {
      _$_AccountsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
addressIndexMap: ${addressIndexMap},
addressIconsMap: ${addressIconsMap}
    ''';
  }
}
