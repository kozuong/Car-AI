class CarBrand {
  final String name;
  final String logoUrl;

  CarBrand({required this.name, required this.logoUrl});

  factory CarBrand.fromJson(Map<String, dynamic> json) {
    return CarBrand(
      name: json['name'],
      logoUrl: json['logo_url'],
    );
  }
} 