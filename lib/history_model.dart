class DiscountHistory {
  final int? id;
  final String date;
  final String originalPrice;
  final String discount;
  final String finalPrice;
  final String profit;
  final String sellprice;


  DiscountHistory({
    this.id,
    required this.date,
    required this.originalPrice,
    required this.discount,
    required this.finalPrice,
    required this.profit,
    required this.sellprice,

  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'originalPrice': originalPrice,
      'discount': discount,
      'finalPrice': finalPrice,
      'profit': profit,
      'sellprice': sellprice,
    };
  }
}
