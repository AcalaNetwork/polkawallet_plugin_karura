import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';

class NFTPage extends StatefulWidget {
  NFTPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/acala/nft';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NFTs'), centerTitle: true),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final list = widget.plugin.store.assets.nft;
            return RefreshIndicator(
              key: _refreshKey,
              onRefresh: _queryNFTs,
              child: ListView.builder(
                itemCount: list.length + 1,
                padding: EdgeInsets.all(16),
                itemBuilder: (_, i) {
                  if (i == list.length) {
                    return ListTail(
                        isLoading: false, isEmpty: list.length == 0);
                  }
                  return RoundedCard(
                    margin: EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Column(
                        children: [
                          Image.network(
                              '${list[i].metadata['imageServiceUrl']}?imageView2/2/w/400'),
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Text(list[i].metadata['name']),
                                ),
                                TapTooltip(
                                  message:
                                      '\n${list[i].metadata['description']}\n',
                                  child: Icon(
                                    Icons.info,
                                    color:
                                        Theme.of(context).unselectedWidgetColor,
                                    size: 16,
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
