// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'terminal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TerminalError {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(BigInt field0) sessionNotFound,
    required TResult Function(BigInt field0) sessionExited,
    required TResult Function(BigInt field0) inputChannelClosed,
    required TResult Function(String field0) spawnFailed,
    required TResult Function(String field0) ptyError,
    required TResult Function(String field0) serialization,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(BigInt field0)? sessionNotFound,
    TResult? Function(BigInt field0)? sessionExited,
    TResult? Function(BigInt field0)? inputChannelClosed,
    TResult? Function(String field0)? spawnFailed,
    TResult? Function(String field0)? ptyError,
    TResult? Function(String field0)? serialization,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(BigInt field0)? sessionNotFound,
    TResult Function(BigInt field0)? sessionExited,
    TResult Function(BigInt field0)? inputChannelClosed,
    TResult Function(String field0)? spawnFailed,
    TResult Function(String field0)? ptyError,
    TResult Function(String field0)? serialization,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TerminalError_SessionNotFound value)
    sessionNotFound,
    required TResult Function(TerminalError_SessionExited value) sessionExited,
    required TResult Function(TerminalError_InputChannelClosed value)
    inputChannelClosed,
    required TResult Function(TerminalError_SpawnFailed value) spawnFailed,
    required TResult Function(TerminalError_PtyError value) ptyError,
    required TResult Function(TerminalError_Serialization value) serialization,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult? Function(TerminalError_SessionExited value)? sessionExited,
    TResult? Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult? Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult? Function(TerminalError_PtyError value)? ptyError,
    TResult? Function(TerminalError_Serialization value)? serialization,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult Function(TerminalError_SessionExited value)? sessionExited,
    TResult Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult Function(TerminalError_PtyError value)? ptyError,
    TResult Function(TerminalError_Serialization value)? serialization,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TerminalErrorCopyWith<$Res> {
  factory $TerminalErrorCopyWith(
    TerminalError value,
    $Res Function(TerminalError) then,
  ) = _$TerminalErrorCopyWithImpl<$Res, TerminalError>;
}

/// @nodoc
class _$TerminalErrorCopyWithImpl<$Res, $Val extends TerminalError>
    implements $TerminalErrorCopyWith<$Res> {
  _$TerminalErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$TerminalError_SessionNotFoundImplCopyWith<$Res> {
  factory _$$TerminalError_SessionNotFoundImplCopyWith(
    _$TerminalError_SessionNotFoundImpl value,
    $Res Function(_$TerminalError_SessionNotFoundImpl) then,
  ) = __$$TerminalError_SessionNotFoundImplCopyWithImpl<$Res>;
  @useResult
  $Res call({BigInt field0});
}

/// @nodoc
class __$$TerminalError_SessionNotFoundImplCopyWithImpl<$Res>
    extends
        _$TerminalErrorCopyWithImpl<$Res, _$TerminalError_SessionNotFoundImpl>
    implements _$$TerminalError_SessionNotFoundImplCopyWith<$Res> {
  __$$TerminalError_SessionNotFoundImplCopyWithImpl(
    _$TerminalError_SessionNotFoundImpl _value,
    $Res Function(_$TerminalError_SessionNotFoundImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$TerminalError_SessionNotFoundImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as BigInt,
      ),
    );
  }
}

/// @nodoc

