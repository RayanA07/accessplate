enum AvailabilityContext {
  grocery('grocery', 'Grocery store'),
  convenience('convenience', 'Convenience store'),
  fastFood('fast_food', 'Fast food'),
  foodPantry('food_pantry', 'Food pantry'),
  dollarStore('dollar_store', 'Dollar store');

  const AvailabilityContext(this.code, this.label);

  final String code;
  final String label;

  static AvailabilityContext fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => AvailabilityContext.grocery,
    );
  }
}
