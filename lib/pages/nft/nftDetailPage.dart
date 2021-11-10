import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/nftData.dart';
import 'package:polkawallet_plugin_karura/pages/nft/nftBurnPage.dart';
import 'package:polkawallet_plugin_karura/pages/nft/nftTransferPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/utils/format.dart';

class NFTDetailPage extends StatefulWidget {
  NFTDetailPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/nft/detail';

  @override
  _NFTDetailPageState createState() => _NFTDetailPageState();
}

class _NFTDetailPageState extends State<NFTDetailPage> {
  Future<void> _onBurn(NFTData item) async {
    final res = await Navigator.of(context)
        .pushNamed(NFTBurnPage.route, arguments: item);
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  Future<void> _onTransfer(NFTData item) async {
    final res = await Navigator.of(context)
        .pushNamed(NFTTransferPage.route, arguments: item);
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final NFTData item = ModalRoute.of(context).settings.arguments;
    final symbol = widget.plugin.networkState.tokenSymbol[0];
    final decimal = widget.plugin.networkState.tokenDecimals[0];

    final deposit = Fmt.balance(item.deposit, decimal);
    return Scaffold(
      appBar: AppBar(title: Text(item.metadata['name']), centerTitle: true),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final list = widget.plugin.store.assets.nft.toList();
            list.retainWhere((e) => e.classId == item.classId);

            final burnable = item.properties.contains('Burnable');
            final transferable = item.properties.contains('Transferable');
            final isMintable = item.properties.contains('Mintable');
            final allProps = item.properties.toList();
            allProps.remove('ClassPropertiesMutable');
            if (!isMintable) {
              allProps.add('Unmintable');
            }
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      RoundedCard(
                        margin: EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Column(
                            children: [
                              Image.network(
                                  '${item.metadata['imageServiceUrl']}?imageView2/2/w/500'),
                              Container(
                                padding: EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.start,
                                      children: allProps
                                          .map((e) => TextTag(
                                                dic['nft.$e'],
                                                color: Theme.of(context)
                                                    .disabledColor,
                                                fontSize: 10,
                                              ))
                                          .toList(),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: NftInfoItem(dic['nft.name'],
                                          item.metadata['name']),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: NftInfoItem(dic['nft.description'],
                                          item.metadata['description']),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: NftInfoItem(dic['nft.deposit'],
                                          '$deposit $symbol'),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: NftInfoItem(
                                          dic['nft.class'], item.classId),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: NftInfoItem(dic['nft.quantity'],
                                          list.length.toString()),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                burnable || transferable
                    ? Container(
                        color: Theme.of(context).cardColor,
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Expanded(
                            //   child: Visibility(
                            //       visible: burnable,
                            //       child: OutlinedButtonSmall(
                            //         content: dic['nft.burn'],
                            //         active: false,
                            //         padding: EdgeInsets.only(top: 8, bottom: 8),
                            //         onPressed:
                            //             false ? () => _onBurn(item) : null,
                            //       )),
                            // ),
                            Expanded(
                              child: Visibility(
                                  visible: transferable,
                                  child: OutlinedButtonSmall(
                                    content: dic['nft.transfer'],
                                    active: true,
                                    padding: EdgeInsets.only(top: 8, bottom: 8),
                                    margin: EdgeInsets.only(left: 8),
                                    onPressed: () => _onTransfer(item),
                                  )),
                            ),
                          ],
                        ),
                      )
                    : Container(padding: EdgeInsets.only(bottom: 16))
              ],
            );
          },
        ),
      ),
    );
  }
}

class NftInfoItem extends StatelessWidget {
  NftInfoItem(this.label, this.content);
  final String label;
  final String content;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 0,
          child: Container(
            padding: EdgeInsets.only(right: 8),
            child: Text(label, style: TextStyle(fontSize: 12)),
          ),
        ),
        Expanded(
          child: Text(
            content,
            textAlign: TextAlign.end,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).unselectedWidgetColor),
          ),
        )
      ],
    );
  }
}