class _$TerminalError_SessionNotFoundImpl
    extends TerminalError_SessionNotFound {
  const _$TerminalError_SessionNotFoundImpl(this.field0) : super._();

  @override
  final BigInt field0;

  @override
  String toString() {
    return 'TerminalError.sessionNotFound(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TerminalError_SessionNotFoundImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TerminalError_SessionNotFoundImplCopyWith<
    _$TerminalError_SessionNotFoundImpl
  >
  get copyWith =>
      __$$TerminalError_SessionNotFoundImplCopyWithImpl<
        _$TerminalError_SessionNotFoundImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(BigInt field0) sessionNotFound,
    required TResult Function(BigInt field0) sessionExited,
    required TResult Function(BigInt field0) inputChannelClosed,
    required TResult Function(String field0) spawnFailed,
    required TResult Function(String field0) ptyError,
    required TResult Function(String field0) serialization,
  }) {
    return sessionNotFound(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(BigInt field0)? sessionNotFound,
    TResult? Function(BigInt field0)? sessionExited,
    TResult? Function(BigInt field0)? inputChannelClosed,
    TResult? Function(String field0)? spawnFailed,
    TResult? Function(String field0)? ptyError,
    TResult? Function(String field0)? serialization,
  }) {
    return sessionNotFound?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(BigInt field0)? sessionNotFound,
    TResult Function(BigInt field0)? sessionExited,
    TResult Function(BigInt field0)? inputChannelClosed,
    TResult Function(String field0)? spawnFailed,
    TResult Function(String field0)? ptyError,
    TResult Function(String field0)? serialization,
    required TResult orElse(),
  }) {
    if (sessionNotFound != null) {
      return sessionNotFound(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TerminalError_SessionNotFound value)
    sessionNotFound,
    required TResult Function(TerminalError_SessionExited value) sessionExited,
    required TResult Function(TerminalError_InputChannelClosed value)
    inputChannelClosed,
    required TResult Function(TerminalError_SpawnFailed value) spawnFailed,
    required TResult Function(TerminalError_PtyError value) ptyError,
    required TResult Function(TerminalError_Serialization value) serialization,
  }) {
    return sessionNotFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult? Function(TerminalError_SessionExited value)? sessionExited,
    TResult? Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult? Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult? Function(TerminalError_PtyError value)? ptyError,
    TResult? Function(TerminalError_Serialization value)? serialization,
  }) {
    return sessionNotFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult Function(TerminalError_SessionExited value)? sessionExited,
    TResult Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult Function(TerminalError_PtyError value)? ptyError,
    TResult Function(TerminalError_Serialization value)? serialization,
    required TResult orElse(),
  }) {
    if (sessionNotFound != null) {
      return sessionNotFound(this);
    }
    return orElse();
  }
}

abstract class TerminalError_SessionNotFound extends TerminalError {
  const factory TerminalError_SessionNotFound(final BigInt field0) =
      _$TerminalError_SessionNotFoundImpl;
  const TerminalError_SessionNotFound._() : super._();

  @override
  BigInt get field0;

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TerminalError_SessionNotFoundImplCopyWith<
    _$TerminalError_SessionNotFoundImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TerminalError_SessionExitedImplCopyWith<$Res> {
  factory _$$TerminalError_SessionExitedImplCopyWith(
    _$TerminalError_SessionExitedImpl value,
    $Res Function(_$TerminalError_SessionExitedImpl) then,
  ) = __$$TerminalError_SessionExitedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({BigInt field0});
}

/// @nodoc
class __$$TerminalError_SessionExitedImplCopyWithImpl<$Res>
    extends _$TerminalErrorCopyWithImpl<$Res, _$TerminalError_SessionExitedImpl>
    implements _$$TerminalError_SessionExitedImplCopyWith<$Res> {
  __$$TerminalError_SessionExitedImplCopyWithImpl(
    _$TerminalError_SessionExitedImpl _value,
    $Res Function(_$TerminalError_SessionExitedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$TerminalError_SessionExitedImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as BigInt,
      ),
    );
  }
}

/// @nodoc

class _$TerminalError_SessionExitedImpl extends TerminalError_SessionExited {
  const _$TerminalError_SessionExitedImpl(this.field0) : super._();

  @override
  final BigInt field0;

