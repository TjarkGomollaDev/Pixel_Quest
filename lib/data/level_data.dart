class LevelMetadata {
  final String tmxFileName;
  final String btnFileName;
  final String uuid;
  final int index;

  const LevelMetadata(this.tmxFileName, this.btnFileName, this.uuid, this.index);
}

extension LevelMetadataLookup on List<LevelMetadata> {
  LevelMetadata getByIndex(int index) =>
      allLevels.firstWhere((element) => element.index == index, orElse: () => allLevels.firstWhere((level) => level.index == 1));

  LevelMetadata getByUUID(String uuid) =>
      allLevels.firstWhere((level) => level.uuid == uuid, orElse: () => allLevels.firstWhere((level) => level.index == 1));
}

final allLevels = [
  const LevelMetadata('Level_01', '01', 'bd278912-62ee-4e96-8130-6deb764016bc', 1),
  const LevelMetadata('Level_02', '02', '875a7aa7-5899-4dfe-96a5-d99d070c44d6', 2),
  const LevelMetadata('Level_03', '03', 'f4c710e8-847c-4334-a0d7-39915939eaaf', 3),
  const LevelMetadata('Level_04', '04', 'e6e1a833-2ce8-482f-b7b7-1a84cfe74cfd', 4),
  const LevelMetadata('Level_05', '05', '85821992-ee5b-442b-9a6d-882e7931a956', 5),
  const LevelMetadata('Level_13', '13', 'e31ee2d0-fc87-4358-a09c-e8f3130f3fc2', 13),
];
