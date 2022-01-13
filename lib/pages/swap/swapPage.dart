import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/pages/swap/bootstrapList.dart';
import 'package:polkawallet_plugin_karura/pages/swap/dexPoolList.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapForm.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapHistoryPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/pageTitleTaps.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
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
  Timer? _waitNetworkTimer;

  Future<void> _updateData() async {
    if (widget.plugin.sdk.api.connectedNode != null) {
      await widget.plugin.service!.earn.getDexPools();
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } else {
      /// we need to re-fetch data with timer before wss connected
      _waitNetworkTimer = new Timer(Duration(seconds: 3), _updateData);
    }
  }

  @override
  void dispose() {
    if (_waitNetworkTimer != null) {
      _waitNetworkTimer?.cancel();
    }

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _updateData();
    });
  }

  @override
  Widget build(_) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    // todo: fix this after new acala online
    final bool enabled = widget.plugin.basic.name == 'acala'
        ? ModalRoute.of(context)!.settings.arguments as bool
        : true;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 240,
            decoration: BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).hoverColor
              ],
              stops: [0.4, 0.9],
            )),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios,
                            color: Theme.of(context).cardColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: PageTitleTabs(
                          names: [
                            dic['dex.title']!,
                            dic['dex.lp']!,
                            dic['boot.title']!
                          ],
                          activeTab: _tab,
                          onTab: (i) {
                            if (i != _tab) {
                              setState(() {
                                _tab = i;
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.fromLTRB(0, 8, 8, 8),
                        icon: Icon(Icons.history,
                            color: Theme.of(context).cardColor),
                        onPressed: enabled
                            ? () => Navigator.of(context)
                                .pushNamed(SwapHistoryPage.route)
                            : null,
                      ),
                    ],
                  ),
                ),
                _loading
                    ? SwapSkeleton()
                    : Expanded(
                        child: _tab == 0
                            ? SwapForm(widget.plugin, widget.keyring, enabled)
                            : _tab == 1
                                ? DexPoolList(widget.plugin, widget.keyring)
                                : BootstrapList(widget.plugin, widget.keyring),
                      )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SwapSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      margin: EdgeInsets.fromLTRB(8, 16, 8, 16),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [0, 1].map((e) {
          return Container(
            margin: EdgeInsets.only(bottom: 48),
            decoration: BoxDecoration(
                border: Border.all(
                    width: 0.5, color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.all(Radius.circular(16))),
            child: SkeletonLoader(
              builder: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: <Widget>[
                        Container(width: 80, height: 14, color: Colors.white),
                        Expanded(
                          child: SizedBox(height: 14),
                        ),
                        Container(width: 104, height: 14, color: Colors.white),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Container(width: 104, height: 24, color: Colors.white),
                        Expanded(
                          child: SizedBox(height: 14),
                        ),
                        CircleAvatar(
                          radius: 12,
                        ),
                        Container(
                            margin: EdgeInsets.only(left: 8),
                            width: 72,
                            height: 24,
                            color: Colors.white),
                      ],
                    )
                  ],
                ),
              ),
              items: 1,
              period: Duration(seconds: 2),
              highlightColor: Color(0xFFC0C0C0),
              baseColor: Color(0xFFE0E0E0),
              direction: SkeletonDirection.ltr,
            ),
          );
        }).toList(),
      ),
    );
  }
}
