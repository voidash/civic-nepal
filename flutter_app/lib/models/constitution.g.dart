// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'constitution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConstitutionWrapperImpl _$$ConstitutionWrapperImplFromJson(
        Map<String, dynamic> json) =>
    _$ConstitutionWrapperImpl(
      constitution: ConstitutionData.fromJson(
          json['constitution'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ConstitutionWrapperImplToJson(
        _$ConstitutionWrapperImpl instance) =>
    <String, dynamic>{
      'constitution': instance.constitution,
    };

_$ConstitutionDataImpl _$$ConstitutionDataImplFromJson(
        Map<String, dynamic> json) =>
    _$ConstitutionDataImpl(
      title: ConstitutionTitle.fromJson(json['title'] as Map<String, dynamic>),
      publicationDate: json['publicationDate'] as String,
      preamble: Preamble.fromJson(json['preamble'] as Map<String, dynamic>),
      parts: (json['parts'] as List<dynamic>)
          .map((e) => Part.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ConstitutionDataImplToJson(
        _$ConstitutionDataImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'publicationDate': instance.publicationDate,
      'preamble': instance.preamble,
      'parts': instance.parts,
    };

_$ConstitutionTitleImpl _$$ConstitutionTitleImplFromJson(
        Map<String, dynamic> json) =>
    _$ConstitutionTitleImpl(
      en: json['en'] as String,
      np: json['np'] as String,
    );

Map<String, dynamic> _$$ConstitutionTitleImplToJson(
        _$ConstitutionTitleImpl instance) =>
    <String, dynamic>{
      'en': instance.en,
      'np': instance.np,
    };

_$PreambleImpl _$$PreambleImplFromJson(Map<String, dynamic> json) =>
    _$PreambleImpl(
      en: json['en'] as String,
      np: json['np'] as String,
    );

Map<String, dynamic> _$$PreambleImplToJson(_$PreambleImpl instance) =>
    <String, dynamic>{
      'en': instance.en,
      'np': instance.np,
    };

_$PartImpl _$$PartImplFromJson(Map<String, dynamic> json) => _$PartImpl(
      number: (json['number'] as num).toInt(),
      title: PartTitle.fromJson(json['title'] as Map<String, dynamic>),
      articles: (json['articles'] as List<dynamic>)
          .map((e) => Article.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PartImplToJson(_$PartImpl instance) =>
    <String, dynamic>{
      'number': instance.number,
      'title': instance.title,
      'articles': instance.articles,
    };

_$PartTitleImpl _$$PartTitleImplFromJson(Map<String, dynamic> json) =>
    _$PartTitleImpl(
      en: json['en'] as String,
      np: json['np'] as String,
    );

Map<String, dynamic> _$$PartTitleImplToJson(_$PartTitleImpl instance) =>
    <String, dynamic>{
      'en': instance.en,
      'np': instance.np,
    };

_$ArticleImpl _$$ArticleImplFromJson(Map<String, dynamic> json) =>
    _$ArticleImpl(
      number: json['number'] as String,
      title: ArticleTitle.fromJson(json['title'] as Map<String, dynamic>),
      content: ArticleContent.fromJson(json['content'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ArticleImplToJson(_$ArticleImpl instance) =>
    <String, dynamic>{
      'number': instance.number,
      'title': instance.title,
      'content': instance.content,
    };

_$ArticleTitleImpl _$$ArticleTitleImplFromJson(Map<String, dynamic> json) =>
    _$ArticleTitleImpl(
      en: json['en'] as String?,
      np: json['np'] as String?,
    );

Map<String, dynamic> _$$ArticleTitleImplToJson(_$ArticleTitleImpl instance) =>
    <String, dynamic>{
      'en': instance.en,
      'np': instance.np,
    };

_$ArticleContentImpl _$$ArticleContentImplFromJson(Map<String, dynamic> json) =>
    _$ArticleContentImpl(
      en: (json['en'] as List<dynamic>)
          .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      np: (json['np'] as List<dynamic>)
          .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ArticleContentImplToJson(
        _$ArticleContentImpl instance) =>
    <String, dynamic>{
      'en': instance.en,
      'np': instance.np,
    };

_$ContentItemImpl _$$ContentItemImplFromJson(Map<String, dynamic> json) =>
    _$ContentItemImpl(
      type: json['type'] as String,
      identifier: json['identifier'] as String?,
      text: json['text'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ContentItemImplToJson(_$ContentItemImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'identifier': instance.identifier,
      'text': instance.text,
      'items': instance.items,
    };

_$AlignedSentenceImpl _$$AlignedSentenceImplFromJson(
        Map<String, dynamic> json) =>
    _$AlignedSentenceImpl(
      np: json['np'] as String,
      en: json['en'] as String,
    );

Map<String, dynamic> _$$AlignedSentenceImplToJson(
        _$AlignedSentenceImpl instance) =>
    <String, dynamic>{
      'np': instance.np,
      'en': instance.en,
    };
