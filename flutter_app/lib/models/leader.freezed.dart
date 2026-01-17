// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leader.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LeadersData _$LeadersDataFromJson(Map<String, dynamic> json) {
  return _LeadersData.fromJson(json);
}

/// @nodoc
mixin _$LeadersData {
  String get version => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  List<Leader> get leaders => throw _privateConstructorUsedError;

  /// Serializes this LeadersData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LeadersData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LeadersDataCopyWith<LeadersData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeadersDataCopyWith<$Res> {
  factory $LeadersDataCopyWith(
          LeadersData value, $Res Function(LeadersData) then) =
      _$LeadersDataCopyWithImpl<$Res, LeadersData>;
  @useResult
  $Res call({String version, int count, List<Leader> leaders});
}

/// @nodoc
class _$LeadersDataCopyWithImpl<$Res, $Val extends LeadersData>
    implements $LeadersDataCopyWith<$Res> {
  _$LeadersDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LeadersData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? count = null,
    Object? leaders = null,
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
      leaders: null == leaders
          ? _value.leaders
          : leaders // ignore: cast_nullable_to_non_nullable
              as List<Leader>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LeadersDataImplCopyWith<$Res>
    implements $LeadersDataCopyWith<$Res> {
  factory _$$LeadersDataImplCopyWith(
          _$LeadersDataImpl value, $Res Function(_$LeadersDataImpl) then) =
      __$$LeadersDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String version, int count, List<Leader> leaders});
}

/// @nodoc
class __$$LeadersDataImplCopyWithImpl<$Res>
    extends _$LeadersDataCopyWithImpl<$Res, _$LeadersDataImpl>
    implements _$$LeadersDataImplCopyWith<$Res> {
  __$$LeadersDataImplCopyWithImpl(
      _$LeadersDataImpl _value, $Res Function(_$LeadersDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of LeadersData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? count = null,
    Object? leaders = null,
  }) {
    return _then(_$LeadersDataImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      leaders: null == leaders
          ? _value._leaders
          : leaders // ignore: cast_nullable_to_non_nullable
              as List<Leader>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LeadersDataImpl implements _LeadersData {
  const _$LeadersDataImpl(
      {required this.version,
      required this.count,
      required final List<Leader> leaders})
      : _leaders = leaders;

  factory _$LeadersDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$LeadersDataImplFromJson(json);

  @override
  final String version;
  @override
  final int count;
  final List<Leader> _leaders;
  @override
  List<Leader> get leaders {
    if (_leaders is EqualUnmodifiableListView) return _leaders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_leaders);
  }

  @override
  String toString() {
    return 'LeadersData(version: $version, count: $count, leaders: $leaders)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeadersDataImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.count, count) || other.count == count) &&
            const DeepCollectionEquality().equals(other._leaders, _leaders));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, version, count,
      const DeepCollectionEquality().hash(_leaders));

  /// Create a copy of LeadersData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LeadersDataImplCopyWith<_$LeadersDataImpl> get copyWith =>
      __$$LeadersDataImplCopyWithImpl<_$LeadersDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LeadersDataImplToJson(
      this,
    );
  }
}

abstract class _LeadersData implements LeadersData {
  const factory _LeadersData(
      {required final String version,
      required final int count,
      required final List<Leader> leaders}) = _$LeadersDataImpl;

  factory _LeadersData.fromJson(Map<String, dynamic> json) =
      _$LeadersDataImpl.fromJson;

  @override
  String get version;
  @override
  int get count;
  @override
  List<Leader> get leaders;

  /// Create a copy of LeadersData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LeadersDataImplCopyWith<_$LeadersDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Leader _$LeaderFromJson(Map<String, dynamic> json) {
  return _Leader.fromJson(json);
}

/// @nodoc
mixin _$Leader {
  @JsonKey(name: '_id')
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get party => throw _privateConstructorUsedError;
  String get position => throw _privateConstructorUsedError;
  String? get district => throw _privateConstructorUsedError;
  String get biography => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  bool get featured => throw _privateConstructorUsedError;
  int get upvotes => throw _privateConstructorUsedError;
  int get downvotes => throw _privateConstructorUsedError;
  int get totalVotes => throw _privateConstructorUsedError;

  /// Serializes this Leader to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Leader
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LeaderCopyWith<Leader> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaderCopyWith<$Res> {
  factory $LeaderCopyWith(Leader value, $Res Function(Leader) then) =
      _$LeaderCopyWithImpl<$Res, Leader>;
  @useResult
  $Res call(
      {@JsonKey(name: '_id') String id,
      String name,
      String party,
      String position,
      String? district,
      String biography,
      String imageUrl,
      bool featured,
      int upvotes,
      int downvotes,
      int totalVotes});
}

/// @nodoc
class _$LeaderCopyWithImpl<$Res, $Val extends Leader>
    implements $LeaderCopyWith<$Res> {
  _$LeaderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Leader
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? party = null,
    Object? position = null,
    Object? district = freezed,
    Object? biography = null,
    Object? imageUrl = null,
    Object? featured = null,
    Object? upvotes = null,
    Object? downvotes = null,
    Object? totalVotes = null,
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
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String,
      district: freezed == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String?,
      biography: null == biography
          ? _value.biography
          : biography // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      featured: null == featured
          ? _value.featured
          : featured // ignore: cast_nullable_to_non_nullable
              as bool,
      upvotes: null == upvotes
          ? _value.upvotes
          : upvotes // ignore: cast_nullable_to_non_nullable
              as int,
      downvotes: null == downvotes
          ? _value.downvotes
          : downvotes // ignore: cast_nullable_to_non_nullable
              as int,
      totalVotes: null == totalVotes
          ? _value.totalVotes
          : totalVotes // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LeaderImplCopyWith<$Res> implements $LeaderCopyWith<$Res> {
  factory _$$LeaderImplCopyWith(
          _$LeaderImpl value, $Res Function(_$LeaderImpl) then) =
      __$$LeaderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: '_id') String id,
      String name,
      String party,
      String position,
      String? district,
      String biography,
      String imageUrl,
      bool featured,
      int upvotes,
      int downvotes,
      int totalVotes});
}

