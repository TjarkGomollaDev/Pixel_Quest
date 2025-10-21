import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/character_data.dart';
import 'package:pixel_adventure/game/level/player.dart';

class CharacterBio extends PositionComponent {
  final PlayerCharacter _character;

  CharacterBio({required PlayerCharacter character, required super.position}) : _character = character, super(size: Vector2(80, 20));

  // text labels
  late final TextComponent _nameTextLabel;
  late final TextComponent _originTextLabel;
  late final TextComponent _abilityTextLabel;

  // text values
  late final TextComponent _nameTextValue;
  late final TextComponent _originTextValue;
  late final TextComponent _abilityTextValue;

  // spacing
  static const double _verticalSpacing = 8; // [Adjustable]

  // typing speed in ms
  static const int _charDelay = 50; // [Adjustable]

  // cancellation token
  int _typingId = 0;

  @override
  Future<void> onLoad() async {
    _setUpBio();
    super.onLoad();
  }

  void _setUpBio() {
    // set up labeels
    _nameTextLabel = _createTextComponent('Name:  ', Vector2(0, 0));
    _originTextLabel = _createTextComponent('Origin:  ', Vector2(0, _verticalSpacing));
    _abilityTextLabel = _createTextComponent('Ability:  ', Vector2(0, _verticalSpacing * 2));

    // set up values
    _nameTextValue = _createTextComponent('', _nameTextLabel.position + Vector2(_nameTextLabel.size.x, 0));
    _originTextValue = _createTextComponent('', _originTextLabel.position + Vector2(_originTextLabel.size.x, 0));
    _abilityTextValue = _createTextComponent('', _abilityTextLabel.position + Vector2(_abilityTextLabel.size.x, 0));

    addAll([_nameTextLabel, _originTextLabel, _abilityTextLabel, _nameTextValue, _originTextValue, _abilityTextValue]);

    // initial display
    setCharacterBio(_character, animation: false);
  }

  TextComponent _createTextComponent(String text, Vector2 position) {
    return TextComponent(
      text: text,
      anchor: Anchor.topLeft,
      position: position,
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Pixel Font', fontSize: 4, color: AppTheme.ingameText, height: 1),
      ),
    );
  }

  Future<void> setCharacterBio(PlayerCharacter character, {bool animation = true}) async {
    final data = characterData[character];
    if (data == null) return;

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
}
