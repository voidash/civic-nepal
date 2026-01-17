// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'district.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DistrictData {
  Map<String, DistrictInfo> get districts => throw _privateConstructorUsedError;

  /// Create a copy of DistrictData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DistrictDataCopyWith<DistrictData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DistrictDataCopyWith<$Res> {
  factory $DistrictDataCopyWith(
          DistrictData value, $Res Function(DistrictData) then) =
      _$DistrictDataCopyWithImpl<$Res, DistrictData>;
  @useResult
  $Res call({Map<String, DistrictInfo> districts});
}

/// @nodoc
class _$DistrictDataCopyWithImpl<$Res, $Val extends DistrictData>
    implements $DistrictDataCopyWith<$Res> {
  _$DistrictDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DistrictData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? districts = null,
  }) {
    return _then(_value.copyWith(
      districts: null == districts
          ? _value.districts
          : districts // ignore: cast_nullable_to_non_nullable
              as Map<String, DistrictInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DistrictDataImplCopyWith<$Res>
    implements $DistrictDataCopyWith<$Res> {
  factory _$$DistrictDataImplCopyWith(
          _$DistrictDataImpl value, $Res Function(_$DistrictDataImpl) then) =
      __$$DistrictDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, DistrictInfo> districts});
}

/// @nodoc
class __$$DistrictDataImplCopyWithImpl<$Res>
    extends _$DistrictDataCopyWithImpl<$Res, _$DistrictDataImpl>
    implements _$$DistrictDataImplCopyWith<$Res> {
  __$$DistrictDataImplCopyWithImpl(
      _$DistrictDataImpl _value, $Res Function(_$DistrictDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of DistrictData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? districts = null,
  }) {
    return _then(_$DistrictDataImpl(
      districts: null == districts
          ? _value._districts
          : districts // ignore: cast_nullable_to_non_nullable
              as Map<String, DistrictInfo>,
    ));
  }
}

/// @nodoc

class _$DistrictDataImpl implements _DistrictData {
  const _$DistrictDataImpl({required final Map<String, DistrictInfo> districts})
      : _districts = districts;

  final Map<String, DistrictInfo> _districts;
  @override
  Map<String, DistrictInfo> get districts {
    if (_districts is EqualUnmodifiableMapView) return _districts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_districts);
  }

  @override
  String toString() {
    return 'DistrictData(districts: $districts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DistrictDataImpl &&
            const DeepCollectionEquality()
                .equals(other._districts, _districts));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_districts));

  /// Create a copy of DistrictData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DistrictDataImplCopyWith<_$DistrictDataImpl> get copyWith =>
      __$$DistrictDataImplCopyWithImpl<_$DistrictDataImpl>(this, _$identity);
}

abstract class _DistrictData implements DistrictData {
  const factory _DistrictData(
          {required final Map<String, DistrictInfo> districts}) =
      _$DistrictDataImpl;

  @override
  Map<String, DistrictInfo> get districts;

  /// Create a copy of DistrictData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DistrictDataImplCopyWith<_$DistrictDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DistrictInfo _$DistrictInfoFromJson(Map<String, dynamic> json) {
  return _DistrictInfo.fromJson(json);
}

/// @nodoc
mixin _$DistrictInfo {
  String get name => throw _privateConstructorUsedError;
  int get province => throw _privateConstructorUsedError;

  /// Serializes this DistrictInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DistrictInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DistrictInfoCopyWith<DistrictInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DistrictInfoCopyWith<$Res> {
  factory $DistrictInfoCopyWith(
          DistrictInfo value, $Res Function(DistrictInfo) then) =
      _$DistrictInfoCopyWithImpl<$Res, DistrictInfo>;
  @useResult
  $Res call({String name, int province});
}

/// @nodoc
class _$DistrictInfoCopyWithImpl<$Res, $Val extends DistrictInfo>
    implements $DistrictInfoCopyWith<$Res> {
  _$DistrictInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DistrictInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? province = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      province: null == province
          ? _value.province
          : province // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DistrictInfoImplCopyWith<$Res>
    implements $DistrictInfoCopyWith<$Res> {
  factory _$$DistrictInfoImplCopyWith(
          _$DistrictInfoImpl value, $Res Function(_$DistrictInfoImpl) then) =
      __$$DistrictInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, int province});
}