/// @nodoc
class __$$LeaderImplCopyWithImpl<$Res>
    extends _$LeaderCopyWithImpl<$Res, _$LeaderImpl>
    implements _$$LeaderImplCopyWith<$Res> {
  __$$LeaderImplCopyWithImpl(
      _$LeaderImpl _value, $Res Function(_$LeaderImpl) _then)
      : super(_value, _then);

  /// Create a copy of Leader
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? party = null,
    Object? position = null,
    Object? district = freezed,
    Object? biography = null,
    Object? imageUrl = null,
    Object? featured = null,
    Object? upvotes = null,
    Object? downvotes = null,
    Object? totalVotes = null,
  }) {
    return _then(_$LeaderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String,
      district: freezed == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String?,
      biography: null == biography
          ? _value.biography
          : biography // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      featured: null == featured
          ? _value.featured
          : featured // ignore: cast_nullable_to_non_nullable
              as bool,
      upvotes: null == upvotes
          ? _value.upvotes
          : upvotes // ignore: cast_nullable_to_non_nullable
              as int,
      downvotes: null == downvotes
          ? _value.downvotes
          : downvotes // ignore: cast_nullable_to_non_nullable
              as int,
      totalVotes: null == totalVotes
          ? _value.totalVotes
          : totalVotes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LeaderImpl implements _Leader {
  const _$LeaderImpl(
      {@JsonKey(name: '_id') required this.id,
      required this.name,
      required this.party,
      required this.position,
      required this.district,
      required this.biography,
      required this.imageUrl,
      this.featured = false,
      required this.upvotes,
      required this.downvotes,
      required this.totalVotes});

  factory _$LeaderImpl.fromJson(Map<String, dynamic> json) =>
      _$$LeaderImplFromJson(json);

  @override
  @JsonKey(name: '_id')
  final String id;
  @override
  final String name;
  @override
  final String party;
  @override
  final String position;
  @override
  final String? district;
  @override
  final String biography;
  @override
  final String imageUrl;
  @override
  @JsonKey()
  final bool featured;
  @override
  final int upvotes;
  @override
  final int downvotes;
  @override
  final int totalVotes;

  @override
  String toString() {
    return 'Leader(id: $id, name: $name, party: $party, position: $position, district: $district, biography: $biography, imageUrl: $imageUrl, featured: $featured, upvotes: $upvotes, downvotes: $downvotes, totalVotes: $totalVotes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.party, party) || other.party == party) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.biography, biography) ||
                other.biography == biography) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.featured, featured) ||
                other.featured == featured) &&
            (identical(other.upvotes, upvotes) || other.upvotes == upvotes) &&
            (identical(other.downvotes, downvotes) ||
                other.downvotes == downvotes) &&
            (identical(other.totalVotes, totalVotes) ||
                other.totalVotes == totalVotes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, party, position,
      district, biography, imageUrl, featured, upvotes, downvotes, totalVotes);

  /// Create a copy of Leader
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaderImplCopyWith<_$LeaderImpl> get copyWith =>
      __$$LeaderImplCopyWithImpl<_$LeaderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LeaderImplToJson(
      this,
    );
  }
}

abstract class _Leader implements Leader {
  const factory _Leader(
      {@JsonKey(name: '_id') required final String id,
      required final String name,
      required final String party,
      required final String position,
      required final String? district,
      required final String biography,
      required final String imageUrl,
      final bool featured,
      required final int upvotes,
      required final int downvotes,
      required final int totalVotes}) = _$LeaderImpl;

  factory _Leader.fromJson(Map<String, dynamic> json) = _$LeaderImpl.fromJson;

  @override
  @JsonKey(name: '_id')
  String get id;
  @override
  String get name;
  @override
  String get party;
  @override
  String get position;
  @override
  String? get district;
  @override
  String get biography;
  @override
  String get imageUrl;
  @override
  bool get featured;
  @override
  int get upvotes;
  @override
  int get downvotes;
  @override
  int get totalVotes;

  /// Create a copy of Leader
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LeaderImplCopyWith<_$LeaderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
