// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'know_your_rights.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LocalizedText _$LocalizedTextFromJson(Map<String, dynamic> json) {
  return _LocalizedText.fromJson(json);
}

/// @nodoc
mixin _$LocalizedText {
  String get en => throw _privateConstructorUsedError;
  String get np => throw _privateConstructorUsedError;
  @JsonKey(name: 'new')
  String? get newari => throw _privateConstructorUsedError;
  String? get mai => throw _privateConstructorUsedError;

  /// Serializes this LocalizedText to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LocalizedText
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocalizedTextCopyWith<LocalizedText> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocalizedTextCopyWith<$Res> {
  factory $LocalizedTextCopyWith(
          LocalizedText value, $Res Function(LocalizedText) then) =
      _$LocalizedTextCopyWithImpl<$Res, LocalizedText>;
  @useResult
  $Res call(
      {String en,
      String np,
      @JsonKey(name: 'new') String? newari,
      String? mai});
}

/// @nodoc
class _$LocalizedTextCopyWithImpl<$Res, $Val extends LocalizedText>
    implements $LocalizedTextCopyWith<$Res> {
  _$LocalizedTextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocalizedText
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = null,
    Object? np = null,
    Object? newari = freezed,
    Object? mai = freezed,
  }) {
    return _then(_value.copyWith(
      en: null == en
          ? _value.en
          : en // ignore: cast_nullable_to_non_nullable
              as String,
      np: null == np
          ? _value.np
          : np // ignore: cast_nullable_to_non_nullable
              as String,
      newari: freezed == newari
          ? _value.newari
          : newari // ignore: cast_nullable_to_non_nullable
              as String?,
      mai: freezed == mai
          ? _value.mai
          : mai // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LocalizedTextImplCopyWith<$Res>
    implements $LocalizedTextCopyWith<$Res> {
  factory _$$LocalizedTextImplCopyWith(
          _$LocalizedTextImpl value, $Res Function(_$LocalizedTextImpl) then) =
      __$$LocalizedTextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String en,
      String np,
      @JsonKey(name: 'new') String? newari,
      String? mai});
}

/// @nodoc
class __$$LocalizedTextImplCopyWithImpl<$Res>
    extends _$LocalizedTextCopyWithImpl<$Res, _$LocalizedTextImpl>
    implements _$$LocalizedTextImplCopyWith<$Res> {
  __$$LocalizedTextImplCopyWithImpl(
      _$LocalizedTextImpl _value, $Res Function(_$LocalizedTextImpl) _then)
      : super(_value, _then);

  /// Create a copy of LocalizedText
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = null,
    Object? np = null,
    Object? newari = freezed,
    Object? mai = freezed,
  }) {
    return _then(_$LocalizedTextImpl(
      en: null == en
          ? _value.en
          : en // ignore: cast_nullable_to_non_nullable
              as String,
      np: null == np
          ? _value.np
          : np // ignore: cast_nullable_to_non_nullable
              as String,
      newari: freezed == newari
          ? _value.newari
          : newari // ignore: cast_nullable_to_non_nullable
              as String?,
      mai: freezed == mai
          ? _value.mai
          : mai // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LocalizedTextImpl extends _LocalizedText {
  const _$LocalizedTextImpl(
      {required this.en,
      required this.np,
      @JsonKey(name: 'new') this.newari,
      this.mai})
      : super._();

  factory _$LocalizedTextImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocalizedTextImplFromJson(json);

  @override
  final String en;
  @override
  final String np;
  @override
  @JsonKey(name: 'new')
  final String? newari;
  @override
  final String? mai;

  @override
  String toString() {
    return 'LocalizedText(en: $en, np: $np, newari: $newari, mai: $mai)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalizedTextImpl &&
            (identical(other.en, en) || other.en == en) &&
            (identical(other.np, np) || other.np == np) &&
            (identical(other.newari, newari) || other.newari == newari) &&
            (identical(other.mai, mai) || other.mai == mai));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, en, np, newari, mai);

  /// Create a copy of LocalizedText
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocalizedTextImplCopyWith<_$LocalizedTextImpl> get copyWith =>
      __$$LocalizedTextImplCopyWithImpl<_$LocalizedTextImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LocalizedTextImplToJson(
      this,
    );
  }
}

abstract class _LocalizedText extends LocalizedText {
  const factory _LocalizedText(
      {required final String en,
      required final String np,
      @JsonKey(name: 'new') final String? newari,
      final String? mai}) = _$LocalizedTextImpl;
  const _LocalizedText._() : super._();