/// @nodoc
class __$$DistrictInfoImplCopyWithImpl<$Res>
    extends _$DistrictInfoCopyWithImpl<$Res, _$DistrictInfoImpl>
    implements _$$DistrictInfoImplCopyWith<$Res> {
  __$$DistrictInfoImplCopyWithImpl(
      _$DistrictInfoImpl _value, $Res Function(_$DistrictInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of DistrictInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? province = null,
  }) {
    return _then(_$DistrictInfoImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      province: null == province
          ? _value.province
          : province // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DistrictInfoImpl implements _DistrictInfo {
  const _$DistrictInfoImpl({required this.name, required this.province});

  factory _$DistrictInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$DistrictInfoImplFromJson(json);

  @override
  final String name;
  @override
  final int province;

  @override
  String toString() {
    return 'DistrictInfo(name: $name, province: $province)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DistrictInfoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.province, province) ||
                other.province == province));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, province);

  /// Create a copy of DistrictInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DistrictInfoImplCopyWith<_$DistrictInfoImpl> get copyWith =>
      __$$DistrictInfoImplCopyWithImpl<_$DistrictInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DistrictInfoImplToJson(
      this,
    );
  }
}

abstract class _DistrictInfo implements DistrictInfo {
  const factory _DistrictInfo(
      {required final String name,
      required final int province}) = _$DistrictInfoImpl;

  factory _DistrictInfo.fromJson(Map<String, dynamic> json) =
      _$DistrictInfoImpl.fromJson;

  @override
  String get name;
  @override
  int get province;

  /// Create a copy of DistrictInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DistrictInfoImplCopyWith<_$DistrictInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PartyData _$PartyDataFromJson(Map<String, dynamic> json) {
  return _PartyData.fromJson(json);
}

/// @nodoc
mixin _$PartyData {
  String get version => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  List<Party> get parties => throw _privateConstructorUsedError;

  /// Serializes this PartyData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PartyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PartyDataCopyWith<PartyData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PartyDataCopyWith<$Res> {
  factory $PartyDataCopyWith(PartyData value, $Res Function(PartyData) then) =
      _$PartyDataCopyWithImpl<$Res, PartyData>;
  @useResult
  $Res call({String version, int count, List<Party> parties});
}

/// @nodoc
class _$PartyDataCopyWithImpl<$Res, $Val extends PartyData>
    implements $PartyDataCopyWith<$Res> {
  _$PartyDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PartyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? count = null,
    Object? parties = null,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      parties: null == parties
          ? _value.parties
          : parties // ignore: cast_nullable_to_non_nullable
              as List<Party>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PartyDataImplCopyWith<$Res>
    implements $PartyDataCopyWith<$Res> {
  factory _$$PartyDataImplCopyWith(
          _$PartyDataImpl value, $Res Function(_$PartyDataImpl) then) =
      __$$PartyDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String version, int count, List<Party> parties});
}