  @override
  String toString() {
    return 'TerminalError.sessionExited(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TerminalError_SessionExitedImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TerminalError_SessionExitedImplCopyWith<_$TerminalError_SessionExitedImpl>
  get copyWith =>
      __$$TerminalError_SessionExitedImplCopyWithImpl<
        _$TerminalError_SessionExitedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(BigInt field0) sessionNotFound,
    required TResult Function(BigInt field0) sessionExited,
    required TResult Function(BigInt field0) inputChannelClosed,
    required TResult Function(String field0) spawnFailed,
    required TResult Function(String field0) ptyError,
    required TResult Function(String field0) serialization,
  }) {
    return sessionExited(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(BigInt field0)? sessionNotFound,
    TResult? Function(BigInt field0)? sessionExited,
    TResult? Function(BigInt field0)? inputChannelClosed,
    TResult? Function(String field0)? spawnFailed,
    TResult? Function(String field0)? ptyError,
    TResult? Function(String field0)? serialization,
  }) {
    return sessionExited?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(BigInt field0)? sessionNotFound,
    TResult Function(BigInt field0)? sessionExited,
    TResult Function(BigInt field0)? inputChannelClosed,
    TResult Function(String field0)? spawnFailed,
    TResult Function(String field0)? ptyError,
    TResult Function(String field0)? serialization,
    required TResult orElse(),
  }) {
    if (sessionExited != null) {
      return sessionExited(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TerminalError_SessionNotFound value)
    sessionNotFound,
    required TResult Function(TerminalError_SessionExited value) sessionExited,
    required TResult Function(TerminalError_InputChannelClosed value)
    inputChannelClosed,
    required TResult Function(TerminalError_SpawnFailed value) spawnFailed,
    required TResult Function(TerminalError_PtyError value) ptyError,
    required TResult Function(TerminalError_Serialization value) serialization,
  }) {
    return sessionExited(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult? Function(TerminalError_SessionExited value)? sessionExited,
    TResult? Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult? Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult? Function(TerminalError_PtyError value)? ptyError,
    TResult? Function(TerminalError_Serialization value)? serialization,
  }) {
    return sessionExited?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult Function(TerminalError_SessionExited value)? sessionExited,
    TResult Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult Function(TerminalError_PtyError value)? ptyError,
    TResult Function(TerminalError_Serialization value)? serialization,
    required TResult orElse(),
  }) {
    if (sessionExited != null) {
      return sessionExited(this);
    }
    return orElse();
  }
}

abstract class TerminalError_SessionExited extends TerminalError {
  const factory TerminalError_SessionExited(final BigInt field0) =
      _$TerminalError_SessionExitedImpl;
  const TerminalError_SessionExited._() : super._();

  @override
  BigInt get field0;

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TerminalError_SessionExitedImplCopyWith<_$TerminalError_SessionExitedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TerminalError_InputChannelClosedImplCopyWith<$Res> {
  factory _$$TerminalError_InputChannelClosedImplCopyWith(
    _$TerminalError_InputChannelClosedImpl value,
    $Res Function(_$TerminalError_InputChannelClosedImpl) then,
  ) = __$$TerminalError_InputChannelClosedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({BigInt field0});
}

/// @nodoc
class __$$TerminalError_InputChannelClosedImplCopyWithImpl<$Res>
    extends
        _$TerminalErrorCopyWithImpl<
          $Res,
          _$TerminalError_InputChannelClosedImpl
        >
    implements _$$TerminalError_InputChannelClosedImplCopyWith<$Res> {
  __$$TerminalError_InputChannelClosedImplCopyWithImpl(
    _$TerminalError_InputChannelClosedImpl _value,
    $Res Function(_$TerminalError_InputChannelClosedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$TerminalError_InputChannelClosedImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as BigInt,
      ),
    );
  }
}

/// @nodoc

class _$TerminalError_InputChannelClosedImpl
    extends TerminalError_InputChannelClosed {
  const _$TerminalError_InputChannelClosedImpl(this.field0) : super._();

  @override
  final BigInt field0;

  @override
  String toString() {
    return 'TerminalError.inputChannelClosed(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TerminalError_InputChannelClosedImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TerminalError_InputChannelClosedImplCopyWith<
    _$TerminalError_InputChannelClosedImpl
  >
  get copyWith =>
      __$$TerminalError_InputChannelClosedImplCopyWithImpl<
        _$TerminalError_InputChannelClosedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(BigInt field0) sessionNotFound,
    required TResult Function(BigInt field0) sessionExited,
    required TResult Function(BigInt field0) inputChannelClosed,
    required TResult Function(String field0) spawnFailed,
    required TResult Function(String field0) ptyError,
    required TResult Function(String field0) serialization,
  }) {
    return inputChannelClosed(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(BigInt field0)? sessionNotFound,
    TResult? Function(BigInt field0)? sessionExited,
    TResult? Function(BigInt field0)? inputChannelClosed,
    TResult? Function(String field0)? spawnFailed,
    TResult? Function(String field0)? ptyError,
    TResult? Function(String field0)? serialization,
  }) {
    return inputChannelClosed?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(BigInt field0)? sessionNotFound,
    TResult Function(BigInt field0)? sessionExited,
    TResult Function(BigInt field0)? inputChannelClosed,
    TResult Function(String field0)? spawnFailed,
    TResult Function(String field0)? ptyError,
    TResult Function(String field0)? serialization,
    required TResult orElse(),
  }) {
    if (inputChannelClosed != null) {
      return inputChannelClosed(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TerminalError_SessionNotFound value)
    sessionNotFound,
    required TResult Function(TerminalError_SessionExited value) sessionExited,
    required TResult Function(TerminalError_InputChannelClosed value)
    inputChannelClosed,
    required TResult Function(TerminalError_SpawnFailed value) spawnFailed,
    required TResult Function(TerminalError_PtyError value) ptyError,
    required TResult Function(TerminalError_Serialization value) serialization,
  }) {
    return inputChannelClosed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult? Function(TerminalError_SessionExited value)? sessionExited,
    TResult? Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult? Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult? Function(TerminalError_PtyError value)? ptyError,
    TResult? Function(TerminalError_Serialization value)? serialization,
  }) {
    return inputChannelClosed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult Function(TerminalError_SessionExited value)? sessionExited,
    TResult Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult Function(TerminalError_PtyError value)? ptyError,
    TResult Function(TerminalError_Serialization value)? serialization,
    required TResult orElse(),
  }) {
    if (inputChannelClosed != null) {
      return inputChannelClosed(this);
    }
    return orElse();
  }
}

