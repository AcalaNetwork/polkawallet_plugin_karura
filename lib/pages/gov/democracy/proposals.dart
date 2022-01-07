import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/pages/gov/democracy/proposalPanel.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_ui/components/listTail.dart';

class Proposals extends StatefulWidget {
  Proposals(this.plugin);
  final PluginKarura plugin;

  @override
  _ProposalsState createState() => _ProposalsState();
}

class _ProposalsState extends State<Proposals> {
  bool isLoading = false;
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  Future<void> _fetchData() async {
    if (widget.plugin.sdk.api.connectedNode == null) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    await widget.plugin.service!.gov.queryProposals();
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _refreshKey.currentState!.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (BuildContext context) {
        return RefreshIndicator(
          key: _refreshKey,
          onRefresh: _fetchData,
          child: widget.plugin.store!.gov.proposals == null ||
                  widget.plugin.store!.gov.proposals.length == 0
              ? Center(
                  child: ListTail(
                  isEmpty: true,
                  isLoading: isLoading,
                  isShowLoadText: true,
                ))
              : ListView.builder(
                  itemCount: widget.plugin.store!.gov.proposals.length + 1,
                  itemBuilder: (_, int i) {
                    if (widget.plugin.store!.gov.proposals.length == i) {
                      return Center(
                          child: ListTail(isEmpty: false, isLoading: false));
                    }
                    return ProposalPanel(
                        widget.plugin, widget.plugin.store!.gov.proposals[i]);
                  }),
        );
      },
    );
  }
}
