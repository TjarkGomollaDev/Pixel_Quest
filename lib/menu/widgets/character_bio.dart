import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/l10n/app_localizations_extensions.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class CharacterBio extends PositionComponent with HasGameReference<PixelQuest>, HasVisibility {
  CharacterBio({required super.position, bool show = true}) {
    size = Vector2(100, 64);
    if (!show) hide();
  }

  // text labels
  late final TextComponent _nameTextLabel;
  late final TextComponent _originTextLabel;
  late final TextComponent _abilityTextLabel;

  // text values
  late final TextComponent _nameTextValue;
  late final TextComponent _originTextValue;
  late final TextComponent _abilityTextValue;

  // spacing
  static const double _verticalSpacing = 11; // [Adjustable]
  static const double _horizontalSpacing = 3.5; // [Adjustable]

  // typing speed in ms
  static const int _charDelay = 50; // [Adjustable]

  // cancellation token
  int _typingId = 0;

  @override
  Future<void> onLoad() async {
    _initialSetup();
    _setUpBio();
    super.onLoad();
  }

  void _initialSetup() {
    // debug
    debugColor = AppTheme.transparent;

    // general
    anchor = Anchor.centerLeft;
  }

  void _setUpBio() {
    final startY = size.y / 2;

    // set up labeels
    _nameTextLabel = _createTextComponent(game.l10n.characterPickerLabelName, Vector2(0, startY - _verticalSpacing));
    _originTextLabel = _createTextComponent(game.l10n.characterPickerLabelOrigin, Vector2(0, startY));
    _abilityTextLabel = _createTextComponent(game.l10n.characterPickerLabelAbility, Vector2(0, startY + _verticalSpacing));

    // set up values
    _nameTextValue = _createTextComponent('', _nameTextLabel.position + Vector2(_nameTextLabel.size.x + _horizontalSpacing, 0));
    _originTextValue = _createTextComponent('', _originTextLabel.position + Vector2(_originTextLabel.size.x + _horizontalSpacing, 0));
    _abilityTextValue = _createTextComponent('', _abilityTextLabel.position + Vector2(_abilityTextLabel.size.x + _horizontalSpacing, 0));

    addAll([_nameTextLabel, _originTextLabel, _abilityTextLabel, _nameTextValue, _originTextValue, _abilityTextValue]);

    // initial display
    setCharacterBio(game.storageCenter.settings.character, animation: false);
  }

  TextComponent _createTextComponent(String text, Vector2 position) =>
      TextComponent(text: text, position: position, anchor: Anchor.centerLeft, textRenderer: AppTheme.characterPickerText.asTextPaint);

  Future<void> setCharacterBio(PlayerCharacter character, {bool animation = true}) async {
    final data = game.l10n.bioForCharacter(character);

    // cancel any currently running typing animation
    _typingId++;
    final int currentTypingId = _typingId;

    if (!animation) {
      _nameTextValue.text = data.name;
      _originTextValue.text = data.origin;
      _abilityTextValue.text = data.ability;
      return;
    }

    // clear old text immediately
    _nameTextValue.text = '';
    _originTextValue.text = '';
    _abilityTextValue.text = '';

    // typewriter effect sequentially
    await _typeWriterEffect(_nameTextValue, data.name, currentTypingId);
    await _typeWriterEffect(_originTextValue, data.origin, currentTypingId);
    await _typeWriterEffect(_abilityTextValue, data.ability, currentTypingId);
  }

  Future<void> _typeWriterEffect(TextComponent component, String text, int typingId) async {
    if (_typingId != typingId) return;
    component.text = '';
    for (int i = 0; i < text.length; i++) {
      if (_typingId != typingId) return;
      component.text += text[i];
      await Future.delayed(const Duration(milliseconds: _charDelay));
    }
  }

  void show() => isVisible = true;

  void hide() => isVisible = false;

  Future<void> animatedShow({double duration = 0.4}) async {
    if (isVisible) return;
    isVisible = true;

    final endPosition = position.clone();
    position += Vector2(30, 0);
    final completer = Completer<void>();

    add(MoveEffect.to(endPosition, EffectController(duration: duration, curve: Curves.easeOutCubic)));

    return completer.future;
  }
}