abstract class TerminalError_InputChannelClosed extends TerminalError {
  const factory TerminalError_InputChannelClosed(final BigInt field0) =
      _$TerminalError_InputChannelClosedImpl;
  const TerminalError_InputChannelClosed._() : super._();

  @override
  BigInt get field0;

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TerminalError_InputChannelClosedImplCopyWith<
    _$TerminalError_InputChannelClosedImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TerminalError_SpawnFailedImplCopyWith<$Res> {
  factory _$$TerminalError_SpawnFailedImplCopyWith(
    _$TerminalError_SpawnFailedImpl value,
    $Res Function(_$TerminalError_SpawnFailedImpl) then,
  ) = __$$TerminalError_SpawnFailedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TerminalError_SpawnFailedImplCopyWithImpl<$Res>
    extends _$TerminalErrorCopyWithImpl<$Res, _$TerminalError_SpawnFailedImpl>
    implements _$$TerminalError_SpawnFailedImplCopyWith<$Res> {
  __$$TerminalError_SpawnFailedImplCopyWithImpl(
    _$TerminalError_SpawnFailedImpl _value,
    $Res Function(_$TerminalError_SpawnFailedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$TerminalError_SpawnFailedImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$TerminalError_SpawnFailedImpl extends TerminalError_SpawnFailed {
  const _$TerminalError_SpawnFailedImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TerminalError.spawnFailed(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TerminalError_SpawnFailedImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TerminalError_SpawnFailedImplCopyWith<_$TerminalError_SpawnFailedImpl>
  get copyWith =>
      __$$TerminalError_SpawnFailedImplCopyWithImpl<
        _$TerminalError_SpawnFailedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(BigInt field0) sessionNotFound,
    required TResult Function(BigInt field0) sessionExited,
    required TResult Function(BigInt field0) inputChannelClosed,
    required TResult Function(String field0) spawnFailed,
    required TResult Function(String field0) ptyError,
    required TResult Function(String field0) serialization,
  }) {
    return spawnFailed(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(BigInt field0)? sessionNotFound,
    TResult? Function(BigInt field0)? sessionExited,
    TResult? Function(BigInt field0)? inputChannelClosed,
    TResult? Function(String field0)? spawnFailed,
    TResult? Function(String field0)? ptyError,
    TResult? Function(String field0)? serialization,
  }) {
    return spawnFailed?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(BigInt field0)? sessionNotFound,
    TResult Function(BigInt field0)? sessionExited,
    TResult Function(BigInt field0)? inputChannelClosed,
    TResult Function(String field0)? spawnFailed,
    TResult Function(String field0)? ptyError,
    TResult Function(String field0)? serialization,
    required TResult orElse(),
  }) {
    if (spawnFailed != null) {
      return spawnFailed(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TerminalError_SessionNotFound value)
    sessionNotFound,
    required TResult Function(TerminalError_SessionExited value) sessionExited,
    required TResult Function(TerminalError_InputChannelClosed value)
    inputChannelClosed,
    required TResult Function(TerminalError_SpawnFailed value) spawnFailed,
    required TResult Function(TerminalError_PtyError value) ptyError,
    required TResult Function(TerminalError_Serialization value) serialization,
  }) {
    return spawnFailed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult? Function(TerminalError_SessionExited value)? sessionExited,
    TResult? Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult? Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult? Function(TerminalError_PtyError value)? ptyError,
    TResult? Function(TerminalError_Serialization value)? serialization,
  }) {
    return spawnFailed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult Function(TerminalError_SessionExited value)? sessionExited,
    TResult Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult Function(TerminalError_PtyError value)? ptyError,
    TResult Function(TerminalError_Serialization value)? serialization,
    required TResult orElse(),
  }) {
    if (spawnFailed != null) {
      return spawnFailed(this);
    }
    return orElse();
  }
}

abstract class TerminalError_SpawnFailed extends TerminalError {
  const factory TerminalError_SpawnFailed(final String field0) =
      _$TerminalError_SpawnFailedImpl;
  const TerminalError_SpawnFailed._() : super._();

