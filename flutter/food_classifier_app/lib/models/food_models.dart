class FoodCategory {
  final int id;
  final String name;
  final String description;
  final DateTime createdAt;

  FoodCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  factory FoodCategory.fromMap(Map<String, dynamic> map) {
    return FoodCategory(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class FoodInfo {
  final int id;
  final String name;
  final String description;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final String nutritionalInfo;
  final String culturalInfo;

  FoodInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.nutritionalInfo,
    required this.culturalInfo,
  });

  factory FoodInfo.fromJson(Map<String, dynamic> json) {
    return FoodInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      calories: json['calories'] ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fats: (json['fats'] as num?)?.toDouble() ?? 0.0,
      nutritionalInfo: json['nutritional_info'] ?? '',
      culturalInfo: json['cultural_info'] ?? '',
    );
  }
}

class IngredientPrediction {
  final String name;
  final double confidence;

  IngredientPrediction({
    required this.name,
    required this.confidence,
  });

  factory IngredientPrediction.fromJson(Map<String, dynamic> json) {
    return IngredientPrediction(
      name: json['name'],
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class FoodPrediction {
  final int id;
  final double confidence;
  final DateTime createdAt;
  final String imagePath;
  final String foodName;
  final String? foodDescription;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fats;
  final List<IngredientPrediction> ingredients;

  FoodPrediction({
    required this.id,
    required this.confidence,
    required this.createdAt,
    required this.imagePath,
    required this.foodName,
    this.foodDescription,
    this.calories,
    this.protein,
    this.carbs,
    this.fats,
    List<IngredientPrediction>? ingredients,
  }) : ingredients = ingredients ?? [];

  factory FoodPrediction.fromJson(Map<String, dynamic> json) {
    List<IngredientPrediction> ingredientsList = [];
    if (json['ingredients'] != null) {
      final ingredients = json['ingredients'] as List;
      ingredientsList = ingredients
          .map((i) => IngredientPrediction.fromJson(i))
          .toList()
        ..sort((a, b) =>
            b.confidence.compareTo(a.confidence)); // Sort by confidence
    }

    return FoodPrediction(
      id: json['id'],
      confidence: (json['confidence'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      imagePath: json['image_path'],
      foodName: json['food_name'],
      foodDescription: json['food_description'],
      calories: json['calories'] != null
          ? (json['calories'] as num).toDouble()
          : null,
      protein:
          json['protein'] != null ? (json['protein'] as num).toDouble() : null,
      carbs: json['carbs'] != null ? (json['carbs'] as num).toDouble() : null,
      fats: json['fats'] != null ? (json['fats'] as num).toDouble() : null,
      ingredients: ingredientsList,
    );
  }
}
