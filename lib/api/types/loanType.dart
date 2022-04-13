import 'dart:math';

import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/assets.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/utils/format.dart';

class LoanType extends _LoanType {
  static LoanType fromJson(Map<String, dynamic> json, PluginKarura plugin) {
    LoanType data = LoanType();
    data.token = AssetsUtils.tokenDataFromCurrencyId(plugin, json['currency']);
    data.debitExchangeRate = BigInt.parse(json['debitExchangeRate'].toString());
    data.liquidationPenalty =
        BigInt.parse(json['liquidationPenalty'].toString());
    data.liquidationRatio = BigInt.parse(json['liquidationRatio'].toString());
    data.requiredCollateralRatio =
        BigInt.parse((json['requiredCollateralRatio'] ?? 0).toString());
    data.interestRatePerSec =
        BigInt.parse((json['interestRatePerSec'] ?? 0).toString());
    data.globalInterestRatePerSec = json['globalInterestRatePerSec'] == null
        ? null
        : BigInt.parse(json['globalInterestRatePerSec'].toString());
    data.maximumTotalDebitValue =
        BigInt.parse(json['maximumTotalDebitValue'].toString());
    data.minimumDebitValue = BigInt.parse(json['minimumDebitValue'].toString());
    data.expectedBlockTime = int.parse(json['expectedBlockTime'] ?? '0');
    return data;
  }

  BigInt debitShareToDebit(BigInt debitShares) {
    return debitShares *
        debitExchangeRate ~/
        BigInt.from(pow(10, acala_price_decimals));
  }

  BigInt debitToDebitShare(BigInt debits) {
    return debits *
        BigInt.from(pow(10, acala_price_decimals)) ~/
        debitExchangeRate;
  }

  BigInt tokenToUSD(BigInt amount, price,
      {required int stableCoinDecimals, required int collateralDecimals}) {
    return amount *
        price ~/
        BigInt.from(pow(10,
            acala_price_decimals + collateralDecimals - stableCoinDecimals));
  }

  double calcCollateralRatio(BigInt debitInUSD, BigInt collateralInUSD) {
    if (debitInUSD + BigInt.two < minimumDebitValue) {
      return double.minPositive;
    }
    return collateralInUSD / debitInUSD;
  }

  BigInt calcLiquidationPrice(BigInt debit, BigInt collaterals,
      {int? stableCoinDecimals, int? collateralDecimals}) {
    return debit > BigInt.zero && collaterals > BigInt.zero
        ? BigInt.from(debit *
            this.liquidationRatio /
            collaterals /
            pow(10, stableCoinDecimals! - collateralDecimals!))
        : BigInt.zero;
  }

  BigInt calcRequiredCollateral(BigInt debitInUSD, BigInt price,
      {int? stableCoinDecimals, int? collateralDecimals}) {
    if (price > BigInt.zero && debitInUSD > BigInt.zero) {
      return BigInt.from(debitInUSD *
          requiredCollateralRatio /
          price /
          pow(10, stableCoinDecimals! - collateralDecimals!));
    }
    return BigInt.zero;
  }

  BigInt calcMaxToBorrow(BigInt collaterals, tokenPrice,
      {int? stableCoinDecimals, int? collateralDecimals}) {
    return requiredCollateralRatio > BigInt.zero
        ? tokenToUSD(collaterals, tokenPrice,
                stableCoinDecimals: stableCoinDecimals ?? 0,
                collateralDecimals: collateralDecimals ?? 0) *
            BigInt.from(pow(10, acala_price_decimals)) ~/
            requiredCollateralRatio
        : BigInt.zero;
  }
}

abstract class _LoanType {
  TokenBalanceData? token;
  BigInt debitExchangeRate = BigInt.zero;
  BigInt liquidationPenalty = BigInt.zero;
  BigInt liquidationRatio = BigInt.zero;
  BigInt requiredCollateralRatio = BigInt.zero;
  BigInt interestRatePerSec = BigInt.zero;
  BigInt? globalInterestRatePerSec = BigInt.zero;
  BigInt maximumTotalDebitValue = BigInt.zero;
  BigInt minimumDebitValue = BigInt.zero;
  int expectedBlockTime = 0;
}

