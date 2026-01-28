// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'constituency.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ConstituencyData _$ConstituencyDataFromJson(Map<String, dynamic> json) {
  return _ConstituencyData.fromJson(json);
}

/// @nodoc
mixin _$ConstituencyData {
  String get version => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'scraped_at')
  String get scrapedAt => throw _privateConstructorUsedError;
  int get totalConstituencies => throw _privateConstructorUsedError;
  Map<String, List<Constituency>> get districts =>
      throw _privateConstructorUsedError;

  /// Serializes this ConstituencyData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConstituencyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConstituencyDataCopyWith<ConstituencyData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConstituencyDataCopyWith<$Res> {
  factory $ConstituencyDataCopyWith(
          ConstituencyData value, $Res Function(ConstituencyData) then) =
      _$ConstituencyDataCopyWithImpl<$Res, ConstituencyData>;
  @useResult
  $Res call(
      {String version,
      String source,
      @JsonKey(name: 'scraped_at') String scrapedAt,
      int totalConstituencies,
      Map<String, List<Constituency>> districts});
}

/// @nodoc
class _$ConstituencyDataCopyWithImpl<$Res, $Val extends ConstituencyData>
    implements $ConstituencyDataCopyWith<$Res> {
  _$ConstituencyDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConstituencyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? source = null,
    Object? scrapedAt = null,
    Object? totalConstituencies = null,
    Object? districts = null,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      scrapedAt: null == scrapedAt
          ? _value.scrapedAt
          : scrapedAt // ignore: cast_nullable_to_non_nullable
              as String,
      totalConstituencies: null == totalConstituencies
          ? _value.totalConstituencies
          : totalConstituencies // ignore: cast_nullable_to_non_nullable
              as int,
      districts: null == districts
          ? _value.districts
          : districts // ignore: cast_nullable_to_non_nullable
              as Map<String, List<Constituency>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConstituencyDataImplCopyWith<$Res>
    implements $ConstituencyDataCopyWith<$Res> {
  factory _$$ConstituencyDataImplCopyWith(_$ConstituencyDataImpl value,
          $Res Function(_$ConstituencyDataImpl) then) =
      __$$ConstituencyDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String version,
      String source,
      @JsonKey(name: 'scraped_at') String scrapedAt,
      int totalConstituencies,
      Map<String, List<Constituency>> districts});
}

