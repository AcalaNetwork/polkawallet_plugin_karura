import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/common/components/connectionChecker.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/bootstrapList.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/dexPoolList.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/swapForm.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPageTitleTaps.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class SwapPage extends StatefulWidget {
  SwapPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/dex';

  @override
  _SwapPageState createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  int _tab = 0;

  bool _loading = true;

  Future<void> _updateData() async {
    if (widget.plugin.sdk.api.connectedNode != null) {
      await widget.plugin.service!.earn.getDexPools();
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(_) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    if (args != null && args['swapPair'] != null) {}
    return PluginScaffold(
      extendBodyBehindAppBar: true,
      appBar: PluginAppBar(
        title: PluginPageTitleTaps(
          names: [dic['dex.title']!, dic['dex.lp']!, dic['boot.title']!],
          activeTab: _tab,
          isSpaceBetween: true,
          onTap: (i) {
            if (i != _tab) {
              setState(() {
                _tab = i;
              });
            }
          },
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: PluginIconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(SwapHistoryPage.route),
              icon: Icon(
                Icons.history,
                size: 22,
                color: Color(0xFF17161F),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
          child: Column(
        children: [
          ConnectionChecker(widget.plugin, onConnected: _updateData),
          _loading
              ? SwapSkeleton()
              : Expanded(
                  child: _tab == 0
                      ? SwapForm(widget.plugin, widget.keyring,
                          initialSwapPair:
                              args != null ? args['swapPair'] : null)
                      : _tab == 1
                          ? DexPoolList(widget.plugin, widget.keyring)
                          : BootstrapList(widget.plugin, widget.keyring),
                ),
        ],
      )),
    );
  }
}

class SwapSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      builder: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 50,
            height: 14,
            color: Colors.white,
            margin: EdgeInsets.only(right: 16),
          ),
          Container(
            margin: EdgeInsets.only(left: 16, right: 16, top: 8),
            decoration: BoxDecoration(
                color: Color(0x24FFFFFF),
                borderRadius: BorderRadius.all(Radius.circular(4))),
            child: SkeletonLoader(
              builder: Container(
                padding:
                    EdgeInsets.only(left: 8, right: 6, top: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: <Widget>[
                        Container(width: 140, height: 14, color: Colors.white),
                        Expanded(
                          child: SizedBox(height: 14),
                        ),
                        Container(width: 80, height: 34, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              items: 1,
              period: Duration(seconds: 2),
              highlightColor: Color(0xFFC0C0C0),
              baseColor: Color(0xFFE0E0E0),
              direction: SkeletonDirection.ltr,
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
                color: Color(0x24FFFFFF),
                borderRadius: BorderRadius.all(Radius.circular(4))),
            child: SkeletonLoader(
              builder: Container(
                padding:
                    EdgeInsets.only(left: 8, right: 6, top: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: <Widget>[
                        Container(width: 140, height: 14, color: Colors.white),
                        Expanded(
                          child: SizedBox(height: 14),
                        ),
                        Container(width: 80, height: 34, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              items: 1,
              period: Duration(seconds: 2),
              highlightColor: Color(0xFFC0C0C0),
              baseColor: Color(0xFFE0E0E0),
              direction: SkeletonDirection.ltr,
            ),
          ),
          Container(
              width: 90,
              height: 14,
              color: Colors.white,
              margin: EdgeInsets.only(right: 16)),
        ],
      ),
      items: 1,
      period: Duration(seconds: 2),
      highlightColor: Color(0xFFC0C0C0),
      baseColor: Color(0xFFE0E0E0),
      direction: SkeletonDirection.ltr,
    );
  }
}
