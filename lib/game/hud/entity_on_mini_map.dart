import 'dart:ui';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/collision/world_collision.dart';

mixin EntityOnMiniMap on PositionComponent {
  /// Returns the world-space position where the minimap marker should be placed.
  /// - If the entity implements EntityCollision, we return the hitbox bottom-center.
  /// - Otherwise we return the bottom-center from the PositionComponent.
  Vector2 get markerPosition {
    if (this is EntityCollision) {
      final offset = (this as EntityCollision).entityHitbox.toAbsoluteRect().bottomCenter;
      return Vector2(offset.dx, offset.dy);
    } else if (this is WorldCollision) {
      final offset = (this as WorldCollision).worldHitbox.toAbsoluteRect().bottomCenter;
      return Vector2(offset.dx, offset.dy);
    }

    // fallback
    return Vector2(position.x + size.x / 2, position.y + size.y);
  }

  EntityMiniMapMarker _marker = EntityMiniMapMarker();
  EntityMiniMapMarker get marker => _marker;
  set marker(EntityMiniMapMarker value) => _marker = value;

  void Function(EntityOnMiniMap entity)? _onRemovedFromLevel;

  /// Callback that will be called when the entity is removed from the game.
  set onRemovedFromLevel(void Function(EntityOnMiniMap entity) function) => _onRemovedFromLevel = function;

  @override
  void onRemove() {
    _onRemovedFromLevel?.call(this);
    super.onRemove();
  }
}

enum EntityMiniMapMarkerType { circle, square, platform }

enum EntityMiniMapMarkerLayer { aboveForeground, behindForeground }

class EntityMiniMapMarker {
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
