class WorldMetadata {
  final String foreGroundFileName;
  final String titleFileName;
  final String uuid;
  final List<String> levelUuids;
  final int index;

  const WorldMetadata(this.foreGroundFileName, this.titleFileName, this.uuid, this.levelUuids, this.index);
}

extension WorldMetadataLookup on List<WorldMetadata> {
  WorldMetadata getByIndex(int index) =>
      allWorlds.firstWhere((element) => element.index == index, orElse: () => allWorlds.firstWhere((level) => level.index == 1));

  WorldMetadata getByUUID(String uuid) =>
      allWorlds.firstWhere((level) => level.uuid == uuid, orElse: () => allWorlds.firstWhere((level) => level.index == 1));

  String? getByLevelUUID(String uuid) {
    for (var world in this) {
      if (world.levelUuids.contains(uuid)) return world.uuid;
    }
    return null;
  }
}

const allWorlds = [
  // world 1
  WorldMetadata('World_1_Foreground', 'World_1_Title', '014809d5-8ec5-4171-a82e-df72e7839d45', [
    'bd278912-62ee-4e96-8130-6deb764016bc',
    '875a7aa7-5899-4dfe-96a5-d99d070c44d6',
    'f4c710e8-847c-4334-a0d7-39915939eaaf',
    'e6e1a833-2ce8-482f-b7b7-1a84cfe74cfd',
    '85821992-ee5b-442b-9a6d-882e7931a956',
    'e31ee2d0-fc87-4358-a09c-e8f3130f3fc2',
    '07b44f9b-261b-44c5-8513-607d5626f34d',
    'd93969f4-009c-436c-a66a-fc256c02e5a1',
    '1cad9a69-2d7d-4a3b-8d06-0c0e0aa2908a',
    '8209bf38-da80-4d41-95c4-9395e9f3129d',
    '9d39de83-59cf-4e4f-9cf1-bedbf344c69d',
    '91e91a6d-58a8-4fa2-b9c8-92dff0dbf085',
    'e51cbaf5-05f3-4ff9-95cb-d5b1e5b2483c',
    '0c730d10-9f9d-4e43-96ee-6111a5ee06be',
    '1b6b292d-28df-4894-ae87-6292adfe3eb7',
    'd8f75fd3-2ec9-4bea-aba6-7f94b3103834',
  ], 1),

  // world 2
];