class LoanData extends _LoanData {
  static LoanData fromJson(Map<String, dynamic> json, LoanType type,
      BigInt tokenPrice, PluginKarura plugin) {
    LoanData data = LoanData();
    data.token = AssetsUtils.tokenDataFromCurrencyId(plugin, json['currency']);
    final stableCoinDecimals =
        plugin.store!.assets.tokenBalanceMap[karura_stable_coin]!.decimals!;
    final collateralDecimals = data.token!.decimals!;
    data.type = type;
    data.price = tokenPrice;
    data.stableCoinPrice = Fmt.tokenInt('1', stableCoinDecimals);
    data.debitShares = BigInt.parse(json['debit'].toString());
    data.debits = type.debitShareToDebit(data.debitShares);
    data.collaterals = BigInt.parse(json['collateral'].toString());

    data.debitInUSD = data.debits;
    data.collateralInUSD = type.tokenToUSD(data.collaterals, tokenPrice,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    data.collateralRatio =
        type.calcCollateralRatio(data.debitInUSD, data.collateralInUSD);

    data.requiredCollateral = type.calcRequiredCollateral(
        data.debitInUSD, tokenPrice,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    data.maxToBorrow = type.calcMaxToBorrow(data.collaterals, tokenPrice,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    data.stableFeeYear = data.calcStableFee(SECONDS_OF_YEAR);
    data.liquidationPrice = type.calcLiquidationPrice(
        data.debitInUSD, data.collaterals,
        stableCoinDecimals: stableCoinDecimals,
        collateralDecimals: collateralDecimals);
    return data;
  }

  LoanData deepCopy() {
    LoanData data = LoanData();
    data.token = this.token;
    data.type = this.type;
    data.price = this.price;
    data.stableCoinPrice = this.stableCoinPrice;
    data.debitShares = this.debitShares;
    data.debits = this.debits;
    data.collaterals = this.collaterals;
    data.debitInUSD = this.debitInUSD;
    data.collateralInUSD = this.collateralInUSD;
    data.collateralRatio = this.collateralRatio;
    data.requiredCollateral = this.requiredCollateral;
    data.maxToBorrow = this.maxToBorrow;
    data.stableCoinPrice = this.stableCoinPrice;
    data.liquidationPrice = this.liquidationPrice;
    data.stableFeeYear = this.stableFeeYear;
    return data;
  }
}

abstract class _LoanData {
  TokenBalanceData? token;
  LoanType type = LoanType();
  BigInt price = BigInt.zero;
  BigInt stableCoinPrice = BigInt.zero;
  BigInt debitShares = BigInt.zero;
  BigInt debits = BigInt.zero;
  BigInt collaterals = BigInt.zero;

  // computed properties
  BigInt debitInUSD = BigInt.zero;
  BigInt collateralInUSD = BigInt.zero;
  double collateralRatio = 0;
  BigInt requiredCollateral = BigInt.zero;
  BigInt maxToBorrow = BigInt.zero;
  double stableFeeYear = 0;
  BigInt liquidationPrice = BigInt.zero;

  double calcStableFee(int seconds) {
    final base = (type.globalInterestRatePerSec! + type.interestRatePerSec) /
        BigInt.from(pow(10, acala_price_decimals));
    return pow((1 + base), seconds) - 1;
  }
}

class CollateralIncentiveData extends _CollateralIncentiveData {
  static CollateralIncentiveData fromJson(List json, PluginKarura plugin) {
    final data = CollateralIncentiveData();
    data.token = AssetsUtils.tokenDataFromCurrencyId(
        plugin, json[0][0]['LoansIncentive']);
    data.incentive = Fmt.balanceInt(json[1].toString());
    return data;
  }
}

abstract class _CollateralIncentiveData {
  TokenBalanceData? token;
  BigInt? incentive;
}

class TotalCDPData extends _TotalCDPData {
  static TotalCDPData fromJson(Map json) {
    final data = TotalCDPData();
    data.tokenNameId = json['tokenNameId'];
    data.collateral = Fmt.balanceInt(json['collateral'].toString());
    data.debit = Fmt.balanceInt(json['debit'].toString());
    return data;
  }
}

abstract class _TotalCDPData {
  String? tokenNameId;
  late BigInt collateral;
  BigInt? debit;
}

class CollateralRewardData extends _CollateralRewardData {
  static CollateralRewardData fromJson(Map json) {
    final data = CollateralRewardData();
    data.tokenNameId = json['tokenNameId'];
    data.sharesTotal = Fmt.balanceInt(json['sharesTotal'].toString());
    data.shares = Fmt.balanceInt(json['shares'].toString());
    data.proportion = double.parse(json['proportion'].toString());
    data.reward = json['reward'];
    return data;
  }
}

abstract class _CollateralRewardData {
  String? tokenNameId;
  BigInt? sharesTotal;
  BigInt? shares;
  List? reward;
  double? proportion;
}
