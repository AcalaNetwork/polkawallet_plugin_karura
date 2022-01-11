import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:polkawallet_plugin_karura/api/types/transferData.dart';
import 'package:polkawallet_plugin_karura/common/constants/subQuery.dart';
import 'package:polkawallet_plugin_karura/pages/assets/transferDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/assets/transferPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/borderedTitle.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TokenDetailPage extends StatefulWidget {
  TokenDetailPage(this.plugin, this.keyring);
  final PluginKarura plugin;
  final Keyring keyring;

  static final String route = '/assets/token/detail';

  @override
  _TokenDetailPageSate createState() => _TokenDetailPageSate();
}

class _TokenDetailPageSate extends State<TokenDetailPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final colorIn = Color(0xFF62CFE4);
  final colorOut = Color(0xFF3394FF);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final TokenBalanceData token =
          ModalRoute.of(context)!.settings.arguments as TokenBalanceData;
      widget.plugin.service!.assets.updateTokenBalances(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');

    final TokenBalanceData token =
        ModalRoute.of(context)!.settings.arguments as TokenBalanceData;

    final primaryColor = Theme.of(context).primaryColor;
    final titleColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
          title: Text(token.symbol!),
          centerTitle: true,
          elevation: 0.0,
          leading: BackBtn()),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final tokenSymbol = token.symbol?.toUpperCase();
            final balance =
                widget.plugin.store!.assets.tokenBalanceMap[token.tokenNameId];
            final free = Fmt.balanceInt(balance?.amount ?? '0');
            final locked = Fmt.balanceInt(balance?.locked ?? '0');
            final reserved = Fmt.balanceInt(balance?.reserved ?? '0');
            final transferable = free - locked;
            final total = free + reserved;

            final tokenPrice =
                widget.plugin.store!.assets.marketPrices[tokenSymbol];
            final tokenValue = (tokenPrice ?? 0) > 0
                ? tokenPrice! * Fmt.bigIntToDouble(total, balance!.decimals!)
                : 0;

            final disabledTokens =
                widget.plugin.store!.setting.tokensConfig['disabled'];
            bool transferDisabled = false;
            if (disabledTokens != null) {
              transferDisabled = List.of(disabledTokens).contains(tokenSymbol);
            }
            return RefreshIndicator(
              key: _refreshKey,
              onRefresh: () =>
                  widget.plugin.service!.assets.updateTokenBalances(token),
              child: Column(
                children: <Widget>[
                  Stack(
                    alignment: AlignmentDirectional.bottomCenter,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.center,
                        color: primaryColor,
                        padding: EdgeInsets.only(bottom: 24),
                        margin: EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 40),
                          child: Column(
                            children: [
                              Container(
                                margin: EdgeInsets.only(
                                    bottom: tokenValue > 0 ? 8 : 24),
                                child: Text(
                                  Fmt.token(total, token.decimals!, length: 8),
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Visibility(
                                  visible: tokenValue > 0,
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      tokenValue > 0
                                          ? '≈ \$ ${Fmt.priceFloor(tokenValue as double?)}'
                                          : "",
                                      style: TextStyle(
                                        color: Theme.of(context).cardColor,
                                      ),
                                    ),
                                  )),
                              Row(
                                children: [
                                  InfoItem(
                                      title: dic!['asset.reserve'],
                                      content: Fmt.priceFloorBigInt(
                                          reserved, token.decimals!,
                                          lengthMax: 4),
                                      color: titleColor,
                                      titleColor: titleColor,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center),
                                  InfoItem(
                                      title: dic['asset.transferable'],
                                      content: Fmt.priceFloorBigInt(
                                          transferable, token.decimals!,
                                          lengthMax: 4),
                                      color: titleColor,
                                      titleColor: titleColor,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center),
                                  InfoItem(
                                      title: dic['asset.lock'],
                                      content: Fmt.priceFloorBigInt(
                                          locked, token.decimals!,
                                          lengthMax: 4),
                                      color: titleColor,
                                      titleColor: titleColor,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: titleColor,
                          borderRadius:
                              const BorderRadius.all(const Radius.circular(16)),
                        ),
                        child: Row(
                          children: <Widget>[
                            BorderedTitle(
                              title: I18n.of(context)!.getDic(
                                  i18n_full_dic_karura, 'acala')!['loan.txs'],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      color: titleColor,
                      child: Query(
                          options: QueryOptions(
                            document: gql(transferQuery),
                            variables: <String, String?>{
                              'account': widget.keyring.current.address,
                              'token': token.tokenNameId,
                            },
                          ),
                          builder: (
                            QueryResult result, {
                            Future<QueryResult?> Function()? refetch,
                            FetchMore? fetchMore,
                          }) {
                            if (result.data == null) {
                              return Container(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [CupertinoActivityIndicator()],
                                ),
                              );
                            }
                            final txs =
                                List.of(result.data!['transfers']['nodes'])
                                    .map((i) =>
                                        TransferData.fromJson(i as Map, token))
                                    .toList();
                            return ListView.builder(
                              itemCount: txs.length + 1,
                              itemBuilder: (_, i) {
                                if (i == txs.length) {
                                  return ListTail(
                                      isEmpty: txs.length == 0,
                                      isLoading: false);
                                }
                                return TransferListItem(
                                  data: txs[i],
                                  token: tokenSymbol,
                                  isOut: txs[i].from ==
                                      widget.keyring.current.address,
                                );
                              },
                            );
                          }),
                    ),
                  ),
                  Container(
                    color: titleColor,
                    child: Visibility(
                      visible: !transferDisabled,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.fromLTRB(16, 8, 8, 8),
                              child: RoundedButton(
                                icon: Icon(Icons.qr_code,
                                    color: titleColor, size: 24),
                                text: dic['receive'],
                                color: colorIn,
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, AccountQrCodePage.route);
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
                              child: RoundedButton(
                                icon: SizedBox(
                                  height: 20,
                                  child: Image.asset(
                                      'packages/polkawallet_plugin_karura/assets/images/assets_send.png'),
                                ),
                                text: dic['transfer'],
                                color: colorOut,
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    TransferPage.route,
                                    arguments: token,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class TransferListItem extends StatelessWidget {
  TransferListItem({
    this.data,
    this.token,
    this.isOut,
    this.crossChain,
  });

  final TransferData? data;
  final String? token;
  final String? crossChain;
  final bool? isOut;

  @override
  Widget build(BuildContext context) {
    final address = isOut! ? data!.to : data!.from;
    final title = Fmt.address(address) ?? Fmt.address(data!.hash);
    return ListTile(
      dense: true,
      leading: data!.isSuccess!
          ? isOut!
              ? TransferIcon(
                  type: TransferIconType.rollOut,
                  bgColor: Theme.of(context).cardColor)
              : TransferIcon(
                  type: TransferIconType.rollIn,
                  bgColor: Theme.of(context).cardColor)
          : TransferIcon(
              type: TransferIconType.failure, bgColor: Color(0xFFD7D7D7)),
      title: Text('$title${crossChain != null ? ' ($crossChain)' : ''}'),
      subtitle: Text(Fmt.dateTime(DateTime.parse(data!.timestamp))),
      trailing: Container(
        width: 110,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${isOut! ? '-' : '+'} ${data!.amount}',
                style: Theme.of(context).textTheme.headline5!.copyWith(
                    color: data!.isSuccess!
                        ? Theme.of(context).toggleableActiveColor
                        : Theme.of(context).unselectedWidgetColor,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          TransferDetailPage.route,
          arguments: data,
        );
      },
    );
  }
}
