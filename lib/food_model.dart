class FoodItem {
  final String name;
  final double price;
  final String image;
  int quantity;

  FoodItem({
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });
}
