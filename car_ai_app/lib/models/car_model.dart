class CarModel {
  final String imagePath;
  final String carName;
  final String carNameEn;
  final String carNameVi;
  final String brand;
  final String year;
  final String yearEn;
  final String yearVi;
  final String price;
  final String priceEn;
  final String priceVi;
  final String power;
  final String powerEn;
  final String powerVi;
  final String acceleration;
  final String accelerationEn;
  final String accelerationVi;
  final String topSpeed;
  final String topSpeedEn;
  final String topSpeedVi;
  final String engine;
  final String engineEn;
  final String engineVi;
  final String interior;
  final String interiorEn;
  final String interiorVi;
  final List<String> features;
  final List<String> featuresEn;
  final List<String> featuresVi;
  final String description;
  final String descriptionEn;
  final String descriptionVi;
  final String engineDetailEn;
  final String engineDetailVi;
  final DateTime timestamp;
  final String pageTitle;
  final String logoUrl;
  final String numberProduced;
  final String numberProducedEn;
  final String numberProducedVi;
  final String rarity;
  final String rarityEn;
  final String rarityVi;
  final String brandEn;
  final String brandVi;

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
    required this.pageTitle,
    this.carNameEn = '',
    this.carNameVi = '',
    this.yearEn = '',
    this.yearVi = '',
    this.priceEn = '',
    this.priceVi = '',
    this.powerEn = '',
    this.powerVi = '',
    this.accelerationEn = '',
    this.accelerationVi = '',
    this.topSpeedEn = '',
    this.topSpeedVi = '',
    this.engineEn = '',
    this.engineVi = '',
    this.interiorEn = '',
    this.interiorVi = '',
    this.featuresEn = const [],
    this.featuresVi = const [],
    this.descriptionEn = '',
    this.descriptionVi = '',
    this.engineDetailEn = '',
    this.engineDetailVi = '',
    this.logoUrl = '',
    this.numberProduced = '',
    this.numberProducedEn = '',
    this.numberProducedVi = '',
    this.rarity = '',
    this.rarityEn = '',
    this.rarityVi = '',
    this.brandEn = '',
    this.brandVi = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'imagePath': imagePath,
    'carName': carName,
    'carNameEn': carNameEn,
    'carNameVi': carNameVi,
    'brand': brand,
    'year': year,
    'yearEn': yearEn,
    'yearVi': yearVi,
    'price': price,
    'priceEn': priceEn,
    'priceVi': priceVi,
    'power': power,
    'powerEn': powerEn,
    'powerVi': powerVi,
    'acceleration': acceleration,
    'accelerationEn': accelerationEn,
    'accelerationVi': accelerationVi,
    'topSpeed': topSpeed,
    'topSpeedEn': topSpeedEn,
    'topSpeedVi': topSpeedVi,
    'engine': engine,
    'engineEn': engineEn,
    'engineVi': engineVi,
    'interior': interior,
    'interiorEn': interiorEn,
    'interiorVi': interiorVi,
    'features': features,
    'featuresEn': featuresEn,
    'featuresVi': featuresVi,
    'description': description,
    'descriptionEn': descriptionEn,
    'descriptionVi': descriptionVi,
    'engineDetailEn': engineDetailEn,
    'engineDetailVi': engineDetailVi,
    'pageTitle': pageTitle,
    'logoUrl': logoUrl,
    'numberProduced': numberProduced,
    'numberProducedEn': numberProducedEn,
    'numberProducedVi': numberProducedVi,
    'rarity': rarity,
    'rarityEn': rarityEn,
    'rarityVi': rarityVi,
    'brandEn': brandEn,
    'brandVi': brandVi,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CarModel.fromJson(Map<String, dynamic> json) => CarModel(
    imagePath: json['imagePath'] as String? ?? '',
    carName: json['carName'] as String? ?? '',
    carNameEn: json['carNameEn'] as String? ?? '',
    carNameVi: json['carNameVi'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    year: json['year'] as String? ?? '',
    yearEn: json['yearEn'] as String? ?? '',
    yearVi: json['yearVi'] as String? ?? '',
    price: json['price'] as String? ?? '',
    priceEn: json['priceEn'] as String? ?? '',
    priceVi: json['priceVi'] as String? ?? '',
    power: json['power'] as String? ?? '',
    powerEn: json['powerEn'] as String? ?? '',
    powerVi: json['powerVi'] as String? ?? '',
    acceleration: json['acceleration'] as String? ?? '',
    accelerationEn: json['accelerationEn'] as String? ?? '',
    accelerationVi: json['accelerationVi'] as String? ?? '',
    topSpeed: json['topSpeed'] as String? ?? '',
    topSpeedEn: json['topSpeedEn'] as String? ?? '',
    topSpeedVi: json['topSpeedVi'] as String? ?? '',
    engine: json['engine'] as String? ?? '',
    engineEn: json['engineEn'] as String? ?? '',
    engineVi: json['engineVi'] as String? ?? '',
    interior: json['interior'] as String? ?? '',
    interiorEn: json['interiorEn'] as String? ?? '',
    interiorVi: json['interiorVi'] as String? ?? '',
    features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    featuresEn: (json['featuresEn'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    featuresVi: (json['featuresVi'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    description: json['description'] as String? ?? '',
    descriptionEn: json['descriptionEn'] as String? ?? '',
    descriptionVi: json['descriptionVi'] as String? ?? '',
    engineDetailEn: json['engineDetailEn'] ?? json['engine_detail_en'] ?? '',
    engineDetailVi: json['engineDetailVi'] ?? json['engine_detail_vi'] ?? '',
    pageTitle: json['pageTitle'] as String? ?? 'Analysis Result',
    logoUrl: json['logoUrl'] as String? ?? '',
    numberProduced: json['number_produced'] as String? ?? '',
    numberProducedEn: json['numberProducedEn'] as String? ?? '',
    numberProducedVi: json['numberProducedVi'] as String? ?? '',
    rarity: json['rarity'] as String? ?? '',
    rarityEn: json['rarityEn'] as String? ?? '',
    rarityVi: json['rarityVi'] as String? ?? '',
    brandEn: json['brandEn'] as String? ?? '',
    brandVi: json['brandVi'] as String? ?? '',
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
    String? logoUrl,
    String? numberProduced,
    String? rarity,
    DateTime? timestamp,
    String? pageTitle,
    String? brandEn,
    String? brandVi,
    String? numberProducedEn,
    String? numberProducedVi,
    String? rarityEn,
    String? rarityVi,
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
      logoUrl: logoUrl ?? this.logoUrl,
      numberProduced: numberProduced ?? this.numberProduced,
      rarity: rarity ?? this.rarity,
      timestamp: timestamp ?? this.timestamp,
      pageTitle: pageTitle ?? this.pageTitle,
      brandEn: brandEn ?? this.brandEn,
      brandVi: brandVi ?? this.brandVi,
      numberProducedEn: numberProducedEn ?? this.numberProducedEn,
      numberProducedVi: numberProducedVi ?? this.numberProducedVi,
      rarityEn: rarityEn ?? this.rarityEn,
      rarityVi: rarityVi ?? this.rarityVi,
    );
  }

  // Helper để chuẩn hóa số thập phân (loại bỏ dấu cách giữa số và phần thập phân)
  static String cleanDecimalSpace(String val) {
    final regex = RegExp(r'(\d+)\s*\.\s*(\d+)');
    return val.replaceAllMapped(regex, (m) => '${m[1]}.${m[2]}');
  }

  // Helper để chuẩn hóa acceleration về dạng '3.6s'
  static String normalizeAcceleration(String acc) {
    if (acc.trim().isEmpty || acc.trim().toLowerCase() == 'n/a') return '3.6s';
    
    // Tìm số trong chuỗi
    final regex = RegExp(r'(\d+(?:[\.,]\d+)?)');
    final match = regex.firstMatch(acc);
    if (match != null) {
      final val = match.group(1)!.replaceAll(',', '.');
      // Kiểm tra giá trị hợp lệ (2-10 giây)
      try {
        final numVal = double.parse(val);
        if (numVal >= 2 && numVal <= 10) {
          return '${val}s';
        }
      } catch (e) {
        // Nếu parse lỗi, giữ nguyên giá trị
        return '${val}s';
      }
    }
    return '3.6s';
  }

  // Helper method to get localized text
  String getLocalizedText(String field, String langCode) {
    String vi, en;
    switch (field) {
      case 'carName':
        vi = carNameVi; en = carNameEn; break;
      case 'year':
        vi = yearVi; en = yearEn; break;
      case 'price':
        vi = priceVi; en = priceEn; break;
      case 'power':
        vi = powerVi; en = powerEn; break;
      case 'acceleration':
        vi = accelerationVi; en = accelerationEn; break;
      case 'topSpeed':
        vi = topSpeedVi; en = topSpeedEn; break;
      case 'engine':
      case 'engine_detail':
        vi = engineDetailVi.isNotEmpty ? engineDetailVi : engineVi;
        en = engineDetailEn.isNotEmpty ? engineDetailEn : engineEn;
        break;
      case 'interior':
        vi = interiorVi; en = interiorEn; break;
      case 'description':
        vi = descriptionVi; en = descriptionEn; break;
      case 'numberProduced':
        vi = numberProducedVi; en = numberProducedEn; break;
      case 'rarity':
        vi = rarityVi; en = rarityEn; break;
      case 'brand':
        vi = brandVi.isNotEmpty ? brandVi : brand;
        en = brandEn.isNotEmpty ? brandEn : brand;
        break;
      default:
        vi = ''; en = '';
    }
    String value = langCode == 'vi' ? vi : en;
    // Nếu value rỗng hoặc N/A thì fallback sang trường còn lại
    if (value.trim().isEmpty || value.trim().toLowerCase() == 'n/a') {
      value = langCode == 'vi' ? en : vi;
    }
    // Nếu vẫn rỗng thì trả về giá trị mặc định
    if (value.trim().isEmpty || value.trim().toLowerCase() == 'n/a') {
      if (field == 'acceleration') return '3.6s';
      return '-';
    }
    // Chuẩn hóa số thập phân cho các trường số
    if (field == 'acceleration') {
      value = normalizeAcceleration(value);
    } else if (field == 'power' || field == 'topSpeed') {
      value = cleanDecimalSpace(value);
    }
    return value;
  }

  // Helper method to get localized features
  List<String> getLocalizedFeatures(String langCode) {
    return langCode == 'vi' ? featuresVi : featuresEn;
  }

  // Helper: Lấy giá trị trung bình từ chuỗi dạng 'a - b' hoặc trả về số nếu chỉ có một số
  static String getAverageValue(String value) {
    if (value.isEmpty) return '';
    // Loại bỏ dấu cách giữa số và phần thập phân, ví dụ: '3. 6' -> '3.6'
    value = value.replaceAll(RegExp(r'(\d+)\s*\.\s*(\d+)'), r'[1m$1.$2[0m');
    final regex = RegExp(r'(\d+[\.,]?\d*)\s*-\s*(\d+[\.,]?\d*)');
    final match = regex.firstMatch(value.replaceAll(',', '.'));
    if (match != null) {
      final a = double.tryParse(match.group(1) ?? '');
      final b = double.tryParse(match.group(2) ?? '');
      if (a != null && b != null) {
        final avg = ((a + b) / 2).toStringAsFixed(1);
        // Lấy đơn vị phía sau số cuối cùng
        final unit = value.replaceAll(match.group(0)!, '').trim();
        return '$avg${unit.isNotEmpty ? ' $unit' : ''}';
      }
    }
    // Nếu chỉ có một số
    final numMatch = RegExp(r'(\d+[\.,]?\d*)').firstMatch(value.replaceAll(',', '.'));
    if (numMatch != null) {
      final num = numMatch.group(1);
      final unit = value.replaceAll(num!, '').trim();
      return '$num${unit.isNotEmpty ? ' $unit' : ''}';
    }
    return value;
  }
} 