import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/animations/spotlight.dart';
import 'package:pixel_adventure/game/background/background.dart';
import 'package:pixel_adventure/game/events/game_event_bus.dart';
import 'package:pixel_adventure/game/game.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/dialog_container.dart';
import 'package:pixel_adventure/game/utils/dialog_page.dart';

/// Inventory overlay route that opens the in-game Inventory dialog.
class InventoryPage extends Route with HasGameReference<PixelQuest> {
  InventoryPage() : super(() => _InventoryDialog(), transparent: true);

  @override
  void onPop(Route nextRoute) {
    game.eventBus.emit(const InventoryStateChanged(PageAction.closed));
    super.onPop(nextRoute);
  }
}

/// Internal Inventory dialog wrapper that mounts the shared [DialogPage] container.
class _InventoryDialog extends Component with HasGameReference<PixelQuest> {
  @override
  FutureOr<void> onLoad() {
    final spot = game.spotlightCenterMenu.x + Spotlight.playerTargetRadius;
    add(
      DialogPage(
        content: _InventoryContent(),
        titleText: game.l10n.inventoryTitle,
        contentSize: _InventoryContent.contentSize,
        blurBackground: false,
        dialogPosition: Vector2(
          spot + (game.canvasSize.x / game.worldToScreenScale - spot) / 2,
          game.canvasSize.y / game.worldToScreenScale / 2,
        ),
      ),
    );
    return super.onLoad();
  }
}

/// Inventory dialog body that builds the UI content.
class _InventoryContent extends PositionComponent with HasGameReference<PixelQuest> {
  _InventoryContent() : super(size: contentSize);

  // content size
  static final Vector2 contentSize = Vector2(
    DialogContainer.contentWidth,
    AppTheme.dialogTextStandardHeight * 3 +
        _optionSize.y * 3 +
        DialogContainer.spacingBetweenSections * 2 +
        DialogContainer.subHeadlineMarginBottom * 3,
  );

  // character picker
  late final TextComponent _characterPickerText;
  late final RadioComponent _characterPickerSelector;

  // level background picker
  late final TextComponent _levelBgPickerText;
  late final RadioComponent _levelBgPickerSelector;

  // loading background picker
  late final TextComponent _loadingBgPickerText;
  late final RadioComponent _loadingBgPickerSelector;

  // styling
  static final Vector2 _optionSize = Vector2.all((DialogContainer.contentWidth - _spacingBetweenOptions * 3) / 4);
  static final double _spacingBetweenOptions = 4; // [Adjustable]
  static final Vector2 _bgSpriteSize = Vector2.all(29); // [Adjustable]
  static const double _bgSpriteCornerRadius = 3.5; // [Adjustable]

  @override
  FutureOr<void> onLoad() {
    _setUpCharacterPicker();
    _setUpLevelBgPicker();
    _setUpLoadingBgPicker();
    return super.onLoad();
  }

  void _setUpCharacterPicker() {
    // character picker text
    _characterPickerText = TextComponent(
      text: game.l10n.inventoryLabelCharacter,
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 0),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
    );

    // character picker selector
    _characterPickerSelector = RadioComponent(
      anchor: Anchor.topCenter,
      position: _characterPickerText.position + Vector2(0, _characterPickerText.height + DialogContainer.subHeadlineMarginBottom),
      initialIndex: game.storageCenter.inventory.character.index,
      optionSize: _optionSize,
      spacingBetweenOptions: _spacingBetweenOptions,
      spriteOffset: Vector2(0, -4),
      options: [
        for (final character in PlayerCharacter.values)
          RadioOptionSprite(path: character.pathPreview, onSelected: () => _characterChanged(character)),
      ],
    );

    addAll([_characterPickerText, _characterPickerSelector]);
  }

  void _setUpLevelBgPicker() {
    // level background picker text
    _levelBgPickerText = TextComponent(
      text: game.l10n.inventoryLabelLevelBackground,
      anchor: Anchor.topCenter,
      position: _characterPickerSelector.position + Vector2(0, _characterPickerSelector.height + DialogContainer.spacingBetweenSections),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
    );

    // level background picker selector
    _levelBgPickerSelector = RadioComponent(
      anchor: Anchor.topCenter,
      position: _levelBgPickerText.position + Vector2(0, _levelBgPickerText.height + DialogContainer.subHeadlineMarginBottom),
      initialIndex: game.storageCenter.inventory.levelBackground.indexForScenes(
        BackgroundScene.levelChoices,
        tail: BackgroundChoiceTail.worldDefault,
      ),
      optionSize: _optionSize,
      spacingBetweenOptions: _spacingBetweenOptions,
      spriteSize: _bgSpriteSize,
      spriteCornerRadius: _bgSpriteCornerRadius,
      options: [
        for (final scene in BackgroundScene.levelChoices)
          RadioOptionSprite(path: scene.pathOrig, onSelected: () => _storeLevelBg(BackgroundChoice.scene(scene))),
        RadioOptionText(
          text: game.l10n.inventoryOptionDefault,
          onSelected: nonBlocking(() => _storeLevelBg(BackgroundChoice.worldDefault())),
        ),
      ],
    );

    addAll([_levelBgPickerText, _levelBgPickerSelector]);
  }

  void _setUpLoadingBgPicker() {
    // loading background picker text
    _loadingBgPickerText = TextComponent(
      text: game.l10n.inventoryLabelLoadingBackground,
      anchor: Anchor.topCenter,
      position: _levelBgPickerSelector.position + Vector2(0, _levelBgPickerSelector.height + DialogContainer.spacingBetweenSections),
      textRenderer: AppTheme.dialogTextStandard.asTextPaint,
    );

    // loading background picker selector
    _loadingBgPickerSelector = RadioComponent(
      anchor: Anchor.topCenter,
      position: _loadingBgPickerText.position + Vector2(0, _loadingBgPickerText.height + DialogContainer.subHeadlineMarginBottom),
      initialIndex: game.storageCenter.inventory.loadingBackground.indexForScenes(
        BackgroundScene.loadingChoices,
        tail: BackgroundChoiceTail.random,
      ),
      optionSize: _optionSize,
      spacingBetweenOptions: _spacingBetweenOptions,
      spriteSize: _bgSpriteSize,
      spriteCornerRadius: _bgSpriteCornerRadius,
      options: [
        for (final scene in BackgroundScene.loadingChoices)
          RadioOptionSprite(path: scene.pathOrig, onSelected: () => _storeLoadingBg(BackgroundChoice.scene(scene))),
        RadioOptionText(text: game.l10n.inventoryOptionRandom, onSelected: nonBlocking(() => _storeLoadingBg(BackgroundChoice.random()))),
      ],
    );

    addAll([_loadingBgPickerText, _loadingBgPickerSelector]);
  }

  void _characterChanged(PlayerCharacter character) {
    game.eventBus.emit(InventoryChangedCharacter(character));
  }

  Future<void> _storeLevelBg(BackgroundChoice choice) async {
    await game.storageCenter.saveInventory(levelBackground: choice);
  }

  Future<void> _storeLoadingBg(BackgroundChoice choice) async {
    await game.storageCenter.saveInventory(loadingBackground: choice);
  }
}
