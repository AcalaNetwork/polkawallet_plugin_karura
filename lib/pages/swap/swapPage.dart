import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/pages/swap/bootstrapList.dart';
import 'package:polkawallet_plugin_karura/pages/swap/dexPoolList.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapForm.dart';
import 'package:polkawallet_plugin_karura/pages/swap/swapHistoryPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/pageTitleTaps.dart';

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
    await widget.plugin.service.earn.getDexPools();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateData();
    });
  }

  @override
  Widget build(_) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final isKar = widget.plugin.basic.name == plugin_name_karura;
    // todo: fix this after new acala online
    final bool enabled = widget.plugin.basic.name == 'acala'
        ? ModalRoute.of(context).settings.arguments
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
                Theme.of(context).canvasColor
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
                          names: isKar
                              ? [
                                  dic['dex.title'],
                                  dic['dex.lp'],
                                  dic['boot.title']
                                ]
                              : [dic['dex.title']],
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
                      Visibility(
                          visible: isKar,
                          child: IconButton(
                            padding: EdgeInsets.fromLTRB(0, 8, 8, 8),
                            icon: Icon(Icons.history,
                                color: Theme.of(context).cardColor),
                            onPressed: enabled
                                ? () => Navigator.of(context)
                                    .pushNamed(SwapHistoryPage.route)
                                : null,
                          )),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CupertinoActivityIndicator(),
                        )
                      // todo: enable bootstrap for aca while new aca online
                      : !isKar || _tab == 0
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
