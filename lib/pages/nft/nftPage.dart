import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/nftData.dart';
import 'package:polkawallet_plugin_karura/pages/nft/nftBurnPage.dart';
import 'package:polkawallet_plugin_karura/pages/nft/nftTransferPage.dart';
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

const nft_filter_name_all = 'All';

class _NFTPageState extends State<NFTPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final List<String> filtersAll = [
    nft_filter_name_all,
    'Transferable',
    'Burnable',
    'Mintable',
    'ClassPropertiesMutable',
  ];
  List<String> _filters = [nft_filter_name_all];

  Future<void> _queryNFTs() async {
    final nft = await widget.plugin.api.assets
        .queryNFTs(widget.keyring.current.address);
    if (nft != null) {
      widget.plugin.store.assets.setNFTs(nft);
    }
  }

  Future<void> _onBurn(NFTData item) async {
    final res = await Navigator.of(context)
        .pushNamed(NFTBurnPage.route, arguments: item);
    if (res != null) {
      _refreshKey.currentState.show();
    }
  }

  Future<void> _onTransfer(NFTData item) async {
    final res = await Navigator.of(context)
        .pushNamed(NFTTransferPage.route, arguments: item);
    if (res != null) {
      _refreshKey.currentState.show();
    }
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
            final list = widget.plugin.store.assets.nft.toList();
            if (_filters.length > 0 &&
                !_filters.contains(nft_filter_name_all)) {
              list.retainWhere((e) => !_filters
                  .map((prop) => e.properties.contains(prop))
                  .contains(false));
            }

            list.forEach((e) {
              if (classes.keys.toList().indexOf(e.classId) < 0) {
                classes[e.classId] = 1;
              } else {
                classes[e.classId] = classes[e.classId] + 1;
              }
            });
            final classKeys = classes.keys.toList();
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16.0,
                        spreadRadius: 4.0,
                        offset: Offset(2.0, 2.0),
                      )
                    ],
                  ),
                  child: Wrap(
                    children: filtersAll.map((e) {
                      return OutlinedButtonSmall(
                        content: dic['nft.$e'],
                        active: _filters.contains(e),
                        padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                        margin: EdgeInsets.only(top: 8, right: 8),
                        onPressed: () async {
                          setState(() {
                            if (e == nft_filter_name_all) {
                              _filters = [nft_filter_name_all];
                            } else {
                              final old = _filters.toList();
                              if (old.contains(nft_filter_name_all)) {
                                old.remove(nft_filter_name_all);
                              }
                              if (_filters.contains(e)) {
                                old.remove(e);
                              } else {
                                old.add(e);
                              }
                              if (old.length == 0) {
                                old.add(nft_filter_name_all);
                              }
                              _filters = old;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
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
                        final burnable = item.properties.contains('Burnable');
                        final transferable =
                            item.properties.contains('Transferable');
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
                                      Expanded(
                                        flex: 0,
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 4),
                                          child: Text(
                                            item.metadata['name'],
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                      TapTooltip(
                                        message:
                                            '\n${item.metadata['description']}\n',
                                        child: Icon(
                                          Icons.info,
                                          color: Theme.of(context)
                                              .unselectedWidgetColor,
                                          size: 16,
                                        ),
                                      ),
                                      Expanded(child: Container()),
                                      Text(
                                        'x ${classes[item.classId]}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4,
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.only(left: 16, right: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.properties
                                              .map((e) => dic['nft.$e'])
                                              .join(', '),
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Theme.of(context)
                                                  .unselectedWidgetColor),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                burnable || transferable
                                    ? Container(
                                        padding: EdgeInsets.all(16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: item.properties
                                                      .contains('Burnable')
                                                  ? OutlinedButtonSmall(
                                                      content: dic['nft.burn'],
                                                      active: false,
                                                      padding: EdgeInsets.only(
                                                          top: 8, bottom: 8),
                                                      onPressed: () =>
                                                          _onBurn(item),
                                                    )
                                                  : Container(),
                                            ),
                                            Expanded(
                                              child: item.properties
                                                      .contains('Transferable')
                                                  ? OutlinedButtonSmall(
                                                      content:
                                                          dic['nft.transfer'],
                                                      active: true,
                                                      padding: EdgeInsets.only(
                                                          top: 8, bottom: 8),
                                                      margin: EdgeInsets.only(
                                                          left: 8),
                                                      onPressed: () =>
                                                          _onTransfer(item),
                                                    )
                                                  : Container(),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        padding: EdgeInsets.only(bottom: 16))
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
