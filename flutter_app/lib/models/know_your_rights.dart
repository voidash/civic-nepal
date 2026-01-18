import 'package:freezed_annotation/freezed_annotation.dart';

part 'know_your_rights.freezed.dart';
part 'know_your_rights.g.dart';

/// Localized text supporting multiple languages
@freezed
class LocalizedText with _$LocalizedText {
  const LocalizedText._();

  const factory LocalizedText({
    required String en,
    required String np,
    @JsonKey(name: 'new') String? newari,
    String? mai,
  }) = _LocalizedText;

  factory LocalizedText.fromJson(Map<String, dynamic> json) =>
      _$LocalizedTextFromJson(json);

  /// Get text for the specified locale code
  String forLocale(String localeCode) {
    switch (localeCode) {
      case 'ne':
        return np;
      case 'new':
        return newari ?? np; // Fallback to Nepali if no Newari
      case 'mai':
        return mai ?? np; // Fallback to Nepali if no Maithili
      default:
        return en;
    }
  }
}

/// Alias for backward compatibility
typedef BilingualText = LocalizedText;

/// Reference to a constitution article
@freezed
class ArticleReference with _$ArticleReference {
  const factory ArticleReference({
    required int partIndex,
    required int articleIndex,
    required String articleNumber,
    required BilingualText articleTitle,
  }) = _ArticleReference;

  factory ArticleReference.fromJson(Map<String, dynamic> json) =>
      _$ArticleReferenceFromJson(json);
}

/// A single right/situation
@freezed
class RightItem with _$RightItem {
  const factory RightItem({
    required BilingualText situation,
    required BilingualText yourRight,
    required ArticleReference articleRef,
    required BilingualText tip,
  }) = _RightItem;

  factory RightItem.fromJson(Map<String, dynamic> json) =>
      _$RightItemFromJson(json);
}

/// A category of rights
@freezed
class RightsCategory with _$RightsCategory {
  const factory RightsCategory({
    required String id,
    required String icon,
    required BilingualText title,
    required BilingualText subtitle,
    required List<RightItem> rights,
  }) = _RightsCategory;

  factory RightsCategory.fromJson(Map<String, dynamic> json) =>
      _$RightsCategoryFromJson(json);
}

/// Root data structure for Know Your Rights
@freezed
class KnowYourRightsData with _$KnowYourRightsData {
  const factory KnowYourRightsData({
    required BilingualText disclaimer,
    required List<RightsCategory> categories,
  }) = _KnowYourRightsData;

  factory KnowYourRightsData.fromJson(Map<String, dynamic> json) =>
      _$KnowYourRightsDataFromJson(json);
}