/// @nodoc
class __$$ConstituencyDataImplCopyWithImpl<$Res>
    extends _$ConstituencyDataCopyWithImpl<$Res, _$ConstituencyDataImpl>
    implements _$$ConstituencyDataImplCopyWith<$Res> {
  __$$ConstituencyDataImplCopyWithImpl(_$ConstituencyDataImpl _value,
      $Res Function(_$ConstituencyDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConstituencyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? source = null,
    Object? scrapedAt = null,
    Object? totalConstituencies = null,
    Object? districts = null,
  }) {
    return _then(_$ConstituencyDataImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      scrapedAt: null == scrapedAt
          ? _value.scrapedAt
          : scrapedAt // ignore: cast_nullable_to_non_nullable
              as String,
      totalConstituencies: null == totalConstituencies
          ? _value.totalConstituencies
          : totalConstituencies // ignore: cast_nullable_to_non_nullable
              as int,
      districts: null == districts
          ? _value._districts
          : districts // ignore: cast_nullable_to_non_nullable
              as Map<String, List<Constituency>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConstituencyDataImpl implements _ConstituencyData {
  const _$ConstituencyDataImpl(
      {required this.version,
      required this.source,
      @JsonKey(name: 'scraped_at') required this.scrapedAt,
      required this.totalConstituencies,
      required final Map<String, List<Constituency>> districts})
      : _districts = districts;

  factory _$ConstituencyDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConstituencyDataImplFromJson(json);

  @override
  final String version;
  @override
  final String source;
  @override
  @JsonKey(name: 'scraped_at')
  final String scrapedAt;
  @override
  final int totalConstituencies;
  final Map<String, List<Constituency>> _districts;
  @override
  Map<String, List<Constituency>> get districts {
    if (_districts is EqualUnmodifiableMapView) return _districts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_districts);
  }

  @override
  String toString() {
    return 'ConstituencyData(version: $version, source: $source, scrapedAt: $scrapedAt, totalConstituencies: $totalConstituencies, districts: $districts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConstituencyDataImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.scrapedAt, scrapedAt) ||
                other.scrapedAt == scrapedAt) &&
            (identical(other.totalConstituencies, totalConstituencies) ||
                other.totalConstituencies == totalConstituencies) &&
            const DeepCollectionEquality()
                .equals(other._districts, _districts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, version, source, scrapedAt,
      totalConstituencies, const DeepCollectionEquality().hash(_districts));

  /// Create a copy of ConstituencyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConstituencyDataImplCopyWith<_$ConstituencyDataImpl> get copyWith =>
      __$$ConstituencyDataImplCopyWithImpl<_$ConstituencyDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConstituencyDataImplToJson(
      this,
    );
  }
}

abstract class _ConstituencyData implements ConstituencyData {
  const factory _ConstituencyData(
          {required final String version,
          required final String source,
          @JsonKey(name: 'scraped_at') required final String scrapedAt,
          required final int totalConstituencies,
          required final Map<String, List<Constituency>> districts}) =
      _$ConstituencyDataImpl;

  factory _ConstituencyData.fromJson(Map<String, dynamic> json) =
      _$ConstituencyDataImpl.fromJson;

  @override
  String get version;
  @override
  String get source;
  @override
  @JsonKey(name: 'scraped_at')
  String get scrapedAt;
  @override
  int get totalConstituencies;
  @override
  Map<String, List<Constituency>> get districts;

  /// Create a copy of ConstituencyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConstituencyDataImplCopyWith<_$ConstituencyDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Constituency _$ConstituencyFromJson(Map<String, dynamic> json) {
  return _Constituency.fromJson(json);
}

/// @nodoc
mixin _$Constituency {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get number => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  String get districtId => throw _privateConstructorUsedError;
  int get province => throw _privateConstructorUsedError;
  List<Candidate> get candidates => throw _privateConstructorUsedError;
  String get svgPathId => throw _privateConstructorUsedError;
  String get svgPathD => throw _privateConstructorUsedError;

  /// Serializes this Constituency to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Constituency
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConstituencyCopyWith<Constituency> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConstituencyCopyWith<$Res> {
  factory $ConstituencyCopyWith(
          Constituency value, $Res Function(Constituency) then) =
      _$ConstituencyCopyWithImpl<$Res, Constituency>;
  @useResult
  $Res call(
      {String id,
      String name,
      int number,
      String district,
      String districtId,
      int province,
      List<Candidate> candidates,
      String svgPathId,
      String svgPathD});
}

/// @nodoc
class _$ConstituencyCopyWithImpl<$Res, $Val extends Constituency>
    implements $ConstituencyCopyWith<$Res> {
  _$ConstituencyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Constituency
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? number = null,
    Object? district = null,
    Object? districtId = null,
    Object? province = null,
    Object? candidates = null,
    Object? svgPathId = null,
    Object? svgPathD = null,
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
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      district: null == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String,
      districtId: null == districtId
          ? _value.districtId
          : districtId // ignore: cast_nullable_to_non_nullable
              as String,
      province: null == province
          ? _value.province
          : province // ignore: cast_nullable_to_non_nullable
              as int,
      candidates: null == candidates
          ? _value.candidates
          : candidates // ignore: cast_nullable_to_non_nullable
              as List<Candidate>,
      svgPathId: null == svgPathId
          ? _value.svgPathId
          : svgPathId // ignore: cast_nullable_to_non_nullable
              as String,
      svgPathD: null == svgPathD
          ? _value.svgPathD
          : svgPathD // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConstituencyImplCopyWith<$Res>
    implements $ConstituencyCopyWith<$Res> {
  factory _$$ConstituencyImplCopyWith(
          _$ConstituencyImpl value, $Res Function(_$ConstituencyImpl) then) =
      __$$ConstituencyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      int number,
      String district,
      String districtId,
      int province,
      List<Candidate> candidates,
      String svgPathId,
      String svgPathD});
}

/// @nodoc
class __$$ConstituencyImplCopyWithImpl<$Res>
    extends _$ConstituencyCopyWithImpl<$Res, _$ConstituencyImpl>
    implements _$$ConstituencyImplCopyWith<$Res> {
  __$$ConstituencyImplCopyWithImpl(
      _$ConstituencyImpl _value, $Res Function(_$ConstituencyImpl) _then)
      : super(_value, _then);

  /// Create a copy of Constituency
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? number = null,
    Object? district = null,
    Object? districtId = null,
    Object? province = null,
    Object? candidates = null,
    Object? svgPathId = null,
    Object? svgPathD = null,
  }) {
    return _then(_$ConstituencyImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      district: null == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String,
      districtId: null == districtId
          ? _value.districtId
          : districtId // ignore: cast_nullable_to_non_nullable
              as String,
      province: null == province
          ? _value.province
          : province // ignore: cast_nullable_to_non_nullable
              as int,
      candidates: null == candidates
          ? _value._candidates
          : candidates // ignore: cast_nullable_to_non_nullable
              as List<Candidate>,
      svgPathId: null == svgPathId
          ? _value.svgPathId
          : svgPathId // ignore: cast_nullable_to_non_nullable
              as String,
      svgPathD: null == svgPathD
          ? _value.svgPathD
          : svgPathD // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConstituencyImpl implements _Constituency {
  const _$ConstituencyImpl(
      {required this.id,
      required this.name,
      required this.number,
      required this.district,
      required this.districtId,
      required this.province,
      required final List<Candidate> candidates,
      this.svgPathId = '',
      this.svgPathD = ''})
      : _candidates = candidates;

  factory _$ConstituencyImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConstituencyImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final int number;
  @override
  final String district;
  @override
  final String districtId;
  @override
  final int province;
  final List<Candidate> _candidates;
  @override
  List<Candidate> get candidates {
    if (_candidates is EqualUnmodifiableListView) return _candidates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_candidates);
  }

  @override
  @JsonKey()
  final String svgPathId;
  @override
  @JsonKey()
  final String svgPathD;

  @override
  String toString() {
    return 'Constituency(id: $id, name: $name, number: $number, district: $district, districtId: $districtId, province: $province, candidates: $candidates, svgPathId: $svgPathId, svgPathD: $svgPathD)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConstituencyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.districtId, districtId) ||
                other.districtId == districtId) &&
            (identical(other.province, province) ||
                other.province == province) &&
            const DeepCollectionEquality()
                .equals(other._candidates, _candidates) &&
            (identical(other.svgPathId, svgPathId) ||
                other.svgPathId == svgPathId) &&
            (identical(other.svgPathD, svgPathD) ||
                other.svgPathD == svgPathD));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      number,
      district,
      districtId,
      province,
      const DeepCollectionEquality().hash(_candidates),
      svgPathId,
      svgPathD);

  /// Create a copy of Constituency
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConstituencyImplCopyWith<_$ConstituencyImpl> get copyWith =>
      __$$ConstituencyImplCopyWithImpl<_$ConstituencyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConstituencyImplToJson(
      this,
    );
  }
}

