import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/pages/gov/democracy/referendumPanel.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';

class Democracy extends StatefulWidget {
  Democracy(this.plugin, this.keyring);

  final PluginKarura plugin;
  final Keyring keyring;

  @override
  _DemocracyState createState() => _DemocracyState();
}

class _DemocracyState extends State<Democracy> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  List _unlocks = [];

  Future<void> _queryDemocracyUnlocks() async {
    final List unlocks = await widget.plugin.sdk.api.gov
        .getDemocracyUnlocks(widget.keyring.current.address);
    if (mounted && unlocks != null) {
      setState(() {
        _unlocks = unlocks;
      });
    }
  }

  Future<void> _fetchReferendums() async {
    if (widget.plugin.sdk.api.connectedNode == null) {
      return;
    }
    widget.plugin.service.gov.getReferendumVoteConvictions();
    await widget.plugin.service.gov.queryReferendums();

    _queryDemocracyUnlocks();
  }

  Future<void> _submitCancelVote(int id) async {
    final govDic = I18n.of(context).getDic(i18n_full_dic_acala, 'gov');
    final params = TxConfirmParams(
      module: 'democracy',
      call: 'removeVote',
      txTitle: govDic['vote.remove'],
      txDisplay: {"id": id},
      params: [id],
    );
    final res = await Navigator.of(context)
        .pushNamed(TxConfirmPage.route, arguments: params);
    if (res != null) {
      _refreshKey.currentState.show();
    }
  }

  void _onUnlock() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'gov');
    final txs = _unlocks
        .map(
            (e) => 'api.tx.democracy.removeVote(${BigInt.parse(e.toString())})')
        .toList();
    txs.add('api.tx.democracy.unlock("${widget.keyring.current.address}")');
    final res = await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
          txTitle: dic['democracy.unlock'],
          module: 'utility',
          call: 'batch',
          txDisplay: {
            "actions": ['democracy.removeVote', 'democracy.unlock'],
          },
          params: [],
          rawParams: '[[${txs.join(',')}]]',
        ));
    if (res != null) {
      _refreshKey.currentState.show();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.plugin.sdk.api.connectedNode != null) {
      widget.plugin.service.gov.subscribeBestNumber();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState.show();
    });
  }

  @override
  void dispose() {
    widget.plugin.service.gov.unsubscribeBestNumber();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'gov');
    return Observer(
      builder: (_) {
        final decimals = widget.plugin.networkState.tokenDecimals[0];
        final symbol = widget.plugin.networkState.tokenSymbol[0];
        final list = widget.plugin.store.gov.referendums;
        final bestNumber = widget.plugin.store.gov.bestNumber;

        final count = list?.length ?? 0;
        return RefreshIndicator(
          key: _refreshKey,
          onRefresh: _fetchReferendums,
          child: ListView.builder(
            itemCount: count + 2,
            itemBuilder: (BuildContext context, int i) {
              if (i == 0) {
                return _unlocks.length > 0
                    ? RoundedCard(
                        margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dic['democracy.expire']),
                            OutlinedButtonSmall(
                              active: true,
                              content: dic['democracy.unlock'],
                              onPressed: _onUnlock,
                              margin: EdgeInsets.all(0),
                            )
                          ],
                        ),
                      )
                    : Container();
              }
              return i == count + 1
                  ? Container(
                      margin: EdgeInsets.only(
                          top: count == 0
                              ? MediaQuery.of(context).size.width / 2
                              : 0),
                      child: Center(
                          child: ListTail(
                        isEmpty: count == 0,
                        isLoading: false,
                      )),
                    )
                  : ReferendumPanel(
                      data: list[i - 1],
                      bestNumber: bestNumber,
                      symbol: symbol,
                      decimals: decimals,
                      blockDuration: BLOCK_TIME_DEFAULT,
                      onCancelVote: _submitCancelVote,
                      links: Container(),
                      onRefresh: () {
                        _refreshKey.currentState.show();
                      },
                    );
            },
          ),
        );
      },
    );
  }
}