  @override
  String get field0;

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TerminalError_SpawnFailedImplCopyWith<_$TerminalError_SpawnFailedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TerminalError_PtyErrorImplCopyWith<$Res> {
  factory _$$TerminalError_PtyErrorImplCopyWith(
    _$TerminalError_PtyErrorImpl value,
    $Res Function(_$TerminalError_PtyErrorImpl) then,
  ) = __$$TerminalError_PtyErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TerminalError_PtyErrorImplCopyWithImpl<$Res>
    extends _$TerminalErrorCopyWithImpl<$Res, _$TerminalError_PtyErrorImpl>
    implements _$$TerminalError_PtyErrorImplCopyWith<$Res> {
  __$$TerminalError_PtyErrorImplCopyWithImpl(
    _$TerminalError_PtyErrorImpl _value,
    $Res Function(_$TerminalError_PtyErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$TerminalError_PtyErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$TerminalError_PtyErrorImpl extends TerminalError_PtyError {
  const _$TerminalError_PtyErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TerminalError.ptyError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TerminalError_PtyErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TerminalError_PtyErrorImplCopyWith<_$TerminalError_PtyErrorImpl>
  get copyWith =>
      __$$TerminalError_PtyErrorImplCopyWithImpl<_$TerminalError_PtyErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(BigInt field0) sessionNotFound,
    required TResult Function(BigInt field0) sessionExited,
    required TResult Function(BigInt field0) inputChannelClosed,
    required TResult Function(String field0) spawnFailed,
    required TResult Function(String field0) ptyError,
    required TResult Function(String field0) serialization,
  }) {
    return ptyError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(BigInt field0)? sessionNotFound,
    TResult? Function(BigInt field0)? sessionExited,
    TResult? Function(BigInt field0)? inputChannelClosed,
    TResult? Function(String field0)? spawnFailed,
    TResult? Function(String field0)? ptyError,
    TResult? Function(String field0)? serialization,
  }) {
    return ptyError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(BigInt field0)? sessionNotFound,
    TResult Function(BigInt field0)? sessionExited,
    TResult Function(BigInt field0)? inputChannelClosed,
    TResult Function(String field0)? spawnFailed,
    TResult Function(String field0)? ptyError,
    TResult Function(String field0)? serialization,
    required TResult orElse(),
  }) {
    if (ptyError != null) {
      return ptyError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TerminalError_SessionNotFound value)
    sessionNotFound,
    required TResult Function(TerminalError_SessionExited value) sessionExited,
    required TResult Function(TerminalError_InputChannelClosed value)
    inputChannelClosed,
    required TResult Function(TerminalError_SpawnFailed value) spawnFailed,
    required TResult Function(TerminalError_PtyError value) ptyError,
    required TResult Function(TerminalError_Serialization value) serialization,
  }) {
    return ptyError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult? Function(TerminalError_SessionExited value)? sessionExited,
    TResult? Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult? Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult? Function(TerminalError_PtyError value)? ptyError,
    TResult? Function(TerminalError_Serialization value)? serialization,
  }) {
    return ptyError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult Function(TerminalError_SessionExited value)? sessionExited,
    TResult Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult Function(TerminalError_PtyError value)? ptyError,
    TResult Function(TerminalError_Serialization value)? serialization,
    required TResult orElse(),
  }) {
    if (ptyError != null) {
      return ptyError(this);
    }
    return orElse();
  }
}

