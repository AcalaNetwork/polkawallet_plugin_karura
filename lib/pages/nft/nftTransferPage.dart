import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_karura/api/types/nftData.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressInputField.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class NFTTransferPage extends StatefulWidget {
  NFTTransferPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static const String route = '/karura/nft/transfer';

  @override
  _NFTTransferPageState createState() => _NFTTransferPageState();
}

class _NFTTransferPageState extends State<NFTTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = new TextEditingController();

  KeyPairData _accountTo;

  Future<void> _onScan() async {
    final to = await Navigator.of(context).pushNamed(ScanPage.route);
    if (to == null) return;
    final acc = KeyPairData();
    acc.address = (to as QRCodeResult).address.address;
    acc.name = (to as QRCodeResult).address.name;
    final res =
        await widget.plugin.sdk.api.account.getAddressIcons([acc.address]);
    if (res != null) {
      acc.icon = res[0][1];
    }
    setState(() {
      _accountTo = acc;
    });
    print(_accountTo.address);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.keyring.allWithContacts.length > 0) {
        setState(() {
          _accountTo = widget.keyring.allWithContacts[0];
        });
      }
    });
  }

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
        title: Text('NFT ${dic['nft.transfer']}'),
        centerTitle: true,
        leading: BackBtn(),
        actions: [
          IconButton(
            padding: EdgeInsets.only(right: 8),
            icon: SvgPicture.asset(
              'assets/images/scan.svg',
              color: Theme.of(context).cardColor,
              width: 28,
            ),
            onPressed: _onScan,
          )
        ],
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
                        margin: EdgeInsets.only(top: 4, bottom: 16),
                        child: NFTFormItem(item),
                      ),
                      AddressInputField(
                        widget.plugin.sdk.api,
                        widget.keyring.allWithContacts,
                        label: dicCommon['address'],
                        initialValue: _accountTo,
                        onChanged: (acc) {
                          setState(() {
                            _accountTo = acc;
                          });
                        },
                      ),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: dic['nft.quantity'],
                            labelText:
                                '${dic['nft.quantity']} (${dicCommon['amount.transferable']}: ${list.length})',
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
                                'api.tx.nft.transfer("${_accountTo.address}", [${e.classId}, ${e.tokenId}])')
                            .toList();
                        return TxConfirmParams(
                          module: 'utility',
                          call: 'batch',
                          txTitle: 'NFT ${dic['nft.transfer']}',
                          txDisplay: {
                            'call': 'nft.transfer',
                            'to': Fmt.address(_accountTo.address),
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

class NFTFormItem extends StatelessWidget {
  NFTFormItem(this.item);
  final NFTData item;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black38),
        borderRadius: const BorderRadius.all(const Radius.circular(6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 64,
              child: Image.network(
                  '${item.metadata['imageServiceUrl']}?imageView2/2/w/400'),
            ),
            Expanded(
              flex: 0,
              child: Container(
                margin: EdgeInsets.only(right: 8),
                child: Text(
                  item.metadata['name'],
                  style: TextStyle(fontSize: 14),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
