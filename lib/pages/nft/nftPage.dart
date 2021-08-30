import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';

class NFTPage extends StatefulWidget {
  NFTPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/nft';

  @override
  _NFTPageState createState() => _NFTPageState();
}

class _NFTPageState extends State<NFTPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  Future<void> _queryNFTs() async {
    final nft = await widget.plugin.api.assets
        .queryNFTs(widget.keyring.current.address);
    if (nft != null) {
      widget.plugin.store.assets.setNFTs(nft);
    }
  }

  Future<void> _onBurn() async {
    //
  }

  Future<void> _onTransfer() async {
    //
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    return Scaffold(
      appBar: AppBar(title: Text('NFTs'), centerTitle: true),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final classes = {};
            final list = widget.plugin.store.assets.nft;
            list.forEach((e) {
              if (classes.keys.toList().indexOf(e.classId) < 0) {
                classes[e.classId] = 1;
              } else {
                classes[e.classId] = classes[e.classId] + 1;
              }
            });
            final classKeys = classes.keys.toList();
            return RefreshIndicator(
              key: _refreshKey,
              onRefresh: _queryNFTs,
              child: ListView.builder(
                itemCount: classKeys.length + 1,
                padding: EdgeInsets.all(16),
                itemBuilder: (_, i) {
                  if (i == classes.length) {
                    return ListTail(
                        isLoading: false, isEmpty: list.length == 0);
                  }
                  final item =
                      list.firstWhere((e) => e.classId == classKeys[i]);
                  return RoundedCard(
                    margin: EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Column(
                        children: [
                          Image.network(
                              '${item.metadata['imageServiceUrl']}?imageView2/2/w/400'),
                          Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Text(item.metadata['name']),
                                ),
                                TapTooltip(
                                  message:
                                      '\n${item.metadata['description']}\n',
                                  child: Icon(
                                    Icons.info,
                                    color:
                                        Theme.of(context).unselectedWidgetColor,
                                    size: 16,
                                  ),
                                ),
                                Expanded(child: Container()),
                                Text(
                                  'x ${classes[item.classId]}',
                                  style: Theme.of(context).textTheme.headline4,
                                )
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: OutlinedButtonSmall(
                                    content: dic['nft.burn'],
                                    active: false,
                                    padding: EdgeInsets.only(top: 8, bottom: 8),
                                    onPressed: _onBurn,
                                  ),
                                ),
                                Expanded(
                                  child: OutlinedButtonSmall(
                                    content: dic['nft.transfer'],
                                    active: true,
                                    padding: EdgeInsets.only(top: 8, bottom: 8),
                                    margin: EdgeInsets.only(left: 8),
                                    onPressed: _onTransfer,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
