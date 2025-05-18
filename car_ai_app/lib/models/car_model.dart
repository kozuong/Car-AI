class CarModel {
  final String imagePath;
  final String carName;
  final String brand;
  final String year;
  final String price;
  final String power;
  final String acceleration;
  final String topSpeed;
  final String engine;
  final String interior;
  final List<String> features;
  final String description;
  final String descriptionEn;
  final String descriptionVi;
  final String engineDetailEn;
  final String engineDetailVi;
  final String interiorEn;
  final String interiorVi;
  final DateTime timestamp;

  CarModel({
    required this.imagePath,
    required this.carName,
    required this.brand,
    required this.year,
    required this.price,
    required this.power,
    required this.acceleration,
    required this.topSpeed,
    required this.engine,
    required this.interior,
    required this.features,
    required this.description,
    this.descriptionEn = '',
    this.descriptionVi = '',
    this.engineDetailEn = '',
    this.engineDetailVi = '',
    this.interiorEn = '',
    this.interiorVi = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'carName': carName,
        'brand': brand,
        'year': year,
        'price': price,
        'power': power,
        'acceleration': acceleration,
        'topSpeed': topSpeed,
        'engine': engine,
        'interior': interior,
        'features': features,
        'description': description,
        'descriptionEn': descriptionEn,
        'descriptionVi': descriptionVi,
        'engineDetailEn': engineDetailEn,
        'engineDetailVi': engineDetailVi,
        'interiorEn': interiorEn,
        'interiorVi': interiorVi,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CarModel.fromJson(Map<String, dynamic> json) => CarModel(
        imagePath: json['imagePath'] as String? ?? '',
        carName: json['carName'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        year: json['year'] as String? ?? '',
        price: json['price'] as String? ?? '',
        power: json['power'] as String? ?? '',
        acceleration: json['acceleration'] as String? ?? '',
        topSpeed: json['topSpeed'] as String? ?? '',
        engine: json['engine'] as String? ?? '',
        interior: json['interior'] as String? ?? '',
        features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        description: json['description'] as String? ?? '',
        descriptionEn: json['descriptionEn'] as String? ?? '',
        descriptionVi: json['descriptionVi'] as String? ?? '',
        engineDetailEn: json['engineDetailEn'] as String? ?? '',
        engineDetailVi: json['engineDetailVi'] as String? ?? '',
        interiorEn: json['interiorEn'] as String? ?? '',
        interiorVi: json['interiorVi'] as String? ?? '',
        timestamp: json['timestamp'] != null 
            ? DateTime.parse(json['timestamp'] as String)
            : null,
      );

  @override
  String toString() => 'CarModel(carName: $carName)';

  CarModel copyWith({
    String? imagePath,
    String? carName,
    String? brand,
    String? year,
    String? price,
    String? power,
    String? acceleration,
    String? topSpeed,
    String? engine,
    String? interior,
    List<String>? features,
    String? description,
    String? descriptionEn,
    String? descriptionVi,
    String? engineDetailEn,
    String? engineDetailVi,
    String? interiorEn,
    String? interiorVi,
    DateTime? timestamp,
  }) {
    return CarModel(
      imagePath: imagePath ?? this.imagePath,
      carName: carName ?? this.carName,
      brand: brand ?? this.brand,
      year: year ?? this.year,
      price: price ?? this.price,
      power: power ?? this.power,
      acceleration: acceleration ?? this.acceleration,
      topSpeed: topSpeed ?? this.topSpeed,
      engine: engine ?? this.engine,
      interior: interior ?? this.interior,
      features: features ?? this.features,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionVi: descriptionVi ?? this.descriptionVi,
      engineDetailEn: engineDetailEn ?? this.engineDetailEn,
      engineDetailVi: engineDetailVi ?? this.engineDetailVi,
      interiorEn: interiorEn ?? this.interiorEn,
      interiorVi: interiorVi ?? this.interiorVi,
      timestamp: timestamp ?? this.timestamp,
    );
  }
} 