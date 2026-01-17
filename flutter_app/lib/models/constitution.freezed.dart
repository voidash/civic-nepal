// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'constitution.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ConstitutionWrapper _$ConstitutionWrapperFromJson(Map<String, dynamic> json) {
  return _ConstitutionWrapper.fromJson(json);
}

/// @nodoc
mixin _$ConstitutionWrapper {
  ConstitutionData get constitution => throw _privateConstructorUsedError;

  /// Serializes this ConstitutionWrapper to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConstitutionWrapper
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConstitutionWrapperCopyWith<ConstitutionWrapper> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConstitutionWrapperCopyWith<$Res> {
  factory $ConstitutionWrapperCopyWith(
          ConstitutionWrapper value, $Res Function(ConstitutionWrapper) then) =
      _$ConstitutionWrapperCopyWithImpl<$Res, ConstitutionWrapper>;
  @useResult
  $Res call({ConstitutionData constitution});

  $ConstitutionDataCopyWith<$Res> get constitution;
}

/// @nodoc
class _$ConstitutionWrapperCopyWithImpl<$Res, $Val extends ConstitutionWrapper>
    implements $ConstitutionWrapperCopyWith<$Res> {
  _$ConstitutionWrapperCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConstitutionWrapper
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? constitution = null,
  }) {
    return _then(_value.copyWith(
      constitution: null == constitution
          ? _value.constitution
          : constitution // ignore: cast_nullable_to_non_nullable
              as ConstitutionData,
    ) as $Val);
  }

  /// Create a copy of ConstitutionWrapper
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConstitutionDataCopyWith<$Res> get constitution {
    return $ConstitutionDataCopyWith<$Res>(_value.constitution, (value) {
      return _then(_value.copyWith(constitution: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ConstitutionWrapperImplCopyWith<$Res>
    implements $ConstitutionWrapperCopyWith<$Res> {
  factory _$$ConstitutionWrapperImplCopyWith(_$ConstitutionWrapperImpl value,
          $Res Function(_$ConstitutionWrapperImpl) then) =
      __$$ConstitutionWrapperImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ConstitutionData constitution});

  @override
  $ConstitutionDataCopyWith<$Res> get constitution;
}

/// @nodoc
class __$$ConstitutionWrapperImplCopyWithImpl<$Res>
    extends _$ConstitutionWrapperCopyWithImpl<$Res, _$ConstitutionWrapperImpl>
    implements _$$ConstitutionWrapperImplCopyWith<$Res> {
  __$$ConstitutionWrapperImplCopyWithImpl(_$ConstitutionWrapperImpl _value,
      $Res Function(_$ConstitutionWrapperImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConstitutionWrapper
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? constitution = null,
  }) {
    return _then(_$ConstitutionWrapperImpl(
      constitution: null == constitution
          ? _value.constitution
          : constitution // ignore: cast_nullable_to_non_nullable
              as ConstitutionData,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConstitutionWrapperImpl implements _ConstitutionWrapper {
  const _$ConstitutionWrapperImpl({required this.constitution});

  factory _$ConstitutionWrapperImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConstitutionWrapperImplFromJson(json);

  @override
  final ConstitutionData constitution;

  @override
  String toString() {
    return 'ConstitutionWrapper(constitution: $constitution)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConstitutionWrapperImpl &&
            (identical(other.constitution, constitution) ||
                other.constitution == constitution));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, constitution);

  /// Create a copy of ConstitutionWrapper
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConstitutionWrapperImplCopyWith<_$ConstitutionWrapperImpl> get copyWith =>
      __$$ConstitutionWrapperImplCopyWithImpl<_$ConstitutionWrapperImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConstitutionWrapperImplToJson(
      this,
    );
  }
}

abstract class _ConstitutionWrapper implements ConstitutionWrapper {
  const factory _ConstitutionWrapper(
          {required final ConstitutionData constitution}) =
      _$ConstitutionWrapperImpl;

  factory _ConstitutionWrapper.fromJson(Map<String, dynamic> json) =
      _$ConstitutionWrapperImpl.fromJson;

  @override
  ConstitutionData get constitution;

  /// Create a copy of ConstitutionWrapper
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConstitutionWrapperImplCopyWith<_$ConstitutionWrapperImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConstitutionData _$ConstitutionDataFromJson(Map<String, dynamic> json) {
  return _ConstitutionData.fromJson(json);
}

/// @nodoc
mixin _$ConstitutionData {
  ConstitutionTitle get title => throw _privateConstructorUsedError;
  String get publicationDate => throw _privateConstructorUsedError;
  Preamble get preamble => throw _privateConstructorUsedError;
  List<Part> get parts => throw _privateConstructorUsedError;

  /// Serializes this ConstitutionData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConstitutionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConstitutionDataCopyWith<ConstitutionData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConstitutionDataCopyWith<$Res> {
  factory $ConstitutionDataCopyWith(
          ConstitutionData value, $Res Function(ConstitutionData) then) =
      _$ConstitutionDataCopyWithImpl<$Res, ConstitutionData>;
  @useResult
  $Res call(
      {ConstitutionTitle title,
      String publicationDate,
      Preamble preamble,
      List<Part> parts});

  $ConstitutionTitleCopyWith<$Res> get title;
  $PreambleCopyWith<$Res> get preamble;
}

/// @nodoc
class _$ConstitutionDataCopyWithImpl<$Res, $Val extends ConstitutionData>
    implements $ConstitutionDataCopyWith<$Res> {
  _$ConstitutionDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConstitutionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? publicationDate = null,
    Object? preamble = null,
    Object? parts = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as ConstitutionTitle,
      publicationDate: null == publicationDate
          ? _value.publicationDate
          : publicationDate // ignore: cast_nullable_to_non_nullable
              as String,
      preamble: null == preamble
          ? _value.preamble
          : preamble // ignore: cast_nullable_to_non_nullable
              as Preamble,
      parts: null == parts
          ? _value.parts
          : parts // ignore: cast_nullable_to_non_nullable
              as List<Part>,
    ) as $Val);
  }

  /// Create a copy of ConstitutionData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConstitutionTitleCopyWith<$Res> get title {
    return $ConstitutionTitleCopyWith<$Res>(_value.title, (value) {
      return _then(_value.copyWith(title: value) as $Val);
    });
  }

  /// Create a copy of ConstitutionData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PreambleCopyWith<$Res> get preamble {
    return $PreambleCopyWith<$Res>(_value.preamble, (value) {
      return _then(_value.copyWith(preamble: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ConstitutionDataImplCopyWith<$Res>
    implements $ConstitutionDataCopyWith<$Res> {
  factory _$$ConstitutionDataImplCopyWith(_$ConstitutionDataImpl value,
          $Res Function(_$ConstitutionDataImpl) then) =
      __$$ConstitutionDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ConstitutionTitle title,
      String publicationDate,
      Preamble preamble,
      List<Part> parts});

  @override
  $ConstitutionTitleCopyWith<$Res> get title;
  @override
  $PreambleCopyWith<$Res> get preamble;
}

/// @nodoc
class __$$ConstitutionDataImplCopyWithImpl<$Res>
    extends _$ConstitutionDataCopyWithImpl<$Res, _$ConstitutionDataImpl>
    implements _$$ConstitutionDataImplCopyWith<$Res> {
  __$$ConstitutionDataImplCopyWithImpl(_$ConstitutionDataImpl _value,
      $Res Function(_$ConstitutionDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConstitutionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? publicationDate = null,
    Object? preamble = null,
    Object? parts = null,
  }) {
    return _then(_$ConstitutionDataImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as ConstitutionTitle,
      publicationDate: null == publicationDate
          ? _value.publicationDate
          : publicationDate // ignore: cast_nullable_to_non_nullable
              as String,
      preamble: null == preamble
          ? _value.preamble
          : preamble // ignore: cast_nullable_to_non_nullable
              as Preamble,
      parts: null == parts
          ? _value._parts
          : parts // ignore: cast_nullable_to_non_nullable
              as List<Part>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConstitutionDataImpl implements _ConstitutionData {
  const _$ConstitutionDataImpl(
      {required this.title,
      required this.publicationDate,
      required this.preamble,
      required final List<Part> parts})
      : _parts = parts;

  factory _$ConstitutionDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConstitutionDataImplFromJson(json);

  @override
  final ConstitutionTitle title;
  @override
  final String publicationDate;
  @override
  final Preamble preamble;
  final List<Part> _parts;
  @override
  List<Part> get parts {
    if (_parts is EqualUnmodifiableListView) return _parts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parts);
  }

  @override
  String toString() {
    return 'ConstitutionData(title: $title, publicationDate: $publicationDate, preamble: $preamble, parts: $parts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConstitutionDataImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.publicationDate, publicationDate) ||
                other.publicationDate == publicationDate) &&
            (identical(other.preamble, preamble) ||
                other.preamble == preamble) &&
            const DeepCollectionEquality().equals(other._parts, _parts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, publicationDate, preamble,
      const DeepCollectionEquality().hash(_parts));

  /// Create a copy of ConstitutionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConstitutionDataImplCopyWith<_$ConstitutionDataImpl> get copyWith =>
      __$$ConstitutionDataImplCopyWithImpl<_$ConstitutionDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConstitutionDataImplToJson(
      this,
    );
  }
}

abstract class _ConstitutionData implements ConstitutionData {
  const factory _ConstitutionData(
      {required final ConstitutionTitle title,
      required final String publicationDate,
      required final Preamble preamble,
      required final List<Part> parts}) = _$ConstitutionDataImpl;

  factory _ConstitutionData.fromJson(Map<String, dynamic> json) =
      _$ConstitutionDataImpl.fromJson;

  @override
  ConstitutionTitle get title;
  @override
  String get publicationDate;
  @override
  Preamble get preamble;
  @override
  List<Part> get parts;

  /// Create a copy of ConstitutionData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConstitutionDataImplCopyWith<_$ConstitutionDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConstitutionTitle _$ConstitutionTitleFromJson(Map<String, dynamic> json) {
  return _ConstitutionTitle.fromJson(json);
}

/// @nodoc
mixin _$ConstitutionTitle {
  String get en => throw _privateConstructorUsedError;
  String get np => throw _privateConstructorUsedError;

  /// Serializes this ConstitutionTitle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConstitutionTitle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConstitutionTitleCopyWith<ConstitutionTitle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConstitutionTitleCopyWith<$Res> {
  factory $ConstitutionTitleCopyWith(
          ConstitutionTitle value, $Res Function(ConstitutionTitle) then) =
      _$ConstitutionTitleCopyWithImpl<$Res, ConstitutionTitle>;
  @useResult
  $Res call({String en, String np});
}

/// @nodoc
class _$ConstitutionTitleCopyWithImpl<$Res, $Val extends ConstitutionTitle>
    implements $ConstitutionTitleCopyWith<$Res> {
  _$ConstitutionTitleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConstitutionTitle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = null,
    Object? np = null,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConstitutionTitleImplCopyWith<$Res>
    implements $ConstitutionTitleCopyWith<$Res> {
  factory _$$ConstitutionTitleImplCopyWith(_$ConstitutionTitleImpl value,
          $Res Function(_$ConstitutionTitleImpl) then) =
      __$$ConstitutionTitleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String en, String np});
}

/// @nodoc
class __$$ConstitutionTitleImplCopyWithImpl<$Res>
    extends _$ConstitutionTitleCopyWithImpl<$Res, _$ConstitutionTitleImpl>
    implements _$$ConstitutionTitleImplCopyWith<$Res> {
  __$$ConstitutionTitleImplCopyWithImpl(_$ConstitutionTitleImpl _value,
      $Res Function(_$ConstitutionTitleImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConstitutionTitle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = null,
    Object? np = null,
  }) {
    return _then(_$ConstitutionTitleImpl(
      en: null == en
          ? _value.en
          : en // ignore: cast_nullable_to_non_nullable
              as String,
      np: null == np
          ? _value.np
          : np // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConstitutionTitleImpl implements _ConstitutionTitle {
  const _$ConstitutionTitleImpl({required this.en, required this.np});

  factory _$ConstitutionTitleImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConstitutionTitleImplFromJson(json);

  @override
  final String en;
  @override
  final String np;

  @override
  String toString() {
    return 'ConstitutionTitle(en: $en, np: $np)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConstitutionTitleImpl &&
            (identical(other.en, en) || other.en == en) &&
            (identical(other.np, np) || other.np == np));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, en, np);

  /// Create a copy of ConstitutionTitle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConstitutionTitleImplCopyWith<_$ConstitutionTitleImpl> get copyWith =>
      __$$ConstitutionTitleImplCopyWithImpl<_$ConstitutionTitleImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConstitutionTitleImplToJson(
      this,
    );
  }
}

abstract class _ConstitutionTitle implements ConstitutionTitle {
  const factory _ConstitutionTitle(
      {required final String en,
      required final String np}) = _$ConstitutionTitleImpl;

  factory _ConstitutionTitle.fromJson(Map<String, dynamic> json) =
      _$ConstitutionTitleImpl.fromJson;

  @override
  String get en;
  @override
  String get np;

  /// Create a copy of ConstitutionTitle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConstitutionTitleImplCopyWith<_$ConstitutionTitleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Preamble _$PreambleFromJson(Map<String, dynamic> json) {
  return _Preamble.fromJson(json);
}

/// @nodoc
mixin _$Preamble {
  String get en => throw _privateConstructorUsedError;
  String get np => throw _privateConstructorUsedError;

  /// Serializes this Preamble to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Preamble
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PreambleCopyWith<Preamble> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PreambleCopyWith<$Res> {
  factory $PreambleCopyWith(Preamble value, $Res Function(Preamble) then) =
      _$PreambleCopyWithImpl<$Res, Preamble>;
  @useResult
  $Res call({String en, String np});
}

/// @nodoc
class _$PreambleCopyWithImpl<$Res, $Val extends Preamble>
    implements $PreambleCopyWith<$Res> {
  _$PreambleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Preamble
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = null,
    Object? np = null,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PreambleImplCopyWith<$Res>
    implements $PreambleCopyWith<$Res> {
  factory _$$PreambleImplCopyWith(
          _$PreambleImpl value, $Res Function(_$PreambleImpl) then) =
      __$$PreambleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String en, String np});
}

/// @nodoc
class __$$PreambleImplCopyWithImpl<$Res>
    extends _$PreambleCopyWithImpl<$Res, _$PreambleImpl>
    implements _$$PreambleImplCopyWith<$Res> {
  __$$PreambleImplCopyWithImpl(
      _$PreambleImpl _value, $Res Function(_$PreambleImpl) _then)
      : super(_value, _then);

  /// Create a copy of Preamble
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = null,
    Object? np = null,
  }) {
    return _then(_$PreambleImpl(
      en: null == en
          ? _value.en
          : en // ignore: cast_nullable_to_non_nullable
              as String,
      np: null == np
          ? _value.np
          : np // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PreambleImpl implements _Preamble {
  const _$PreambleImpl({required this.en, required this.np});

  factory _$PreambleImpl.fromJson(Map<String, dynamic> json) =>
      _$$PreambleImplFromJson(json);

  @override
  final String en;
  @override
  final String np;

  @override
  String toString() {
    return 'Preamble(en: $en, np: $np)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PreambleImpl &&
            (identical(other.en, en) || other.en == en) &&
            (identical(other.np, np) || other.np == np));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, en, np);

  /// Create a copy of Preamble
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PreambleImplCopyWith<_$PreambleImpl> get copyWith =>
      __$$PreambleImplCopyWithImpl<_$PreambleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PreambleImplToJson(
      this,
    );
  }
}

abstract class _Preamble implements Preamble {
  const factory _Preamble(
      {required final String en, required final String np}) = _$PreambleImpl;

  factory _Preamble.fromJson(Map<String, dynamic> json) =
      _$PreambleImpl.fromJson;

  @override
  String get en;
  @override
  String get np;

  /// Create a copy of Preamble
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PreambleImplCopyWith<_$PreambleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Part _$PartFromJson(Map<String, dynamic> json) {
  return _Part.fromJson(json);
}

/// @nodoc
mixin _$Part {
  int get number => throw _privateConstructorUsedError;
  PartTitle get title => throw _privateConstructorUsedError;
  List<Article> get articles => throw _privateConstructorUsedError;

  /// Serializes this Part to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PartCopyWith<Part> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PartCopyWith<$Res> {
  factory $PartCopyWith(Part value, $Res Function(Part) then) =
      _$PartCopyWithImpl<$Res, Part>;
  @useResult
  $Res call({int number, PartTitle title, List<Article> articles});

  $PartTitleCopyWith<$Res> get title;
}

/// @nodoc
class _$PartCopyWithImpl<$Res, $Val extends Part>
    implements $PartCopyWith<$Res> {
  _$PartCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? title = null,
    Object? articles = null,
  }) {
    return _then(_value.copyWith(
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as PartTitle,
      articles: null == articles
          ? _value.articles
          : articles // ignore: cast_nullable_to_non_nullable
              as List<Article>,
    ) as $Val);
  }

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PartTitleCopyWith<$Res> get title {
    return $PartTitleCopyWith<$Res>(_value.title, (value) {
      return _then(_value.copyWith(title: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PartImplCopyWith<$Res> implements $PartCopyWith<$Res> {
  factory _$$PartImplCopyWith(
          _$PartImpl value, $Res Function(_$PartImpl) then) =
      __$$PartImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int number, PartTitle title, List<Article> articles});

  @override
  $PartTitleCopyWith<$Res> get title;
}

/// @nodoc
class __$$PartImplCopyWithImpl<$Res>
    extends _$PartCopyWithImpl<$Res, _$PartImpl>
    implements _$$PartImplCopyWith<$Res> {
  __$$PartImplCopyWithImpl(_$PartImpl _value, $Res Function(_$PartImpl) _then)
      : super(_value, _then);

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? title = null,
    Object? articles = null,
  }) {
    return _then(_$PartImpl(
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as PartTitle,
      articles: null == articles
          ? _value._articles
          : articles // ignore: cast_nullable_to_non_nullable
              as List<Article>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PartImpl implements _Part {
  const _$PartImpl(
      {required this.number,
      required this.title,
      required final List<Article> articles})
      : _articles = articles;

  factory _$PartImpl.fromJson(Map<String, dynamic> json) =>
      _$$PartImplFromJson(json);

  @override
  final int number;
  @override
  final PartTitle title;
  final List<Article> _articles;
  @override
  List<Article> get articles {
    if (_articles is EqualUnmodifiableListView) return _articles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_articles);
  }

  @override
  String toString() {
    return 'Part(number: $number, title: $title, articles: $articles)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PartImpl &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._articles, _articles));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, number, title,
      const DeepCollectionEquality().hash(_articles));

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PartImplCopyWith<_$PartImpl> get copyWith =>
      __$$PartImplCopyWithImpl<_$PartImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PartImplToJson(
      this,
    );
  }
}

abstract class _Part implements Part {
  const factory _Part(
      {required final int number,
      required final PartTitle title,
      required final List<Article> articles}) = _$PartImpl;

  factory _Part.fromJson(Map<String, dynamic> json) = _$PartImpl.fromJson;

  @override
  int get number;
  @override
  PartTitle get title;
  @override
  List<Article> get articles;

  /// Create a copy of Part
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PartImplCopyWith<_$PartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PartTitle _$PartTitleFromJson(Map<String, dynamic> json) {
  return _PartTitle.fromJson(json);
}

/// @nodoc
mixin _$PartTitle {
  String get en => throw _privateConstructorUsedError;
  String get np => throw _privateConstructorUsedError;

  /// Serializes this PartTitle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PartTitle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PartTitleCopyWith<PartTitle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PartTitleCopyWith<$Res> {
  factory $PartTitleCopyWith(PartTitle value, $Res Function(PartTitle) then) =
      _$PartTitleCopyWithImpl<$Res, PartTitle>;
  @useResult
  $Res call({String en, String np});
}

/// @nodoc
class _$PartTitleCopyWithImpl<$Res, $Val extends PartTitle>
    implements $PartTitleCopyWith<$Res> {
  _$PartTitleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PartTitle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = null,
    Object? np = null,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PartTitleImplCopyWith<$Res>
    implements $PartTitleCopyWith<$Res> {
  factory _$$PartTitleImplCopyWith(
          _$PartTitleImpl value, $Res Function(_$PartTitleImpl) then) =
      __$$PartTitleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String en, String np});
}

/// @nodoc
class __$$PartTitleImplCopyWithImpl<$Res>
    extends _$PartTitleCopyWithImpl<$Res, _$PartTitleImpl>
    implements _$$PartTitleImplCopyWith<$Res> {
  __$$PartTitleImplCopyWithImpl(
      _$PartTitleImpl _value, $Res Function(_$PartTitleImpl) _then)
      : super(_value, _then);

  /// Create a copy of PartTitle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = null,
    Object? np = null,
  }) {
    return _then(_$PartTitleImpl(
      en: null == en
          ? _value.en
          : en // ignore: cast_nullable_to_non_nullable
              as String,
      np: null == np
          ? _value.np
          : np // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PartTitleImpl implements _PartTitle {
  const _$PartTitleImpl({required this.en, required this.np});

  factory _$PartTitleImpl.fromJson(Map<String, dynamic> json) =>
      _$$PartTitleImplFromJson(json);

  @override
  final String en;
  @override
  final String np;

  @override
  String toString() {
    return 'PartTitle(en: $en, np: $np)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PartTitleImpl &&
            (identical(other.en, en) || other.en == en) &&
            (identical(other.np, np) || other.np == np));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, en, np);

  /// Create a copy of PartTitle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PartTitleImplCopyWith<_$PartTitleImpl> get copyWith =>
      __$$PartTitleImplCopyWithImpl<_$PartTitleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PartTitleImplToJson(
      this,
    );
  }
}

abstract class _PartTitle implements PartTitle {
  const factory _PartTitle(
      {required final String en, required final String np}) = _$PartTitleImpl;

  factory _PartTitle.fromJson(Map<String, dynamic> json) =
      _$PartTitleImpl.fromJson;

  @override
  String get en;
  @override
  String get np;

  /// Create a copy of PartTitle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PartTitleImplCopyWith<_$PartTitleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Article _$ArticleFromJson(Map<String, dynamic> json) {
  return _Article.fromJson(json);
}

/// @nodoc
mixin _$Article {
  String get number => throw _privateConstructorUsedError;
  ArticleTitle get title => throw _privateConstructorUsedError;
  ArticleContent get content => throw _privateConstructorUsedError;

  /// Serializes this Article to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArticleCopyWith<Article> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleCopyWith<$Res> {
  factory $ArticleCopyWith(Article value, $Res Function(Article) then) =
      _$ArticleCopyWithImpl<$Res, Article>;
  @useResult
  $Res call({String number, ArticleTitle title, ArticleContent content});

  $ArticleTitleCopyWith<$Res> get title;
  $ArticleContentCopyWith<$Res> get content;
}

/// @nodoc
class _$ArticleCopyWithImpl<$Res, $Val extends Article>
    implements $ArticleCopyWith<$Res> {
  _$ArticleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? title = null,
    Object? content = null,
  }) {
    return _then(_value.copyWith(
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as ArticleTitle,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as ArticleContent,
    ) as $Val);
  }

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArticleTitleCopyWith<$Res> get title {
    return $ArticleTitleCopyWith<$Res>(_value.title, (value) {
      return _then(_value.copyWith(title: value) as $Val);
    });
  }

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArticleContentCopyWith<$Res> get content {
    return $ArticleContentCopyWith<$Res>(_value.content, (value) {
      return _then(_value.copyWith(content: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ArticleImplCopyWith<$Res> implements $ArticleCopyWith<$Res> {
  factory _$$ArticleImplCopyWith(
          _$ArticleImpl value, $Res Function(_$ArticleImpl) then) =
      __$$ArticleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String number, ArticleTitle title, ArticleContent content});

  @override
  $ArticleTitleCopyWith<$Res> get title;
  @override
  $ArticleContentCopyWith<$Res> get content;
}

/// @nodoc
class __$$ArticleImplCopyWithImpl<$Res>
    extends _$ArticleCopyWithImpl<$Res, _$ArticleImpl>
    implements _$$ArticleImplCopyWith<$Res> {
  __$$ArticleImplCopyWithImpl(
      _$ArticleImpl _value, $Res Function(_$ArticleImpl) _then)
      : super(_value, _then);

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? title = null,
    Object? content = null,
  }) {
    return _then(_$ArticleImpl(
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as ArticleTitle,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as ArticleContent,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleImpl implements _Article {
  const _$ArticleImpl(
      {required this.number, required this.title, required this.content});

  factory _$ArticleImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleImplFromJson(json);

  @override
  final String number;
  @override
  final ArticleTitle title;
  @override
  final ArticleContent content;

  @override
  String toString() {
    return 'Article(number: $number, title: $title, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleImpl &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, number, title, content);

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArticleImplCopyWith<_$ArticleImpl> get copyWith =>
      __$$ArticleImplCopyWithImpl<_$ArticleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArticleImplToJson(
      this,
    );
  }
}

abstract class _Article implements Article {
  const factory _Article(
      {required final String number,
      required final ArticleTitle title,
      required final ArticleContent content}) = _$ArticleImpl;

  factory _Article.fromJson(Map<String, dynamic> json) = _$ArticleImpl.fromJson;

  @override
  String get number;
  @override
  ArticleTitle get title;
  @override
  ArticleContent get content;

  /// Create a copy of Article
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleImplCopyWith<_$ArticleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArticleTitle _$ArticleTitleFromJson(Map<String, dynamic> json) {
  return _ArticleTitle.fromJson(json);
}

/// @nodoc
mixin _$ArticleTitle {
  String? get en => throw _privateConstructorUsedError;
  String? get np => throw _privateConstructorUsedError;

  /// Serializes this ArticleTitle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArticleTitle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArticleTitleCopyWith<ArticleTitle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleTitleCopyWith<$Res> {
  factory $ArticleTitleCopyWith(
          ArticleTitle value, $Res Function(ArticleTitle) then) =
      _$ArticleTitleCopyWithImpl<$Res, ArticleTitle>;
  @useResult
  $Res call({String? en, String? np});
}

/// @nodoc
class _$ArticleTitleCopyWithImpl<$Res, $Val extends ArticleTitle>
    implements $ArticleTitleCopyWith<$Res> {
  _$ArticleTitleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArticleTitle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = freezed,
    Object? np = freezed,
  }) {
    return _then(_value.copyWith(
      en: freezed == en
          ? _value.en
          : en // ignore: cast_nullable_to_non_nullable
              as String?,
      np: freezed == np
          ? _value.np
          : np // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArticleTitleImplCopyWith<$Res>
    implements $ArticleTitleCopyWith<$Res> {
  factory _$$ArticleTitleImplCopyWith(
          _$ArticleTitleImpl value, $Res Function(_$ArticleTitleImpl) then) =
      __$$ArticleTitleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? en, String? np});
}

/// @nodoc
class __$$ArticleTitleImplCopyWithImpl<$Res>
    extends _$ArticleTitleCopyWithImpl<$Res, _$ArticleTitleImpl>
    implements _$$ArticleTitleImplCopyWith<$Res> {
  __$$ArticleTitleImplCopyWithImpl(
      _$ArticleTitleImpl _value, $Res Function(_$ArticleTitleImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArticleTitle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = freezed,
    Object? np = freezed,
  }) {
    return _then(_$ArticleTitleImpl(
      en: freezed == en
          ? _value.en
          : en // ignore: cast_nullable_to_non_nullable
              as String?,
      np: freezed == np
          ? _value.np
          : np // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleTitleImpl implements _ArticleTitle {
  const _$ArticleTitleImpl({required this.en, required this.np});

  factory _$ArticleTitleImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleTitleImplFromJson(json);

  @override
  final String? en;
  @override
  final String? np;

  @override
  String toString() {
    return 'ArticleTitle(en: $en, np: $np)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleTitleImpl &&
            (identical(other.en, en) || other.en == en) &&
            (identical(other.np, np) || other.np == np));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, en, np);

  /// Create a copy of ArticleTitle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArticleTitleImplCopyWith<_$ArticleTitleImpl> get copyWith =>
      __$$ArticleTitleImplCopyWithImpl<_$ArticleTitleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArticleTitleImplToJson(
      this,
    );
  }
}

abstract class _ArticleTitle implements ArticleTitle {
  const factory _ArticleTitle(
      {required final String? en,
      required final String? np}) = _$ArticleTitleImpl;

  factory _ArticleTitle.fromJson(Map<String, dynamic> json) =
      _$ArticleTitleImpl.fromJson;

  @override
  String? get en;
  @override
  String? get np;

  /// Create a copy of ArticleTitle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleTitleImplCopyWith<_$ArticleTitleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArticleContent _$ArticleContentFromJson(Map<String, dynamic> json) {
  return _ArticleContent.fromJson(json);
}

/// @nodoc
mixin _$ArticleContent {
  List<ContentItem> get en => throw _privateConstructorUsedError;
  List<ContentItem> get np => throw _privateConstructorUsedError;

  /// Serializes this ArticleContent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArticleContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArticleContentCopyWith<ArticleContent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleContentCopyWith<$Res> {
  factory $ArticleContentCopyWith(
          ArticleContent value, $Res Function(ArticleContent) then) =
      _$ArticleContentCopyWithImpl<$Res, ArticleContent>;
  @useResult
  $Res call({List<ContentItem> en, List<ContentItem> np});
}

/// @nodoc
class _$ArticleContentCopyWithImpl<$Res, $Val extends ArticleContent>
    implements $ArticleContentCopyWith<$Res> {
  _$ArticleContentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArticleContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = null,
    Object? np = null,
  }) {
    return _then(_value.copyWith(
      en: null == en
          ? _value.en
          : en // ignore: cast_nullable_to_non_nullable
              as List<ContentItem>,
      np: null == np
          ? _value.np
          : np // ignore: cast_nullable_to_non_nullable
              as List<ContentItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArticleContentImplCopyWith<$Res>
    implements $ArticleContentCopyWith<$Res> {
  factory _$$ArticleContentImplCopyWith(_$ArticleContentImpl value,
          $Res Function(_$ArticleContentImpl) then) =
      __$$ArticleContentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ContentItem> en, List<ContentItem> np});
}

/// @nodoc
class __$$ArticleContentImplCopyWithImpl<$Res>
    extends _$ArticleContentCopyWithImpl<$Res, _$ArticleContentImpl>
    implements _$$ArticleContentImplCopyWith<$Res> {
  __$$ArticleContentImplCopyWithImpl(
      _$ArticleContentImpl _value, $Res Function(_$ArticleContentImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArticleContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? en = null,
    Object? np = null,
  }) {
    return _then(_$ArticleContentImpl(
      en: null == en
          ? _value._en
          : en // ignore: cast_nullable_to_non_nullable
              as List<ContentItem>,
      np: null == np
          ? _value._np
          : np // ignore: cast_nullable_to_non_nullable
              as List<ContentItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleContentImpl implements _ArticleContent {
  const _$ArticleContentImpl(
      {required final List<ContentItem> en,
      required final List<ContentItem> np})
      : _en = en,
        _np = np;

  factory _$ArticleContentImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleContentImplFromJson(json);

  final List<ContentItem> _en;
  @override
  List<ContentItem> get en {
    if (_en is EqualUnmodifiableListView) return _en;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_en);
  }

  final List<ContentItem> _np;
  @override
  List<ContentItem> get np {
    if (_np is EqualUnmodifiableListView) return _np;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_np);
  }

  @override
  String toString() {
    return 'ArticleContent(en: $en, np: $np)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleContentImpl &&
            const DeepCollectionEquality().equals(other._en, _en) &&
            const DeepCollectionEquality().equals(other._np, _np));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_en),
      const DeepCollectionEquality().hash(_np));

  /// Create a copy of ArticleContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArticleContentImplCopyWith<_$ArticleContentImpl> get copyWith =>
      __$$ArticleContentImplCopyWithImpl<_$ArticleContentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArticleContentImplToJson(
      this,
    );
  }
}

abstract class _ArticleContent implements ArticleContent {
  const factory _ArticleContent(
      {required final List<ContentItem> en,
      required final List<ContentItem> np}) = _$ArticleContentImpl;

  factory _ArticleContent.fromJson(Map<String, dynamic> json) =
      _$ArticleContentImpl.fromJson;

  @override
  List<ContentItem> get en;
  @override
  List<ContentItem> get np;

  /// Create a copy of ArticleContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleContentImplCopyWith<_$ArticleContentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ContentItem _$ContentItemFromJson(Map<String, dynamic> json) {
  return _ContentItem.fromJson(json);
}

/// @nodoc
mixin _$ContentItem {
  String get type => throw _privateConstructorUsedError;
  String? get identifier => throw _privateConstructorUsedError;
  String? get text => throw _privateConstructorUsedError;
  List<ContentItem> get items => throw _privateConstructorUsedError;

  /// Serializes this ContentItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContentItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContentItemCopyWith<ContentItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentItemCopyWith<$Res> {
  factory $ContentItemCopyWith(
          ContentItem value, $Res Function(ContentItem) then) =
      _$ContentItemCopyWithImpl<$Res, ContentItem>;
  @useResult
  $Res call(
      {String type, String? identifier, String? text, List<ContentItem> items});
}

/// @nodoc
class _$ContentItemCopyWithImpl<$Res, $Val extends ContentItem>
    implements $ContentItemCopyWith<$Res> {
  _$ContentItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? identifier = freezed,
    Object? text = freezed,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      identifier: freezed == identifier
          ? _value.identifier
          : identifier // ignore: cast_nullable_to_non_nullable
              as String?,
      text: freezed == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ContentItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ContentItemImplCopyWith<$Res>
    implements $ContentItemCopyWith<$Res> {
  factory _$$ContentItemImplCopyWith(
          _$ContentItemImpl value, $Res Function(_$ContentItemImpl) then) =
      __$$ContentItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String type, String? identifier, String? text, List<ContentItem> items});
}

/// @nodoc
class __$$ContentItemImplCopyWithImpl<$Res>
    extends _$ContentItemCopyWithImpl<$Res, _$ContentItemImpl>
    implements _$$ContentItemImplCopyWith<$Res> {
  __$$ContentItemImplCopyWithImpl(
      _$ContentItemImpl _value, $Res Function(_$ContentItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of ContentItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? identifier = freezed,
    Object? text = freezed,
    Object? items = null,
  }) {
    return _then(_$ContentItemImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      identifier: freezed == identifier
          ? _value.identifier
          : identifier // ignore: cast_nullable_to_non_nullable
              as String?,
      text: freezed == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ContentItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ContentItemImpl implements _ContentItem {
  const _$ContentItemImpl(
      {required this.type,
      this.identifier,
      this.text,
      final List<ContentItem> items = const []})
      : _items = items;

  factory _$ContentItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContentItemImplFromJson(json);

  @override
  final String type;
  @override
  final String? identifier;
  @override
  final String? text;
  final List<ContentItem> _items;
  @override
  @JsonKey()
  List<ContentItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'ContentItem(type: $type, identifier: $identifier, text: $text, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentItemImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.identifier, identifier) ||
                other.identifier == identifier) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, identifier, text,
      const DeepCollectionEquality().hash(_items));

  /// Create a copy of ContentItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentItemImplCopyWith<_$ContentItemImpl> get copyWith =>
      __$$ContentItemImplCopyWithImpl<_$ContentItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContentItemImplToJson(
      this,
    );
  }
}

abstract class _ContentItem implements ContentItem {
  const factory _ContentItem(
      {required final String type,
      final String? identifier,
      final String? text,
      final List<ContentItem> items}) = _$ContentItemImpl;

  factory _ContentItem.fromJson(Map<String, dynamic> json) =
      _$ContentItemImpl.fromJson;

  @override
  String get type;
  @override
  String? get identifier;
  @override
  String? get text;
  @override
  List<ContentItem> get items;

  /// Create a copy of ContentItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContentItemImplCopyWith<_$ContentItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AlignedSentence _$AlignedSentenceFromJson(Map<String, dynamic> json) {
  return _AlignedSentence.fromJson(json);
}

/// @nodoc
mixin _$AlignedSentence {
  String get np => throw _privateConstructorUsedError;
  String get en => throw _privateConstructorUsedError;

  /// Serializes this AlignedSentence to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlignedSentence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlignedSentenceCopyWith<AlignedSentence> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlignedSentenceCopyWith<$Res> {
  factory $AlignedSentenceCopyWith(
          AlignedSentence value, $Res Function(AlignedSentence) then) =
      _$AlignedSentenceCopyWithImpl<$Res, AlignedSentence>;
  @useResult
  $Res call({String np, String en});
}

/// @nodoc
class _$AlignedSentenceCopyWithImpl<$Res, $Val extends AlignedSentence>
    implements $AlignedSentenceCopyWith<$Res> {
  _$AlignedSentenceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlignedSentence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? np = null,
    Object? en = null,
  }) {
    return _then(_value.copyWith(
      np: null == np
          ? _value.np
          : np // ignore: cast_nullable_to_non_nullable
              as String,
      en: null == en
          ? _value.en
          : en // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlignedSentenceImplCopyWith<$Res>
    implements $AlignedSentenceCopyWith<$Res> {
  factory _$$AlignedSentenceImplCopyWith(_$AlignedSentenceImpl value,
          $Res Function(_$AlignedSentenceImpl) then) =
      __$$AlignedSentenceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String np, String en});
}

/// @nodoc
class __$$AlignedSentenceImplCopyWithImpl<$Res>
    extends _$AlignedSentenceCopyWithImpl<$Res, _$AlignedSentenceImpl>
    implements _$$AlignedSentenceImplCopyWith<$Res> {
  __$$AlignedSentenceImplCopyWithImpl(
      _$AlignedSentenceImpl _value, $Res Function(_$AlignedSentenceImpl) _then)
      : super(_value, _then);

  /// Create a copy of AlignedSentence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? np = null,
    Object? en = null,
  }) {
    return _then(_$AlignedSentenceImpl(
      np: null == np
          ? _value.np
          : np // ignore: cast_nullable_to_non_nullable
              as String,
      en: null == en
          ? _value.en
          : en // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlignedSentenceImpl implements _AlignedSentence {
  const _$AlignedSentenceImpl({required this.np, required this.en});

  factory _$AlignedSentenceImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlignedSentenceImplFromJson(json);

  @override
  final String np;
  @override
  final String en;

  @override
  String toString() {
    return 'AlignedSentence(np: $np, en: $en)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlignedSentenceImpl &&
            (identical(other.np, np) || other.np == np) &&
            (identical(other.en, en) || other.en == en));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, np, en);

  /// Create a copy of AlignedSentence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlignedSentenceImplCopyWith<_$AlignedSentenceImpl> get copyWith =>
      __$$AlignedSentenceImplCopyWithImpl<_$AlignedSentenceImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlignedSentenceImplToJson(
      this,
    );
  }
}

abstract class _AlignedSentence implements AlignedSentence {
  const factory _AlignedSentence(
      {required final String np,
      required final String en}) = _$AlignedSentenceImpl;

  factory _AlignedSentence.fromJson(Map<String, dynamic> json) =
      _$AlignedSentenceImpl.fromJson;

  @override
  String get np;
  @override
  String get en;

  /// Create a copy of AlignedSentence
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlignedSentenceImplCopyWith<_$AlignedSentenceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