abstract class _Constituency implements Constituency {
  const factory _Constituency(
      {required final String id,
      required final String name,
      required final int number,
      required final String district,
      required final String districtId,
      required final int province,
      required final List<Candidate> candidates,
      final String svgPathId,
      final String svgPathD}) = _$ConstituencyImpl;

  factory _Constituency.fromJson(Map<String, dynamic> json) =
      _$ConstituencyImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get number;
  @override
  String get district;
  @override
  String get districtId;
  @override
  int get province;
  @override
  List<Candidate> get candidates;
  @override
  String get svgPathId;
  @override
  String get svgPathD;

  /// Create a copy of Constituency
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConstituencyImplCopyWith<_$ConstituencyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Candidate _$CandidateFromJson(Map<String, dynamic> json) {
  return _Candidate.fromJson(json);
}

/// @nodoc
mixin _$Candidate {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get party => throw _privateConstructorUsedError;
  String get partySymbol => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  int get votes => throw _privateConstructorUsedError;

  /// Serializes this Candidate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Candidate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CandidateCopyWith<Candidate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CandidateCopyWith<$Res> {
  factory $CandidateCopyWith(Candidate value, $Res Function(Candidate) then) =
      _$CandidateCopyWithImpl<$Res, Candidate>;
  @useResult
  $Res call(
      {String id,
      String name,
      String party,
      String partySymbol,
      String imageUrl,
      int votes});
}

/// @nodoc
class _$CandidateCopyWithImpl<$Res, $Val extends Candidate>
    implements $CandidateCopyWith<$Res> {
  _$CandidateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Candidate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? party = null,
    Object? partySymbol = null,
    Object? imageUrl = null,
    Object? votes = null,
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
      partySymbol: null == partySymbol
          ? _value.partySymbol
          : partySymbol // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      votes: null == votes
          ? _value.votes
          : votes // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CandidateImplCopyWith<$Res>
    implements $CandidateCopyWith<$Res> {
  factory _$$CandidateImplCopyWith(
          _$CandidateImpl value, $Res Function(_$CandidateImpl) then) =
      __$$CandidateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String party,
      String partySymbol,
      String imageUrl,
      int votes});
}