abstract class TerminalError_PtyError extends TerminalError {
  const factory TerminalError_PtyError(final String field0) =
      _$TerminalError_PtyErrorImpl;
  const TerminalError_PtyError._() : super._();

  @override
  String get field0;

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TerminalError_PtyErrorImplCopyWith<_$TerminalError_PtyErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TerminalError_SerializationImplCopyWith<$Res> {
  factory _$$TerminalError_SerializationImplCopyWith(
    _$TerminalError_SerializationImpl value,
    $Res Function(_$TerminalError_SerializationImpl) then,
  ) = __$$TerminalError_SerializationImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TerminalError_SerializationImplCopyWithImpl<$Res>
    extends _$TerminalErrorCopyWithImpl<$Res, _$TerminalError_SerializationImpl>
    implements _$$TerminalError_SerializationImplCopyWith<$Res> {
  __$$TerminalError_SerializationImplCopyWithImpl(
    _$TerminalError_SerializationImpl _value,
    $Res Function(_$TerminalError_SerializationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$TerminalError_SerializationImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$TerminalError_SerializationImpl extends TerminalError_Serialization {
  const _$TerminalError_SerializationImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TerminalError.serialization(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TerminalError_SerializationImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TerminalError_SerializationImplCopyWith<_$TerminalError_SerializationImpl>
  get copyWith =>
      __$$TerminalError_SerializationImplCopyWithImpl<
        _$TerminalError_SerializationImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(BigInt field0) sessionNotFound,
    required TResult Function(BigInt field0) sessionExited,
    required TResult Function(BigInt field0) inputChannelClosed,
    required TResult Function(String field0) spawnFailed,
    required TResult Function(String field0) ptyError,
    required TResult Function(String field0) serialization,
  }) {
    return serialization(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(BigInt field0)? sessionNotFound,
    TResult? Function(BigInt field0)? sessionExited,
    TResult? Function(BigInt field0)? inputChannelClosed,
    TResult? Function(String field0)? spawnFailed,
    TResult? Function(String field0)? ptyError,
    TResult? Function(String field0)? serialization,
  }) {
    return serialization?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(BigInt field0)? sessionNotFound,
    TResult Function(BigInt field0)? sessionExited,
    TResult Function(BigInt field0)? inputChannelClosed,
    TResult Function(String field0)? spawnFailed,
    TResult Function(String field0)? ptyError,
    TResult Function(String field0)? serialization,
    required TResult orElse(),
  }) {
    if (serialization != null) {
      return serialization(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TerminalError_SessionNotFound value)
    sessionNotFound,
    required TResult Function(TerminalError_SessionExited value) sessionExited,
    required TResult Function(TerminalError_InputChannelClosed value)
    inputChannelClosed,
    required TResult Function(TerminalError_SpawnFailed value) spawnFailed,
    required TResult Function(TerminalError_PtyError value) ptyError,
    required TResult Function(TerminalError_Serialization value) serialization,
  }) {
    return serialization(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult? Function(TerminalError_SessionExited value)? sessionExited,
    TResult? Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult? Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult? Function(TerminalError_PtyError value)? ptyError,
    TResult? Function(TerminalError_Serialization value)? serialization,
  }) {
    return serialization?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TerminalError_SessionNotFound value)? sessionNotFound,
    TResult Function(TerminalError_SessionExited value)? sessionExited,
    TResult Function(TerminalError_InputChannelClosed value)?
    inputChannelClosed,
    TResult Function(TerminalError_SpawnFailed value)? spawnFailed,
    TResult Function(TerminalError_PtyError value)? ptyError,
    TResult Function(TerminalError_Serialization value)? serialization,
    required TResult orElse(),
  }) {
    if (serialization != null) {
      return serialization(this);
    }
    return orElse();
  }
}

abstract class TerminalError_Serialization extends TerminalError {
  const factory TerminalError_Serialization(final String field0) =
      _$TerminalError_SerializationImpl;
  const TerminalError_Serialization._() : super._();

  @override
  String get field0;

  /// Create a copy of TerminalError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TerminalError_SerializationImplCopyWith<_$TerminalError_SerializationImpl>
  get copyWith => throw _privateConstructorUsedError;
}
