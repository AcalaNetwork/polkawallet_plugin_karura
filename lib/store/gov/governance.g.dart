// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'governance.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$GovernanceStore on _GovernanceStore, Store {
  final _$bestNumberAtom = Atom(name: '_GovernanceStore.bestNumber');

  @override
  BigInt get bestNumber {
    _$bestNumberAtom.reportRead();
    return super.bestNumber;
  }

  @override
  set bestNumber(BigInt value) {
    _$bestNumberAtom.reportWrite(value, super.bestNumber, () {
      super.bestNumber = value;
    });
  }

  final _$referendumsAtom = Atom(name: '_GovernanceStore.referendums');

  @override
  List<ReferendumInfo>? get referendums {
    _$referendumsAtom.reportRead();
    return super.referendums;
  }

  @override
  set referendums(List<ReferendumInfo>? value) {
    _$referendumsAtom.reportWrite(value, super.referendums, () {
      super.referendums = value;
    });
  }

  final _$voteConvictionsAtom = Atom(name: '_GovernanceStore.voteConvictions');

  @override
  List<dynamic>? get voteConvictions {
    _$voteConvictionsAtom.reportRead();
    return super.voteConvictions;
  }

  @override
  set voteConvictions(List<dynamic>? value) {
    _$voteConvictionsAtom.reportWrite(value, super.voteConvictions, () {
      super.voteConvictions = value;
    });
  }

  final _$proposalsAtom = Atom(name: '_GovernanceStore.proposals');

  @override
  List<ProposalInfoData> get proposals {
    _$proposalsAtom.reportRead();
    return super.proposals;
  }

  @override
  set proposals(List<ProposalInfoData> value) {
    _$proposalsAtom.reportWrite(value, super.proposals, () {
      super.proposals = value;
    });
  }

  final _$_GovernanceStoreActionController =
      ActionController(name: '_GovernanceStore');

  @override
  void setBestNumber(BigInt number) {
    final _$actionInfo = _$_GovernanceStoreActionController.startAction(
        name: '_GovernanceStore.setBestNumber');
    try {
      return super.setBestNumber(number);
    } finally {
      _$_GovernanceStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setReferendums(List<ReferendumInfo> ls) {
    final _$actionInfo = _$_GovernanceStoreActionController.startAction(
        name: '_GovernanceStore.setReferendums');
    try {
      return super.setReferendums(ls);
    } finally {
      _$_GovernanceStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setReferendumVoteConvictions(List<dynamic>? ls) {
    final _$actionInfo = _$_GovernanceStoreActionController.startAction(
        name: '_GovernanceStore.setReferendumVoteConvictions');
    try {
      return super.setReferendumVoteConvictions(ls);
    } finally {
      _$_GovernanceStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setProposals(List<ProposalInfoData> ls) {
    final _$actionInfo = _$_GovernanceStoreActionController.startAction(
        name: '_GovernanceStore.setProposals');
    try {
      return super.setProposals(ls);
    } finally {
      _$_GovernanceStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearState() {
    final _$actionInfo = _$_GovernanceStoreActionController.startAction(
        name: '_GovernanceStore.clearState');
    try {
      return super.clearState();
    } finally {
      _$_GovernanceStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
bestNumber: ${bestNumber},
referendums: ${referendums},
voteConvictions: ${voteConvictions},
proposals: ${proposals}
    ''';
  }
}