  factory _LocalizedText.fromJson(Map<String, dynamic> json) =
      _$LocalizedTextImpl.fromJson;

  @override
  String get en;
  @override
  String get np;
  @override
  @JsonKey(name: 'new')
  String? get newari;
  @override
  String? get mai;

  /// Create a copy of LocalizedText
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocalizedTextImplCopyWith<_$LocalizedTextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArticleReference _$ArticleReferenceFromJson(Map<String, dynamic> json) {
  return _ArticleReference.fromJson(json);
}

/// @nodoc
mixin _$ArticleReference {
  int get partIndex => throw _privateConstructorUsedError;
  int get articleIndex => throw _privateConstructorUsedError;
  String get articleNumber => throw _privateConstructorUsedError;
  LocalizedText get articleTitle => throw _privateConstructorUsedError;

  /// Serializes this ArticleReference to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArticleReference
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArticleReferenceCopyWith<ArticleReference> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleReferenceCopyWith<$Res> {
  factory $ArticleReferenceCopyWith(
          ArticleReference value, $Res Function(ArticleReference) then) =
      _$ArticleReferenceCopyWithImpl<$Res, ArticleReference>;
  @useResult
  $Res call(
      {int partIndex,
      int articleIndex,
      String articleNumber,
      LocalizedText articleTitle});

  $LocalizedTextCopyWith<$Res> get articleTitle;
}

/// @nodoc
class _$ArticleReferenceCopyWithImpl<$Res, $Val extends ArticleReference>
    implements $ArticleReferenceCopyWith<$Res> {
  _$ArticleReferenceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArticleReference
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? partIndex = null,
    Object? articleIndex = null,
    Object? articleNumber = null,
    Object? articleTitle = null,
  }) {
    return _then(_value.copyWith(
      partIndex: null == partIndex
          ? _value.partIndex
          : partIndex // ignore: cast_nullable_to_non_nullable
              as int,
      articleIndex: null == articleIndex
          ? _value.articleIndex
          : articleIndex // ignore: cast_nullable_to_non_nullable
              as int,
      articleNumber: null == articleNumber
          ? _value.articleNumber
          : articleNumber // ignore: cast_nullable_to_non_nullable
              as String,
      articleTitle: null == articleTitle
          ? _value.articleTitle
          : articleTitle // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
    ) as $Val);
  }

