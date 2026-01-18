import 'package:freezed_annotation/freezed_annotation.dart';

part 'ipo.freezed.dart';
part 'ipo.g.dart';

/// IPO listing from CDSC
@freezed
class Ipo with _$Ipo {
  const factory Ipo({
    required String companyName,
    required String symbol,
    required String issueType,
    required String issueManager,
    required int issuedUnits,
    required int numberOfApplications,
    required int appliedUnits,
    required int amount,
    required DateTime openDate,
    required DateTime closeDate,
    required DateTime lastUpdate,
  }) = _Ipo;

  factory Ipo.fromJson(Map<String, dynamic> json) => _$IpoFromJson(json);
}

/// Stock price data from NEPSE/Merolagani
@freezed
class StockPrice with _$StockPrice {
  const factory StockPrice({
    required String symbol,
    required String companyName,
    required double ltp,
    required double change,
    required double changePercent,
    required double open,
    required double high,
    required double low,
    required int volume,
    required double previousClose,
    String? sector,
  }) = _StockPrice;

  factory StockPrice.fromJson(Map<String, dynamic> json) => _$StockPriceFromJson(json);
}

/// Market summary data
@freezed
class MarketSummary with _$MarketSummary {
  const factory MarketSummary({
    required double nepseIndex,
    required double change,
    required double changePercent,
    required double turnover,
    required int tradedShares,
    required int transactions,
    required DateTime asOf,
  }) = _MarketSummary;

  factory MarketSummary.fromJson(Map<String, dynamic> json) => _$MarketSummaryFromJson(json);
}