/// @nodoc
class __$$PartyDataImplCopyWithImpl<$Res>
    extends _$PartyDataCopyWithImpl<$Res, _$PartyDataImpl>
    implements _$$PartyDataImplCopyWith<$Res> {
  __$$PartyDataImplCopyWithImpl(
      _$PartyDataImpl _value, $Res Function(_$PartyDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of PartyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? count = null,
    Object? parties = null,
  }) {
    return _then(_$PartyDataImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      parties: null == parties
          ? _value._parties
          : parties // ignore: cast_nullable_to_non_nullable
              as List<Party>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PartyDataImpl implements _PartyData {
  const _$PartyDataImpl(
      {required this.version,
      required this.count,
      required final List<Party> parties})
      : _parties = parties;

  factory _$PartyDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$PartyDataImplFromJson(json);

  @override
  final String version;
  @override
  final int count;
  final List<Party> _parties;
  @override
  List<Party> get parties {
    if (_parties is EqualUnmodifiableListView) return _parties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parties);
  }

  @override
  String toString() {
    return 'PartyData(version: $version, count: $count, parties: $parties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PartyDataImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.count, count) || other.count == count) &&
            const DeepCollectionEquality().equals(other._parties, _parties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, version, count,
      const DeepCollectionEquality().hash(_parties));

  /// Create a copy of PartyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PartyDataImplCopyWith<_$PartyDataImpl> get copyWith =>
      __$$PartyDataImplCopyWithImpl<_$PartyDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PartyDataImplToJson(
      this,
    );
  }
}

abstract class _PartyData implements PartyData {
  const factory _PartyData(
      {required final String version,
      required final int count,
      required final List<Party> parties}) = _$PartyDataImpl;

  factory _PartyData.fromJson(Map<String, dynamic> json) =
      _$PartyDataImpl.fromJson;

  @override
  String get version;
  @override
  int get count;
  @override
  List<Party> get parties;

  /// Create a copy of PartyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PartyDataImplCopyWith<_$PartyDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Party _$PartyFromJson(Map<String, dynamic> json) {
  return _Party.fromJson(json);
}

/// @nodoc
mixin _$Party {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get shortName => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  int get leaderCount => throw _privateConstructorUsedError;

  /// Serializes this Party to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Party
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PartyCopyWith<Party> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PartyCopyWith<$Res> {
  factory $PartyCopyWith(Party value, $Res Function(Party) then) =
      _$PartyCopyWithImpl<$Res, Party>;
  @useResult
  $Res call(
      {String id,
      String name,
      String shortName,
      String color,
      int leaderCount});
}

/// @nodoc
class _$PartyCopyWithImpl<$Res, $Val extends Party>
    implements $PartyCopyWith<$Res> {
  _$PartyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Party
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? shortName = null,
    Object? color = null,
    Object? leaderCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      shortName: null == shortName
          ? _value.shortName
          : shortName // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      leaderCount: null == leaderCount
          ? _value.leaderCount
          : leaderCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PartyImplCopyWith<$Res> implements $PartyCopyWith<$Res> {
  factory _$$PartyImplCopyWith(
          _$PartyImpl value, $Res Function(_$PartyImpl) then) =
      __$$PartyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String shortName,
      String color,
      int leaderCount});
}

/// @nodoc
class __$$PartyImplCopyWithImpl<$Res>
    extends _$PartyCopyWithImpl<$Res, _$PartyImpl>
    implements _$$PartyImplCopyWith<$Res> {
  __$$PartyImplCopyWithImpl(
      _$PartyImpl _value, $Res Function(_$PartyImpl) _then)
      : super(_value, _then);

  /// Create a copy of Party
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? shortName = null,
    Object? color = null,
    Object? leaderCount = null,
  }) {
    return _then(_$PartyImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      shortName: null == shortName
          ? _value.shortName
          : shortName // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      leaderCount: null == leaderCount
          ? _value.leaderCount
          : leaderCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PartyImpl implements _Party {
  const _$PartyImpl(
      {required this.id,
      required this.name,
      required this.shortName,
      required this.color,
      required this.leaderCount});

  factory _$PartyImpl.fromJson(Map<String, dynamic> json) =>
      _$$PartyImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String shortName;
  @override
  final String color;
  @override
  final int leaderCount;

  @override
  String toString() {
    return 'Party(id: $id, name: $name, shortName: $shortName, color: $color, leaderCount: $leaderCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PartyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.leaderCount, leaderCount) ||
                other.leaderCount == leaderCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, shortName, color, leaderCount);

  /// Create a copy of Party
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PartyImplCopyWith<_$PartyImpl> get copyWith =>
      __$$PartyImplCopyWithImpl<_$PartyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PartyImplToJson(
      this,
    );
  }
}

abstract class _Party implements Party {
  const factory _Party(
      {required final String id,
      required final String name,
      required final String shortName,
      required final String color,
      required final int leaderCount}) = _$PartyImpl;

  factory _Party.fromJson(Map<String, dynamic> json) = _$PartyImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get shortName;
  @override
  String get color;
  @override
  int get leaderCount;

  /// Create a copy of Party
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PartyImplCopyWith<_$PartyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
