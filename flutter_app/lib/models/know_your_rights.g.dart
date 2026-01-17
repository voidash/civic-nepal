// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'know_your_rights.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BilingualTextImpl _$$BilingualTextImplFromJson(Map<String, dynamic> json) =>
    _$BilingualTextImpl(
      en: json['en'] as String,
      np: json['np'] as String,
    );

Map<String, dynamic> _$$BilingualTextImplToJson(_$BilingualTextImpl instance) =>
    <String, dynamic>{
      'en': instance.en,
      'np': instance.np,
    };

_$ArticleReferenceImpl _$$ArticleReferenceImplFromJson(
        Map<String, dynamic> json) =>
    _$ArticleReferenceImpl(
      partIndex: (json['partIndex'] as num).toInt(),
      articleIndex: (json['articleIndex'] as num).toInt(),
      articleNumber: json['articleNumber'] as String,
      articleTitle:
          BilingualText.fromJson(json['articleTitle'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ArticleReferenceImplToJson(
        _$ArticleReferenceImpl instance) =>
    <String, dynamic>{
      'partIndex': instance.partIndex,
      'articleIndex': instance.articleIndex,
      'articleNumber': instance.articleNumber,
      'articleTitle': instance.articleTitle,
    };

_$RightItemImpl _$$RightItemImplFromJson(Map<String, dynamic> json) =>
    _$RightItemImpl(
      situation:
          BilingualText.fromJson(json['situation'] as Map<String, dynamic>),
      yourRight:
          BilingualText.fromJson(json['yourRight'] as Map<String, dynamic>),
      articleRef:
          ArticleReference.fromJson(json['articleRef'] as Map<String, dynamic>),
      tip: BilingualText.fromJson(json['tip'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$RightItemImplToJson(_$RightItemImpl instance) =>
    <String, dynamic>{
      'situation': instance.situation,
      'yourRight': instance.yourRight,
      'articleRef': instance.articleRef,
      'tip': instance.tip,
    };

_$RightsCategoryImpl _$$RightsCategoryImplFromJson(Map<String, dynamic> json) =>
    _$RightsCategoryImpl(
      id: json['id'] as String,
      icon: json['icon'] as String,
      title: BilingualText.fromJson(json['title'] as Map<String, dynamic>),
      subtitle:
          BilingualText.fromJson(json['subtitle'] as Map<String, dynamic>),
      rights: (json['rights'] as List<dynamic>)
          .map((e) => RightItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$RightsCategoryImplToJson(
        _$RightsCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'icon': instance.icon,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'rights': instance.rights,
    };

_$KnowYourRightsDataImpl _$$KnowYourRightsDataImplFromJson(
        Map<String, dynamic> json) =>
    _$KnowYourRightsDataImpl(
      disclaimer:
          BilingualText.fromJson(json['disclaimer'] as Map<String, dynamic>),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => RightsCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$KnowYourRightsDataImplToJson(
        _$KnowYourRightsDataImpl instance) =>
    <String, dynamic>{
      'disclaimer': instance.disclaimer,
      'categories': instance.categories,
    };
