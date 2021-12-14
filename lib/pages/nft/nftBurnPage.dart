import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_karura/api/types/nftData.dart';
import 'package:polkawallet_plugin_karura/pages/nft/nftTransferPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';

class NFTBurnPage extends StatefulWidget {
  NFTBurnPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/nft/burn';

  @override
  _NFTBurnPageState createState() => _NFTBurnPageState();
}

class _NFTBurnPageState extends State<NFTBurnPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = new TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_karura, 'common');

    final colorGrey = Theme.of(context).unselectedWidgetColor;
    return Scaffold(
      appBar: AppBar(
        title: Text('NFT ${dic['nft.burn']}'),
        centerTitle: true,
        leading: BackBtn(),
      ),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final NFTData item = ModalRoute.of(context).settings.arguments;
            final list = widget.plugin.store.assets.nft.toList();
            list.retainWhere((e) => e.classId == item.classId);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      Text(
                        'NFT',
                        style: TextStyle(fontSize: 12, color: colorGrey),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        child: NFTFormItem(item),
                      ),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: dic['nft.quantity'],
                            labelText:
                                '${dic['nft.quantity']} (${dic['earn.available']}: ${list.length})',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          ],
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: _amountCtrl,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v.isEmpty) {
                              return dicCommon['input.invalid'];
                            }
                            final count = int.parse(v.trim());
                            if (count < 1) {
                              return dicCommon['input.invalid'];
                            }
                            if (count > list.length) {
                              return dicCommon['amount.low'];
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TxButton(
                    getTxParams: () async {
                      if (_formKey.currentState.validate()) {
                        final count = int.parse(_amountCtrl.text.trim());
                        final txs = list
                            .sublist(0, count)
                            .map((e) =>
                                'api.tx.nft.burn([${e.classId}, ${e.tokenId}])')
                            .toList();
                        return TxConfirmParams(
                          module: 'utility',
                          call: 'batch',
                          txTitle: 'NFT ${dic['nft.burn']}',
                          txDisplay: {
                            'call': 'nft.burn',
                            'classId': item.classId,
                            'quantity': _amountCtrl.text.trim(),
                          },
                          params: [],
                          rawParams: '[[${txs.join(',')}]]',
                        );
                      }
                      return null;
                    },
                    onFinish: (res) {
                      if (res != null) {
                        Navigator.of(context).pop(res);
                      }
                    },
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
