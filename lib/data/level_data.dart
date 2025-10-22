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

const allLevels = [
  // all levels from world 1
  LevelMetadata('Level_01', '01', 'bd278912-62ee-4e96-8130-6deb764016bc', 1),
  LevelMetadata('Level_02', '02', '875a7aa7-5899-4dfe-96a5-d99d070c44d6', 2),
  LevelMetadata('Level_03', '03', 'f4c710e8-847c-4334-a0d7-39915939eaaf', 3),
  LevelMetadata('Level_04', '04', 'e6e1a833-2ce8-482f-b7b7-1a84cfe74cfd', 4),
  LevelMetadata('Level_05', '05', '85821992-ee5b-442b-9a6d-882e7931a956', 5),
  LevelMetadata('Level_13', '06', 'e31ee2d0-fc87-4358-a09c-e8f3130f3fc2', 6),
  LevelMetadata('Level_13', '07', '07b44f9b-261b-44c5-8513-607d5626f34d', 7),
  LevelMetadata('Level_13', '08', 'd93969f4-009c-436c-a66a-fc256c02e5a1', 8),
  LevelMetadata('Level_13', '09', '1cad9a69-2d7d-4a3b-8d06-0c0e0aa2908a', 9),
  LevelMetadata('Level_13', '10', '8209bf38-da80-4d41-95c4-9395e9f3129d', 10),
  LevelMetadata('Level_13', '11', '9d39de83-59cf-4e4f-9cf1-bedbf344c69d', 11),
  LevelMetadata('Level_13', '12', '91e91a6d-58a8-4fa2-b9c8-92dff0dbf085', 12),
  LevelMetadata('Level_13', '13', 'e51cbaf5-05f3-4ff9-95cb-d5b1e5b2483c', 13),
  LevelMetadata('Level_13', '14', '0c730d10-9f9d-4e43-96ee-6111a5ee06be', 14),
  LevelMetadata('Level_13', '15', '1b6b292d-28df-4894-ae87-6292adfe3eb7', 15),
  LevelMetadata('Level_13', '16', 'd8f75fd3-2ec9-4bea-aba6-7f94b3103834', 16),

  // all levels from world 2
];
