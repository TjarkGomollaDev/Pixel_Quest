# Diff Details

Date : 2025-12-19 02:54:03

Directory /Users/tjarkgomolla/Development/Flutter/pixel_adventure

Total : 69 files,  1014 codes, 234 comments, 182 blanks, all 1430 lines

[Summary](results.md) / [Details](details.md) / [Diff Summary](diff.md) / Diff Details

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [assets/tiles/Level\_13.tmx](/assets/tiles/Level_13.tmx) | XML | 13 | 0 | 0 | 13 |
| [lib/app\_theme.dart](/lib/app_theme.dart) | Dart | 6 | 0 | 2 | 8 |
| [lib/data/audio/audio\_center.dart](/lib/data/audio/audio_center.dart) | Dart | 116 | 9 | 31 | 156 |
| [lib/data/storage/entities/settings\_entity.dart](/lib/data/storage/entities/settings_entity.dart) | Dart | 26 | 0 | 1 | 27 |
| [lib/data/storage/storage\_center.dart](/lib/data/storage/storage_center.dart) | Dart | 14 | 1 | -1 | 14 |
| [lib/extensions/build\_context.dart](/lib/extensions/build_context.dart) | Dart | -7 | 0 | -2 | -9 |
| [lib/extensions/int\_double\_extensions.dart](/lib/extensions/int_double_extensions.dart) | Dart | -9 | 0 | -3 | -12 |
| [lib/game/animations/star.dart](/lib/game/animations/star.dart) | Dart | 6 | 0 | -1 | 5 |
| [lib/game/checkpoints/checkpoint.dart](/lib/game/checkpoints/checkpoint.dart) | Dart | 2 | 0 | 1 | 3 |
| [lib/game/checkpoints/finish.dart](/lib/game/checkpoints/finish.dart) | Dart | 3 | 0 | 1 | 4 |
| [lib/game/collision/collision.dart](/lib/game/collision/collision.dart) | Dart | -4 | 0 | 1 | -3 |
| [lib/game/enemies/blue\_bird.dart](/lib/game/enemies/blue_bird.dart) | Dart | 4 | 2 | 2 | 8 |
| [lib/game/enemies/chicken.dart](/lib/game/enemies/chicken.dart) | Dart | 2 | 1 | 1 | 4 |
| [lib/game/enemies/ghost.dart](/lib/game/enemies/ghost.dart) | Dart | 2 | 1 | 1 | 4 |
| [lib/game/enemies/ghost\_particle.dart](/lib/game/enemies/ghost_particle.dart) | Dart | 2 | 0 | 1 | 3 |
| [lib/game/enemies/mushroom.dart](/lib/game/enemies/mushroom.dart) | Dart | 2 | 1 | 1 | 4 |
| [lib/game/enemies/plant.dart](/lib/game/enemies/plant.dart) | Dart | 2 | 1 | 1 | 4 |
| [lib/game/enemies/slime\_particle.dart](/lib/game/enemies/slime_particle.dart) | Dart | 7 | 0 | 1 | 8 |
| [lib/game/enemies/snail.dart](/lib/game/enemies/snail.dart) | Dart | 3 | 3 | 2 | 8 |
| [lib/game/enemies/trunk.dart](/lib/game/enemies/trunk.dart) | Dart | 2 | 1 | 1 | 4 |
| [lib/game/enemies/trunk\_bullet.dart](/lib/game/enemies/trunk_bullet.dart) | Dart | -2 | 0 | 0 | -2 |
| [lib/game/enemies/turtle.dart](/lib/game/enemies/turtle.dart) | Dart | 2 | 1 | 1 | 4 |
| [lib/game/hud/entity\_on\_mini\_map.dart](/lib/game/hud/entity_on_mini_map.dart) | Dart | 11 | 32 | 3 | 46 |
| [lib/game/hud/game\_hud.dart](/lib/game/hud/game_hud.dart) | Dart | -3 | 1 | 0 | -2 |
| [lib/game/hud/mini\_map.dart](/lib/game/hud/mini_map.dart) | Dart | 52 | 36 | 10 | 98 |
| [lib/game/hud/mini\_map\_arrow\_layer.dart](/lib/game/hud/mini_map_arrow_layer.dart) | Dart | 59 | 24 | 14 | 97 |
| [lib/game/hud/pause\_route.dart](/lib/game/hud/pause_route.dart) | Dart | 1 | 0 | 0 | 1 |
| [lib/game/hud/settings\_route.dart](/lib/game/hud/settings_route.dart) | Dart | 157 | 18 | 26 | 201 |
| [lib/game/level/background\_colored.dart](/lib/game/level/background_colored.dart) | Dart | 0 | 1 | 0 | 1 |
| [lib/game/level/background\_szene.dart](/lib/game/level/background_szene.dart) | Dart | 7 | 2 | 3 | 12 |
| [lib/game/level/level.dart](/lib/game/level/level.dart) | Dart | -5 | 10 | 0 | 5 |
| [lib/game/level/loading\_overlay.dart](/lib/game/level/loading_overlay.dart) | Dart | 0 | 1 | 0 | 1 |
| [lib/game/level/player.dart](/lib/game/level/player.dart) | Dart | 15 | 0 | -1 | 14 |
| [lib/game/level/player\_special\_effect.dart](/lib/game/level/player_special_effect.dart) | Dart | 0 | 1 | 0 | 1 |
| [lib/game/traps/arrow\_up.dart](/lib/game/traps/arrow_up.dart) | Dart | 4 | 0 | 0 | 4 |
| [lib/game/traps/fire\_trap.dart](/lib/game/traps/fire_trap.dart) | Dart | 2 | 0 | 0 | 2 |
| [lib/game/traps/fruit.dart](/lib/game/traps/fruit.dart) | Dart | 5 | 0 | 0 | 5 |
| [lib/game/traps/moving\_platform.dart](/lib/game/traps/moving_platform.dart) | Dart | 1 | 2 | 1 | 4 |
| [lib/game/traps/rock\_head.dart](/lib/game/traps/rock_head.dart) | Dart | 1 | 4 | 2 | 7 |
| [lib/game/traps/saw.dart](/lib/game/traps/saw.dart) | Dart | 1 | 1 | 1 | 3 |
| [lib/game/traps/saw\_circle\_component.dart](/lib/game/traps/saw_circle_component.dart) | Dart | 2 | 2 | 3 | 7 |
| [lib/game/traps/spike\_head.dart](/lib/game/traps/spike_head.dart) | Dart | 1 | 1 | 1 | 3 |
| [lib/game/traps/spiked\_ball\_component.dart](/lib/game/traps/spiked_ball_component.dart) | Dart | 4 | 1 | 1 | 6 |
| [lib/game/traps/trampoline.dart](/lib/game/traps/trampoline.dart) | Dart | 2 | 0 | 1 | 3 |
| [lib/game/utils/button.dart](/lib/game/utils/button.dart) | Dart | 195 | 39 | 22 | 256 |
| [lib/game/utils/corner\_outline.dart](/lib/game/utils/corner_outline.dart) | Dart | -23 | 1 | -1 | -23 |
| [lib/game/utils/curves.dart](/lib/game/utils/curves.dart) | Dart | -2 | 0 | 0 | -2 |
| [lib/game/utils/dialog\_container.dart](/lib/game/utils/dialog_container.dart) | Dart | 139 | 16 | 22 | 177 |
| [lib/game/utils/dialog\_page.dart](/lib/game/utils/dialog_page.dart) | Dart | 52 | 1 | 10 | 63 |
| [lib/game/utils/slider.dart](/lib/game/utils/slider.dart) | Dart | 130 | 14 | 28 | 172 |
| [lib/game/utils/utils.dart](/lib/game/utils/utils.dart) | Dart | 2 | 0 | 1 | 3 |
| [lib/game/utils/volume.dart](/lib/game/utils/volume.dart) | Dart | -6 | 0 | -2 | -8 |
| [lib/menu/menu\_page.dart](/lib/menu/menu_page.dart) | Dart | 4 | 2 | 0 | 6 |
| [lib/menu/widgets/character\_picker.dart](/lib/menu/widgets/character_picker.dart) | Dart | 0 | 1 | 0 | 1 |
| [lib/menu/widgets/level\_btn.dart](/lib/menu/widgets/level_btn.dart) | Dart | -43 | -4 | -12 | -59 |
| [lib/menu/widgets/level\_grid.dart](/lib/menu/widgets/level_grid.dart) | Dart | 0 | 1 | 0 | 1 |
| [lib/menu/widgets/level\_tile.dart](/lib/menu/widgets/level_tile.dart) | Dart | 6 | 2 | 0 | 8 |
| [lib/menu/widgets/menu\_dummy\_character.dart](/lib/menu/widgets/menu_dummy_character.dart) | Dart | 2 | 0 | 0 | 2 |
| [lib/menu/widgets/menu\_top\_bar.dart](/lib/menu/widgets/menu_top_bar.dart) | Dart | 6 | 1 | 0 | 7 |
| [lib/pixel\_quest.dart](/lib/pixel_quest.dart) | Dart | 8 | 2 | 2 | 12 |
| [lib/router.dart](/lib/router.dart) | Dart | 3 | 0 | 0 | 3 |
| [lib/splash/flutter extensions/build\_context.dart](/lib/splash/flutter%20extensions/build_context.dart) | Dart | 7 | 0 | 2 | 9 |
| [lib/splash/flutter extensions/int\_double\_extensions.dart](/lib/splash/flutter%20extensions/int_double_extensions.dart) | Dart | 9 | 0 | 3 | 12 |
| [linux/flutter/generated\_plugin\_registrant.cc](/linux/flutter/generated_plugin_registrant.cc) | C++ | 4 | 0 | 0 | 4 |
| [linux/flutter/generated\_plugins.cmake](/linux/flutter/generated_plugins.cmake) | CMake | 1 | 0 | 0 | 1 |
| [macos/Flutter/GeneratedPluginRegistrant.swift](/macos/Flutter/GeneratedPluginRegistrant.swift) | Swift | 4 | 0 | 0 | 4 |
| [pubspec.yaml](/pubspec.yaml) | YAML | 3 | 0 | 0 | 3 |
| [windows/flutter/generated\_plugin\_registrant.cc](/windows/flutter/generated_plugin_registrant.cc) | C++ | 3 | 0 | 0 | 3 |
| [windows/flutter/generated\_plugins.cmake](/windows/flutter/generated_plugins.cmake) | CMake | 1 | 0 | 0 | 1 |

[Summary](results.md) / [Details](details.md) / [Diff Summary](diff.md) / Diff Details