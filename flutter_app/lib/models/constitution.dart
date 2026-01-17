import 'package:freezed_annotation/freezed_annotation.dart';

part 'constitution.freezed.dart';
part 'constitution.g.dart';

// Default value annotation for ContentItem.items
const _emptyContentItemList = <ContentItem>[];

/// Root constitution wrapper from JSON
@freezed
class ConstitutionWrapper with _$ConstitutionWrapper {
  const factory ConstitutionWrapper({
    required ConstitutionData constitution,
  }) = _ConstitutionWrapper;

  factory ConstitutionWrapper.fromJson(Map<String, dynamic> json) =>
      _$ConstitutionWrapperFromJson(json);
}

/// Main constitution data
@freezed
class ConstitutionData with _$ConstitutionData {
  const factory ConstitutionData({
    required ConstitutionTitle title,
    required String publicationDate,
    required Preamble preamble,
    required List<Part> parts,
  }) = _ConstitutionData;

  factory ConstitutionData.fromJson(Map<String, dynamic> json) =>
      _$ConstitutionDataFromJson(json);
}

/// Constitution title
@freezed
class ConstitutionTitle with _$ConstitutionTitle {
  const factory ConstitutionTitle({
    required String en,
    required String np,
  }) = _ConstitutionTitle;

  factory ConstitutionTitle.fromJson(Map<String, dynamic> json) =>
      _$ConstitutionTitleFromJson(json);
}

/// Preamble with bilingual text
@freezed
class Preamble with _$Preamble {
  const factory Preamble({
    required String en,
    required String np,
  }) = _Preamble;

  factory Preamble.fromJson(Map<String, dynamic> json) =>
      _$PreambleFromJson(json);
}

/// Part (section) of the constitution
@freezed
class Part with _$Part {
  const factory Part({
    required int number,
    required PartTitle title,
    required List<Article> articles,
  }) = _Part;

  factory Part.fromJson(Map<String, dynamic> json) => _$PartFromJson(json);
}

/// Part title (may have empty strings)
@freezed
class PartTitle with _$PartTitle {
  const factory PartTitle({
    required String en,
    required String np,
  }) = _PartTitle;

  factory PartTitle.fromJson(Map<String, dynamic> json) =>
      _$PartTitleFromJson(json);
}

/// Article within a part
@freezed
class Article with _$Article {
  const factory Article({
    required String number,
    required ArticleTitle title,
    required ArticleContent content,
  }) = _Article;

  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);
}

/// Article title (may have empty strings)
@freezed
class ArticleTitle with _$ArticleTitle {
  const factory ArticleTitle({
    required String? en,
    required String? np,
  }) = _ArticleTitle;

  factory ArticleTitle.fromJson(Map<String, dynamic> json) =>
      _$ArticleTitleFromJson(json);
}

/// Article content with separate language arrays
@freezed
class ArticleContent with _$ArticleContent {
  const factory ArticleContent({
    required List<ContentItem> en,
    required List<ContentItem> np,
  }) = _ArticleContent;

  factory ArticleContent.fromJson(Map<String, dynamic> json) =>
      _$ArticleContentFromJson(json);
}

/// Content item (subsection or text) - can be nested
@freezed
class ContentItem with _$ContentItem {
  const factory ContentItem({
    required String type,
    String? identifier,
    String? text,
    @Default([]) List<ContentItem> items,
  }) = _ContentItem;

  factory ContentItem.fromJson(Map<String, dynamic> json) =>
      _$ContentItemFromJson(json);
}

/// Aligned sentence from per-sentence.json
@freezed
class AlignedSentence with _$AlignedSentence {
  const factory AlignedSentence({
    required String np,
    required String en,
  }) = _AlignedSentence;

  factory AlignedSentence.fromJson(Map<String, dynamic> json) =>
      _$AlignedSentenceFromJson(json);
}