  /// Create a copy of ArticleReference
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocalizedTextCopyWith<$Res> get articleTitle {
    return $LocalizedTextCopyWith<$Res>(_value.articleTitle, (value) {
      return _then(_value.copyWith(articleTitle: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ArticleReferenceImplCopyWith<$Res>
    implements $ArticleReferenceCopyWith<$Res> {
  factory _$$ArticleReferenceImplCopyWith(_$ArticleReferenceImpl value,
          $Res Function(_$ArticleReferenceImpl) then) =
      __$$ArticleReferenceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int partIndex,
      int articleIndex,
      String articleNumber,
      LocalizedText articleTitle});

  @override
  $LocalizedTextCopyWith<$Res> get articleTitle;
}

/// @nodoc
class __$$ArticleReferenceImplCopyWithImpl<$Res>
    extends _$ArticleReferenceCopyWithImpl<$Res, _$ArticleReferenceImpl>
    implements _$$ArticleReferenceImplCopyWith<$Res> {
  __$$ArticleReferenceImplCopyWithImpl(_$ArticleReferenceImpl _value,
      $Res Function(_$ArticleReferenceImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArticleReference
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? partIndex = null,
    Object? articleIndex = null,
    Object? articleNumber = null,
    Object? articleTitle = null,
  }) {
    return _then(_$ArticleReferenceImpl(
      partIndex: null == partIndex
          ? _value.partIndex
          : partIndex // ignore: cast_nullable_to_non_nullable
              as int,
      articleIndex: null == articleIndex
          ? _value.articleIndex
          : articleIndex // ignore: cast_nullable_to_non_nullable
              as int,
      articleNumber: null == articleNumber
          ? _value.articleNumber
          : articleNumber // ignore: cast_nullable_to_non_nullable
              as String,
      articleTitle: null == articleTitle
          ? _value.articleTitle
          : articleTitle // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleReferenceImpl implements _ArticleReference {
  const _$ArticleReferenceImpl(
      {required this.partIndex,
      required this.articleIndex,
      required this.articleNumber,
      required this.articleTitle});

  factory _$ArticleReferenceImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleReferenceImplFromJson(json);

  @override
  final int partIndex;
  @override
  final int articleIndex;
  @override
  final String articleNumber;
  @override
  final LocalizedText articleTitle;

  @override
  String toString() {
    return 'ArticleReference(partIndex: $partIndex, articleIndex: $articleIndex, articleNumber: $articleNumber, articleTitle: $articleTitle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleReferenceImpl &&
            (identical(other.partIndex, partIndex) ||
                other.partIndex == partIndex) &&
            (identical(other.articleIndex, articleIndex) ||
                other.articleIndex == articleIndex) &&
            (identical(other.articleNumber, articleNumber) ||
                other.articleNumber == articleNumber) &&
            (identical(other.articleTitle, articleTitle) ||
                other.articleTitle == articleTitle));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, partIndex, articleIndex, articleNumber, articleTitle);

  /// Create a copy of ArticleReference
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArticleReferenceImplCopyWith<_$ArticleReferenceImpl> get copyWith =>
      __$$ArticleReferenceImplCopyWithImpl<_$ArticleReferenceImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArticleReferenceImplToJson(
      this,
    );
  }
}

abstract class _ArticleReference implements ArticleReference {
  const factory _ArticleReference(
      {required final int partIndex,
      required final int articleIndex,
      required final String articleNumber,
      required final LocalizedText articleTitle}) = _$ArticleReferenceImpl;

  factory _ArticleReference.fromJson(Map<String, dynamic> json) =
      _$ArticleReferenceImpl.fromJson;

  @override
  int get partIndex;
  @override
  int get articleIndex;
  @override
  String get articleNumber;
  @override
  LocalizedText get articleTitle;

  /// Create a copy of ArticleReference
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleReferenceImplCopyWith<_$ArticleReferenceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RightItem _$RightItemFromJson(Map<String, dynamic> json) {
  return _RightItem.fromJson(json);
}

/// @nodoc
mixin _$RightItem {
  LocalizedText get situation => throw _privateConstructorUsedError;
  LocalizedText get yourRight => throw _privateConstructorUsedError;
  ArticleReference get articleRef => throw _privateConstructorUsedError;
  LocalizedText get tip => throw _privateConstructorUsedError;

  /// Serializes this RightItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RightItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RightItemCopyWith<RightItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RightItemCopyWith<$Res> {
  factory $RightItemCopyWith(RightItem value, $Res Function(RightItem) then) =
      _$RightItemCopyWithImpl<$Res, RightItem>;
  @useResult
  $Res call(
      {LocalizedText situation,
      LocalizedText yourRight,
      ArticleReference articleRef,
      LocalizedText tip});

  $LocalizedTextCopyWith<$Res> get situation;
  $LocalizedTextCopyWith<$Res> get yourRight;
  $ArticleReferenceCopyWith<$Res> get articleRef;
  $LocalizedTextCopyWith<$Res> get tip;
}

/// @nodoc
class _$RightItemCopyWithImpl<$Res, $Val extends RightItem>
    implements $RightItemCopyWith<$Res> {
  _$RightItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RightItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? situation = null,
    Object? yourRight = null,
    Object? articleRef = null,
    Object? tip = null,
  }) {
    return _then(_value.copyWith(
      situation: null == situation
          ? _value.situation
          : situation // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
      yourRight: null == yourRight
          ? _value.yourRight
          : yourRight // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
      articleRef: null == articleRef
          ? _value.articleRef
          : articleRef // ignore: cast_nullable_to_non_nullable
              as ArticleReference,
      tip: null == tip
          ? _value.tip
          : tip // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
    ) as $Val);
  }

  /// Create a copy of RightItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocalizedTextCopyWith<$Res> get situation {
    return $LocalizedTextCopyWith<$Res>(_value.situation, (value) {
      return _then(_value.copyWith(situation: value) as $Val);
    });
  }

  /// Create a copy of RightItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocalizedTextCopyWith<$Res> get yourRight {
    return $LocalizedTextCopyWith<$Res>(_value.yourRight, (value) {
      return _then(_value.copyWith(yourRight: value) as $Val);
    });
  }

  /// Create a copy of RightItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArticleReferenceCopyWith<$Res> get articleRef {
    return $ArticleReferenceCopyWith<$Res>(_value.articleRef, (value) {
      return _then(_value.copyWith(articleRef: value) as $Val);
    });
  }

  /// Create a copy of RightItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocalizedTextCopyWith<$Res> get tip {
    return $LocalizedTextCopyWith<$Res>(_value.tip, (value) {
      return _then(_value.copyWith(tip: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RightItemImplCopyWith<$Res>
    implements $RightItemCopyWith<$Res> {
  factory _$$RightItemImplCopyWith(
          _$RightItemImpl value, $Res Function(_$RightItemImpl) then) =
      __$$RightItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {LocalizedText situation,
      LocalizedText yourRight,
      ArticleReference articleRef,
      LocalizedText tip});

  @override
  $LocalizedTextCopyWith<$Res> get situation;
  @override
  $LocalizedTextCopyWith<$Res> get yourRight;
  @override
  $ArticleReferenceCopyWith<$Res> get articleRef;
  @override
  $LocalizedTextCopyWith<$Res> get tip;
}

/// @nodoc
class __$$RightItemImplCopyWithImpl<$Res>
    extends _$RightItemCopyWithImpl<$Res, _$RightItemImpl>
    implements _$$RightItemImplCopyWith<$Res> {
  __$$RightItemImplCopyWithImpl(
      _$RightItemImpl _value, $Res Function(_$RightItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of RightItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? situation = null,
    Object? yourRight = null,
    Object? articleRef = null,
    Object? tip = null,
  }) {
    return _then(_$RightItemImpl(
      situation: null == situation
          ? _value.situation
          : situation // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
      yourRight: null == yourRight
          ? _value.yourRight
          : yourRight // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
      articleRef: null == articleRef
          ? _value.articleRef
          : articleRef // ignore: cast_nullable_to_non_nullable
              as ArticleReference,
      tip: null == tip
          ? _value.tip
          : tip // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RightItemImpl implements _RightItem {
  const _$RightItemImpl(
      {required this.situation,
      required this.yourRight,
      required this.articleRef,
      required this.tip});

  factory _$RightItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$RightItemImplFromJson(json);

  @override
  final LocalizedText situation;
  @override
  final LocalizedText yourRight;
  @override
  final ArticleReference articleRef;
  @override
  final LocalizedText tip;

  @override
  String toString() {
    return 'RightItem(situation: $situation, yourRight: $yourRight, articleRef: $articleRef, tip: $tip)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RightItemImpl &&
            (identical(other.situation, situation) ||
                other.situation == situation) &&
            (identical(other.yourRight, yourRight) ||
                other.yourRight == yourRight) &&
            (identical(other.articleRef, articleRef) ||
                other.articleRef == articleRef) &&
            (identical(other.tip, tip) || other.tip == tip));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, situation, yourRight, articleRef, tip);

  /// Create a copy of RightItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RightItemImplCopyWith<_$RightItemImpl> get copyWith =>
      __$$RightItemImplCopyWithImpl<_$RightItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RightItemImplToJson(
      this,
    );
  }
}

abstract class _RightItem implements RightItem {
  const factory _RightItem(
      {required final LocalizedText situation,
      required final LocalizedText yourRight,
      required final ArticleReference articleRef,
      required final LocalizedText tip}) = _$RightItemImpl;

  factory _RightItem.fromJson(Map<String, dynamic> json) =
      _$RightItemImpl.fromJson;

  @override
  LocalizedText get situation;
  @override
  LocalizedText get yourRight;
  @override
  ArticleReference get articleRef;
  @override
  LocalizedText get tip;

  /// Create a copy of RightItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RightItemImplCopyWith<_$RightItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RightsCategory _$RightsCategoryFromJson(Map<String, dynamic> json) {
  return _RightsCategory.fromJson(json);
}

/// @nodoc
mixin _$RightsCategory {
  String get id => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  LocalizedText get title => throw _privateConstructorUsedError;
  LocalizedText get subtitle => throw _privateConstructorUsedError;
  List<RightItem> get rights => throw _privateConstructorUsedError;

  /// Serializes this RightsCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RightsCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RightsCategoryCopyWith<RightsCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RightsCategoryCopyWith<$Res> {
  factory $RightsCategoryCopyWith(
          RightsCategory value, $Res Function(RightsCategory) then) =
      _$RightsCategoryCopyWithImpl<$Res, RightsCategory>;
  @useResult
  $Res call(
      {String id,
      String icon,
      LocalizedText title,
      LocalizedText subtitle,
      List<RightItem> rights});

  $LocalizedTextCopyWith<$Res> get title;
  $LocalizedTextCopyWith<$Res> get subtitle;
}

/// @nodoc
class _$RightsCategoryCopyWithImpl<$Res, $Val extends RightsCategory>
    implements $RightsCategoryCopyWith<$Res> {
  _$RightsCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RightsCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? icon = null,
    Object? title = null,
    Object? subtitle = null,
    Object? rights = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
      subtitle: null == subtitle
          ? _value.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
      rights: null == rights
          ? _value.rights
          : rights // ignore: cast_nullable_to_non_nullable
              as List<RightItem>,
    ) as $Val);
  }

  /// Create a copy of RightsCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocalizedTextCopyWith<$Res> get title {
    return $LocalizedTextCopyWith<$Res>(_value.title, (value) {
      return _then(_value.copyWith(title: value) as $Val);
    });
  }

  /// Create a copy of RightsCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocalizedTextCopyWith<$Res> get subtitle {
    return $LocalizedTextCopyWith<$Res>(_value.subtitle, (value) {
      return _then(_value.copyWith(subtitle: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RightsCategoryImplCopyWith<$Res>
    implements $RightsCategoryCopyWith<$Res> {
  factory _$$RightsCategoryImplCopyWith(_$RightsCategoryImpl value,
          $Res Function(_$RightsCategoryImpl) then) =
      __$$RightsCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String icon,
      LocalizedText title,
      LocalizedText subtitle,
      List<RightItem> rights});

  @override
  $LocalizedTextCopyWith<$Res> get title;
  @override
  $LocalizedTextCopyWith<$Res> get subtitle;
}

/// @nodoc
class __$$RightsCategoryImplCopyWithImpl<$Res>
    extends _$RightsCategoryCopyWithImpl<$Res, _$RightsCategoryImpl>
    implements _$$RightsCategoryImplCopyWith<$Res> {
  __$$RightsCategoryImplCopyWithImpl(
      _$RightsCategoryImpl _value, $Res Function(_$RightsCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of RightsCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? icon = null,
    Object? title = null,
    Object? subtitle = null,
    Object? rights = null,
  }) {
    return _then(_$RightsCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
      subtitle: null == subtitle
          ? _value.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
      rights: null == rights
          ? _value._rights
          : rights // ignore: cast_nullable_to_non_nullable
              as List<RightItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RightsCategoryImpl implements _RightsCategory {
  const _$RightsCategoryImpl(
      {required this.id,
      required this.icon,
      required this.title,
      required this.subtitle,
      required final List<RightItem> rights})
      : _rights = rights;

  factory _$RightsCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$RightsCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String icon;
  @override
  final LocalizedText title;
  @override
  final LocalizedText subtitle;
  final List<RightItem> _rights;
  @override
  List<RightItem> get rights {
    if (_rights is EqualUnmodifiableListView) return _rights;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rights);
  }

  @override
  String toString() {
    return 'RightsCategory(id: $id, icon: $icon, title: $title, subtitle: $subtitle, rights: $rights)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RightsCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            const DeepCollectionEquality().equals(other._rights, _rights));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, icon, title, subtitle,
      const DeepCollectionEquality().hash(_rights));

  /// Create a copy of RightsCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RightsCategoryImplCopyWith<_$RightsCategoryImpl> get copyWith =>
      __$$RightsCategoryImplCopyWithImpl<_$RightsCategoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RightsCategoryImplToJson(
      this,
    );
  }
}

abstract class _RightsCategory implements RightsCategory {
  const factory _RightsCategory(
      {required final String id,
      required final String icon,
      required final LocalizedText title,
      required final LocalizedText subtitle,
      required final List<RightItem> rights}) = _$RightsCategoryImpl;

  factory _RightsCategory.fromJson(Map<String, dynamic> json) =
      _$RightsCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get icon;
  @override
  LocalizedText get title;
  @override
  LocalizedText get subtitle;
  @override
  List<RightItem> get rights;

  /// Create a copy of RightsCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RightsCategoryImplCopyWith<_$RightsCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

KnowYourRightsData _$KnowYourRightsDataFromJson(Map<String, dynamic> json) {
  return _KnowYourRightsData.fromJson(json);
}

/// @nodoc
mixin _$KnowYourRightsData {
  LocalizedText get disclaimer => throw _privateConstructorUsedError;
  List<RightsCategory> get categories => throw _privateConstructorUsedError;

  /// Serializes this KnowYourRightsData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KnowYourRightsData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KnowYourRightsDataCopyWith<KnowYourRightsData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KnowYourRightsDataCopyWith<$Res> {
  factory $KnowYourRightsDataCopyWith(
          KnowYourRightsData value, $Res Function(KnowYourRightsData) then) =
      _$KnowYourRightsDataCopyWithImpl<$Res, KnowYourRightsData>;
  @useResult
  $Res call({LocalizedText disclaimer, List<RightsCategory> categories});

  $LocalizedTextCopyWith<$Res> get disclaimer;
}

/// @nodoc
class _$KnowYourRightsDataCopyWithImpl<$Res, $Val extends KnowYourRightsData>
    implements $KnowYourRightsDataCopyWith<$Res> {
  _$KnowYourRightsDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KnowYourRightsData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? disclaimer = null,
    Object? categories = null,
  }) {
    return _then(_value.copyWith(
      disclaimer: null == disclaimer
          ? _value.disclaimer
          : disclaimer // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<RightsCategory>,
    ) as $Val);
  }

  /// Create a copy of KnowYourRightsData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocalizedTextCopyWith<$Res> get disclaimer {
    return $LocalizedTextCopyWith<$Res>(_value.disclaimer, (value) {
      return _then(_value.copyWith(disclaimer: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$KnowYourRightsDataImplCopyWith<$Res>
    implements $KnowYourRightsDataCopyWith<$Res> {
  factory _$$KnowYourRightsDataImplCopyWith(_$KnowYourRightsDataImpl value,
          $Res Function(_$KnowYourRightsDataImpl) then) =
      __$$KnowYourRightsDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({LocalizedText disclaimer, List<RightsCategory> categories});

  @override
  $LocalizedTextCopyWith<$Res> get disclaimer;
}

/// @nodoc
class __$$KnowYourRightsDataImplCopyWithImpl<$Res>
    extends _$KnowYourRightsDataCopyWithImpl<$Res, _$KnowYourRightsDataImpl>
    implements _$$KnowYourRightsDataImplCopyWith<$Res> {
  __$$KnowYourRightsDataImplCopyWithImpl(_$KnowYourRightsDataImpl _value,
      $Res Function(_$KnowYourRightsDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of KnowYourRightsData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? disclaimer = null,
    Object? categories = null,
  }) {
    return _then(_$KnowYourRightsDataImpl(
      disclaimer: null == disclaimer
          ? _value.disclaimer
          : disclaimer // ignore: cast_nullable_to_non_nullable
              as LocalizedText,
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<RightsCategory>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$KnowYourRightsDataImpl implements _KnowYourRightsData {
  const _$KnowYourRightsDataImpl(
      {required this.disclaimer,
      required final List<RightsCategory> categories})
      : _categories = categories;

  factory _$KnowYourRightsDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$KnowYourRightsDataImplFromJson(json);

  @override
  final LocalizedText disclaimer;
  final List<RightsCategory> _categories;
  @override
  List<RightsCategory> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  String toString() {
    return 'KnowYourRightsData(disclaimer: $disclaimer, categories: $categories)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KnowYourRightsDataImpl &&
            (identical(other.disclaimer, disclaimer) ||
                other.disclaimer == disclaimer) &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, disclaimer,
      const DeepCollectionEquality().hash(_categories));

  /// Create a copy of KnowYourRightsData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KnowYourRightsDataImplCopyWith<_$KnowYourRightsDataImpl> get copyWith =>
      __$$KnowYourRightsDataImplCopyWithImpl<_$KnowYourRightsDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KnowYourRightsDataImplToJson(
      this,
    );
  }
}

abstract class _KnowYourRightsData implements KnowYourRightsData {
  const factory _KnowYourRightsData(
          {required final LocalizedText disclaimer,
          required final List<RightsCategory> categories}) =
      _$KnowYourRightsDataImpl;

  factory _KnowYourRightsData.fromJson(Map<String, dynamic> json) =
      _$KnowYourRightsDataImpl.fromJson;

  @override
  LocalizedText get disclaimer;
  @override
  List<RightsCategory> get categories;

  /// Create a copy of KnowYourRightsData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KnowYourRightsDataImplCopyWith<_$KnowYourRightsDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
