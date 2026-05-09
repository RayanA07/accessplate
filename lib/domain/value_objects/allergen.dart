enum Allergen {
  peanut('peanut', 'Peanut'),
  treeNut('tree_nut', 'Tree nut'),
  dairy('dairy', 'Dairy / milk'),
  egg('egg', 'Egg'),
  soy('soy', 'Soy'),
  wheat('wheat', 'Wheat'),
  gluten('gluten', 'Gluten'),
  fish('fish', 'Fish'),
  shellfish('shellfish', 'Shellfish'),
  sesame('sesame', 'Sesame');

  const Allergen(this.code, this.label);

  final String code;
  final String label;

  static Allergen fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => Allergen.peanut,
    );
  }
}