/// @nodoc
class __$$CandidateImplCopyWithImpl<$Res>
    extends _$CandidateCopyWithImpl<$Res, _$CandidateImpl>
    implements _$$CandidateImplCopyWith<$Res> {
  __$$CandidateImplCopyWithImpl(
      _$CandidateImpl _value, $Res Function(_$CandidateImpl) _then)
      : super(_value, _then);

  /// Create a copy of Candidate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? party = null,
    Object? partySymbol = null,
    Object? imageUrl = null,
    Object? votes = null,
  }) {
    return _then(_$CandidateImpl(
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
      partySymbol: null == partySymbol
          ? _value.partySymbol
          : partySymbol // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      votes: null == votes
          ? _value.votes
          : votes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CandidateImpl implements _Candidate {
  const _$CandidateImpl(
      {required this.id,
      required this.name,
      required this.party,
      this.partySymbol = '',
      this.imageUrl = '',
      this.votes = 0});

  factory _$CandidateImpl.fromJson(Map<String, dynamic> json) =>
      _$$CandidateImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String party;
  @override
  @JsonKey()
  final String partySymbol;
  @override
  @JsonKey()
  final String imageUrl;
  @override
  @JsonKey()
  final int votes;

  @override
  String toString() {
    return 'Candidate(id: $id, name: $name, party: $party, partySymbol: $partySymbol, imageUrl: $imageUrl, votes: $votes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CandidateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.party, party) || other.party == party) &&
            (identical(other.partySymbol, partySymbol) ||
                other.partySymbol == partySymbol) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.votes, votes) || other.votes == votes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, party, partySymbol, imageUrl, votes);

  /// Create a copy of Candidate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CandidateImplCopyWith<_$CandidateImpl> get copyWith =>
      __$$CandidateImplCopyWithImpl<_$CandidateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CandidateImplToJson(
      this,
    );
  }
}

abstract class _Candidate implements Candidate {
  const factory _Candidate(
      {required final String id,
      required final String name,
      required final String party,
      final String partySymbol,
      final String imageUrl,
      final int votes}) = _$CandidateImpl;

  factory _Candidate.fromJson(Map<String, dynamic> json) =
      _$CandidateImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get party;
  @override
  String get partySymbol;
  @override
  String get imageUrl;
  @override
  int get votes;

  /// Create a copy of Candidate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CandidateImplCopyWith<_$CandidateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
