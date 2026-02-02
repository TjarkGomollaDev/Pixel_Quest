import 'dart:ui';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/collision/entity_collision.dart';
import 'package:pixel_quest/game/collision/world_collision.dart';
import 'package:pixel_quest/game/utils/misc_utils.dart';

/// Mixin that marks a component as renderable on the mini map.
///
/// An entity can provide:
/// - a marker position (where its marker is drawn on the mini map),
/// - an occlusion position (used to check whether it is hidden by the mini map frame),
/// - an optional movement range in y (`yMoveRange`) used for pre-filtering arrow candidates,
/// - marker styling information (`EntityMiniMapMarker`),
/// - a removal callback hook (`onRemovedFromLevel`) to keep mini map lists in sync.
///
/// The mixin supports entities with collision hitboxes:
/// - If the entity implements `EntityCollision` or `WorldCollision`,
///   marker and occlusion positions are derived from the hitbox rect.
/// - Otherwise, it falls back to the component bounds.
mixin EntityOnMiniMap on PositionComponent {
  @override
  void onRemove() {
    _onRemovedFromLevel?.call(this);
    super.onRemove();
  }

  /// World-space position where the mini map marker should be rendered.
  ///
  /// - If a collision rect exists: hitbox bottom-center (feels grounded on platforms).
  /// - Fallback: component bottom-center.
  Vector2 get markerPosition {
    final rect = _collisionRect();
    if (rect != null) return offsetToVector(rect.bottomCenter);

    // fallback: component bottom center
    return Vector2(position.x + size.x / 2, position.y + size.y);
  }

  /// World-space position used for occlusion checks against the mini map frame.
  ///
  /// - If a collision rect exists: hitbox center (stable for "is inside frame" checks).
  /// - Fallback: component center.
  Vector2 get occlusionPosition {
    final rect = _collisionRect();
    if (rect != null) return offsetToVector(rect.center);

    // fallback: component center
    return Vector2(position.x + size.x / 2, position.y + size.y / 2);
  }

  /// Returns the collision rect in world coordinates if the entity provides one.
  Rect? _collisionRect() {
    return switch (this) {
      EntityCollision(entityHitbox: final hitbox) => hitbox.toAbsoluteRect(),
      WorldCollision(worldHitbox: final hitbox) => hitbox.toAbsoluteRect(),
      _ => null,
    };
  }

  // y move range
  Vector2? _yMoveRange;

  /// Optional hint range for entities that can move vertically (used for quick mini map filtering).
  Vector2 get yMoveRange => _yMoveRange ?? Vector2.all(occlusionPosition.y);
  set yMoveRange(Vector2 range) => _yMoveRange = range;

  // marker
  EntityMiniMapMarker _marker = EntityMiniMapMarker();
  EntityMiniMapMarker get marker => _marker;

  /// Updates how this entity should be drawn on the mini map.
  set marker(EntityMiniMapMarker value) => _marker = value;

  // callback
  void Function(EntityOnMiniMap entity)? _onRemovedFromLevel;

  /// Hook used by the mini map to keep its internal lists in sync when entities despawn.
  set onRemovedFromLevel(void Function(EntityOnMiniMap entity) function) => _onRemovedFromLevel = function;
}

/// Marker style for the player on the mini map.
enum PlayerMiniMapMarkerType {
  circle,
  triangel;

  static const PlayerMiniMapMarkerType defaultMarker = PlayerMiniMapMarkerType.triangel;

  static PlayerMiniMapMarkerType fromName(String name) =>
      PlayerMiniMapMarkerType.values.firstWhere((c) => c.name == name, orElse: () => defaultMarker);
}

/// Marker style for various entities on the mini map.
enum EntityMiniMapMarkerType { circle, square, platform }

/// Defines in which visual layer the entity marker should be rendered.
///
/// - `aboveForeground`: marker is drawn on top of the mini map foreground sprite.
/// - `behindForeground`: marker is drawn below the foreground sprite.
/// - `none`: entity has no marker on the mini map view, but can still be considered
///   for arrow hints.
enum EntityMiniMapMarkerLayer { aboveForeground, behindForeground, none }

/// Configuration object describing how an entity should appear on the mini map.
class EntityMiniMapMarker {
  // constructor parameters
  final double size;
  final EntityMiniMapMarkerType type;
  final Color color;
  final EntityMiniMapMarkerLayer layer;

  const EntityMiniMapMarker({
    this.size = 24,
    this.type = EntityMiniMapMarkerType.circle,
    this.color = AppTheme.entityMarkerStandard,
    this.layer = EntityMiniMapMarkerLayer.aboveForeground,
  });
}
