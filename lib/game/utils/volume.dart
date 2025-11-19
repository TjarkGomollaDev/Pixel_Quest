import 'package:pixel_adventure/game/utils/settings_notifier.dart';
import 'package:pixel_adventure/pixel_quest.dart';

Future<void> switchVolume({required PixelQuest game, bool soundsEnabled = true}) async {
  await game.storageCenter.saveSettings(game.storageCenter.settings.copyWith(soundsEnabled: soundsEnabled));
  SettingsNotifier.instance.notify(SettingsEvent.volume);
}
