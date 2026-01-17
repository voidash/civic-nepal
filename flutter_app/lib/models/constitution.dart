import 'package:freezed_annotation/freezed_annotation.dart';

part 'constitution.freezed.dart';
part 'constitution.g.dart';

@freezed
class Constitution with _$Constitution {
  const factory Constitution({
    required List<Part> parts,
    required Preamble? preamble,
  }) = _Constitution;

  factory Constitution.fromJson(Map<String, dynamic> json) =>
      _$ConstitutionFromJson(json);
}

@freezed
class Preamble with _$Preamble {
  const factory Preamble({
    required String? np,
    required String? en,
  }) = _Preamble;

  factory Preamble.fromJson(Map<String, dynamic> json) =>
      _$PreambleFromJson(json);
}

@freezed
class Part with _$Part {
  const factory Part({
    required int id,
    required String? title,
    required String? titleNp,
    required List<Article> articles,
  }) = _Part;

  factory Part.fromJson(Map<String, dynamic> json) => _$PartFromJson(json);
}

@freezed
class Article with _$Article {
  const factory Article({
    required String id,
    required String? title,
    required String? titleNp,
    required String? topic,
    required String? topicNp,
    required List<ContentItem> content,
  }) = _Article;

  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);
}

@freezed
class ContentItem with _$ContentItem {
  const factory ContentItem({
    required String type,
    required String? identifier,
    required String? text,
    required String? textNp,
    required List<ContentItem>? items,
  }) = _ContentItem;

  factory ContentItem.fromJson(Map<String, dynamic> json) =>
      _$ContentItemFromJson(json);
}

@freezed
class AlignedSentence with _$AlignedSentence {
  const factory AlignedSentence({
    required String np,
    required String en,
  }) = _AlignedSentence;

  factory AlignedSentence.fromJson(Map<String, dynamic> json) =>
      _$AlignedSentenceFromJson(json);
}
