// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ipo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IpoImpl _$$IpoImplFromJson(Map<String, dynamic> json) => _$IpoImpl(
      companyName: json['companyName'] as String,
      symbol: json['symbol'] as String,
      issueType: json['issueType'] as String,
      issueManager: json['issueManager'] as String,
      issuedUnits: (json['issuedUnits'] as num).toInt(),
      numberOfApplications: (json['numberOfApplications'] as num).toInt(),
      appliedUnits: (json['appliedUnits'] as num).toInt(),
      amount: (json['amount'] as num).toInt(),
      openDate: DateTime.parse(json['openDate'] as String),
      closeDate: DateTime.parse(json['closeDate'] as String),
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
    );

Map<String, dynamic> _$$IpoImplToJson(_$IpoImpl instance) => <String, dynamic>{
      'companyName': instance.companyName,
      'symbol': instance.symbol,
      'issueType': instance.issueType,
      'issueManager': instance.issueManager,
      'issuedUnits': instance.issuedUnits,
      'numberOfApplications': instance.numberOfApplications,
      'appliedUnits': instance.appliedUnits,
      'amount': instance.amount,
      'openDate': instance.openDate.toIso8601String(),
      'closeDate': instance.closeDate.toIso8601String(),
      'lastUpdate': instance.lastUpdate.toIso8601String(),
    };

_$StockPriceImpl _$$StockPriceImplFromJson(Map<String, dynamic> json) =>
    _$StockPriceImpl(
      symbol: json['symbol'] as String,
      companyName: json['companyName'] as String,
      ltp: (json['ltp'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      volume: (json['volume'] as num).toInt(),
      previousClose: (json['previousClose'] as num).toDouble(),
      sector: json['sector'] as String?,
    );

Map<String, dynamic> _$$StockPriceImplToJson(_$StockPriceImpl instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'companyName': instance.companyName,
      'ltp': instance.ltp,
      'change': instance.change,
      'changePercent': instance.changePercent,
      'open': instance.open,
      'high': instance.high,
      'low': instance.low,
      'volume': instance.volume,
      'previousClose': instance.previousClose,
      'sector': instance.sector,
    };

_$MarketSummaryImpl _$$MarketSummaryImplFromJson(Map<String, dynamic> json) =>
    _$MarketSummaryImpl(
      nepseIndex: (json['nepseIndex'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      turnover: (json['turnover'] as num).toDouble(),
      tradedShares: (json['tradedShares'] as num).toInt(),
      transactions: (json['transactions'] as num).toInt(),
      asOf: DateTime.parse(json['asOf'] as String),
    );

Map<String, dynamic> _$$MarketSummaryImplToJson(_$MarketSummaryImpl instance) =>
    <String, dynamic>{
      'nepseIndex': instance.nepseIndex,
      'change': instance.change,
      'changePercent': instance.changePercent,
      'turnover': instance.turnover,
      'tradedShares': instance.tradedShares,
      'transactions': instance.transactions,
      'asOf': instance.asOf.toIso8601String(),
    };
