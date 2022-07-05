import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/LPStakePage.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/addLiquidityPage.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/earnDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/earnHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/earnPage.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/earnTaigaDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/earnTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/inviteFriendsPage.dart';
import 'package:polkawallet_plugin_karura/pages/earnNew/withdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_karura/pages/governanceNew/governancePage.dart';
import 'package:polkawallet_plugin_karura/pages/governanceNew/referendumVotePage.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/completedPage.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/homaHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/homaPage.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/homaTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/mintPage.dart';
import 'package:polkawallet_plugin_karura/pages/homaNew/redeemPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanAdjustPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanCreatePage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanDepositPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanPage.dart';
import 'package:polkawallet_plugin_karura/pages/loanNew/loanTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/multiply/multiplyHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/multiply/multiplyTxDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/nftNew/nftPage.dart';
import 'package:polkawallet_plugin_karura/pages/nftNew/nftTransferPage.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/bootstrapPage.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/swapDetailPage.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/swapHistoryPage.dart';
import 'package:polkawallet_plugin_karura/pages/swapNew/swapPage.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/service/graphql.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

Map<String, WidgetBuilder> getNewUiRoutes(
    PluginKarura plugin, Keyring keyring) {
  /// use new pages in testnet for now.
  final isTest = true;
  return isTest
      ? {
          //homa
          HomaPage.route: (_) => HomaPage(plugin, keyring),
          MintPage.route: (_) => MintPage(plugin, keyring),
          RedeemPage.route: (_) => RedeemPage(plugin, keyring),
          HomaHistoryPage.route: (_) => ClientProvider(
                child: Builder(
                  builder: (_) => HomaHistoryPage(plugin, keyring),
                ),
                uri: GraphQLConfig['httpUri']!,
              ),
          HomaTxDetailPage.route: (_) => HomaTxDetailPage(plugin, keyring),
          CompletedPage.route: (_) => CompletedPage(),

          //loan
          LoanPage.route: (_) => LoanPage(plugin, keyring),
          LoanCreatePage.route: (_) => LoanCreatePage(plugin, keyring),
          LoanHistoryPage.route: (_) => ClientProvider(
                child: Builder(
                  builder: (_) => LoanHistoryPage(plugin, keyring),
                ),
                uri: GraphQLConfig['httpUri']!,
              ),
          LoanDepositPage.route: (_) => LoanDepositPage(plugin, keyring),
          LoanTxDetailPage.route: (_) => LoanTxDetailPage(plugin, keyring),
          LoanAdjustPage.route: (_) => LoanAdjustPage(plugin, keyring),

          //swap
          SwapPage.route: (_) => SwapPage(plugin, keyring),
          SwapHistoryPage.route: (_) => ClientProvider(
                child: Builder(
                  builder: (_) => SwapHistoryPage(plugin, keyring),
                ),
                uri: GraphQLConfig['httpUri']!,
              ),
          BootstrapPage.route: (_) => BootstrapPage(plugin, keyring),
          SwapDetailPage.route: (_) => SwapDetailPage(plugin, keyring),

          //earn
          EarnPage.route: (_) => EarnPage(plugin, keyring),
          AddLiquidityPage.route: (_) => AddLiquidityPage(plugin, keyring),
          WithdrawLiquidityPage.route: (_) =>
              WithdrawLiquidityPage(plugin, keyring),
          EarnHistoryPage.route: (_) => ClientProvider(
                child: Builder(
                  builder: (_) => EarnHistoryPage(plugin, keyring),
                ),
                uri: GraphQLConfig['httpUri']!,
              ),
          EarnDetailPage.route: (_) => ClientProvider(
                child: Builder(
                  builder: (_) => EarnDetailPage(plugin, keyring),
                ),
                uri: GraphQLConfig['httpUri']!,
              ),
          LPStakePage.route: (_) => LPStakePage(plugin, keyring),
          InviteFriendsPage.route: (_) => InviteFriendsPage(plugin, keyring),
          EarnTxDetailPage.route: (_) => EarnTxDetailPage(plugin, keyring),
          EarnTaigaDetailPage.route: (_) =>
              EarnTaigaDetailPage(plugin, keyring),

          //nft
          NftPage.route: (_) => NftPage(plugin, keyring),
          NFTTransferPage.route: (_) => NFTTransferPage(plugin, keyring),

          //governanceNew
          GovernancePage.route: (_) => GovernancePage(plugin, keyring),
          ReferendumVotePage.route: (_) => ReferendumVotePage(plugin, keyring),

          //multiply
          MultiplyHistoryPage.route: (_) => ClientProvider(
                child: Builder(
                  builder: (_) => MultiplyHistoryPage(plugin, keyring),
                ),
                uri: GraphQLConfig['defiUri']!,
              ),
          MultiplyTxDetailPage.route: (_) =>
              MultiplyTxDetailPage(plugin, keyring),
        }
      : {};
}
