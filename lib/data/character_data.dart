import 'package:pixel_adventure/game/level/player.dart';

class CharacterData {
  final String name;
  final String origin;
  final String ability;

  const CharacterData({required this.name, required this.origin, required this.ability});
}

final Map<PlayerCharacter, CharacterData> characterData = {
  PlayerCharacter.maskDude: const CharacterData(name: 'Mojo', origin: 'Banana River', ability: 'Monkey Call'),
  PlayerCharacter.ninjaFrog: const CharacterData(name: 'Croakashi', origin: 'Kyoto Swamp', ability: 'Spin Attack'),
  PlayerCharacter.pinkMan: const CharacterData(name: 'Popstar P', origin: 'Pink Hills', ability: 'Disco Dash'),
  PlayerCharacter.virtualGuy: const CharacterData(name: 'Gl1tch.exe', origin: 'The Cloud', ability: 'Hack Attack'),
};
