enum Allergen {
  peanut('peanut', 'Peanut'),
  treeNut('tree_nut', 'Tree nut'),
  dairy('dairy', 'Dairy / milk'),
  egg('egg', 'Egg'),
  soy('soy', 'Soy'),
  fish('fish', 'Fish'),
  shellfish('shellfish', 'Shellfish'),
  sesame('sesame', 'Sesame'),
  wheat('wheat', 'Wheat'),
  gluten('gluten', 'Gluten');

  const Allergen(this.code, this.label);

  final String code;
  final String label;

  static const List<Allergen> displayOrder = [
    Allergen.peanut,
    Allergen.treeNut,
    Allergen.dairy,
    Allergen.egg,
    Allergen.soy,
    Allergen.fish,
    Allergen.shellfish,
    Allergen.sesame,
    Allergen.wheat,
    Allergen.gluten,
  ];

  static Allergen fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => Allergen.peanut,
    );
  }
}
