enum MyLevel {
  level_1('Level_01', '01', 1),
  level_2('Level_02', '02', 2),
  level_3('Level_03', '03', 3),
  level_4('Level_04', '04', 4),
  level_5('Level_05', '05', 5),
  level_13('Level_13', '13', 13);

  final String name;
  final String btnName;
  final int levelIndex;

  const MyLevel(this.name, this.btnName, this.levelIndex);
}
