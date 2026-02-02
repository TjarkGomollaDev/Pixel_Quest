import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/l10n/app_localizations.dart';

typedef CharacterBioStrings = ({String name, String origin, String ability});

extension CharacterL10n on AppLocalizations {
  CharacterBioStrings bioForCharacter(PlayerCharacter character) {
    return switch (character) {
      PlayerCharacter.maskDude => (name: characterName_maskDude, origin: characterOrigin_maskDude, ability: characterAbility_maskDude),
      PlayerCharacter.ninjaFrog => (name: characterName_ninjaFrog, origin: characterOrigin_ninjaFrog, ability: characterAbility_ninjaFrog),
      PlayerCharacter.pinkMan => (name: characterName_pinkMan, origin: characterOrigin_pinkMan, ability: characterAbility_pinkMan),
      PlayerCharacter.virtualGuy => (
        name: characterName_virtualGuy,
        origin: characterOrigin_virtualGuy,
        ability: characterAbility_virtualGuy,
      ),
    };
  }
}
