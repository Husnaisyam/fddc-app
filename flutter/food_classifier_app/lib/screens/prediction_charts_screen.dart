import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/food_models.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class PredictionChartsScreen extends StatefulWidget {
  const PredictionChartsScreen({super.key});

  @override
  State<PredictionChartsScreen> createState() => _PredictionChartsScreenState();
}

class _PredictionChartsScreenState extends State<PredictionChartsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  List<FoodPrediction> _predictions = [];
  bool _isLoading = true;
  late TabController _tabController;
  final Map<String, Color> _foodColors = {};
  final List<Color> _defaultColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPredictions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPredictions() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = await _authService.getCurrentUser();

    if (currentUser == null || !mounted) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final predictions = await _apiService.getUserPredictions(currentUser.id);

      // Sort predictions by date
      predictions.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted) return;

      // Assign colors to food types
      int colorIndex = 0;
      for (var prediction in predictions) {
        if (!_foodColors.containsKey(prediction.foodName)) {
          _foodColors[prediction.foodName] =
              _defaultColors[colorIndex % _defaultColors.length];
          colorIndex++;
        }
      }

      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading predictions: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Analytics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Food Types', icon: Icon(Icons.pie_chart)),
            Tab(text: 'Nutrition', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Radar Chart', icon: Icon(Icons.radar)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _predictions.isEmpty
              ? const Center(
                  child: Text(
                    'No prediction data available.\nClassify some foods to see analytics!',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 18.0, fontStyle: FontStyle.italic),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFoodTypeDistributionChart(),
                    _buildNutritionComparisonChart(),
                    _buildTimelineChart(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: _loadPredictions,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildFoodTypeDistributionChart() {
    // Count occurrences of each food type
    final Map<String, int> foodCounts = {};
    for (var prediction in _predictions) {
      foodCounts[prediction.foodName] =
          (foodCounts[prediction.foodName] ?? 0) + 1;
    }

    // Sort by frequency
    final sortedFoodTypes = foodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Prepare pie chart sections
    final sections = <PieChartSectionData>[];
    for (var entry in sortedFoodTypes) {
      sections.add(
        PieChartSectionData(
          value: entry.value.toDouble(),
          title: '${entry.key}\n${entry.value}',
          color: _foodColors[entry.key] ?? Colors.grey,
          radius: 150,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Food Type Distribution',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 16.0,
            runSpacing: 8.0,
            children: sortedFoodTypes.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: _foodColors[entry.key] ?? Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(entry.key),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionComparisonChart() {
    // Filter predictions with nutrition data
    final nutritionPredictions = _predictions
        .where((p) =>
            p.calories != null &&
            p.protein != null &&
            p.carbs != null &&
            p.fats != null)
        .toList();

    if (nutritionPredictions.isEmpty) {
      return const Center(
        child: Text(
          'No nutrition data available',
          style: TextStyle(fontSize: 18.0, fontStyle: FontStyle.italic),
        ),
      );
    }

    // Group by food name and calculate averages
    final Map<String, Map<String, double>> nutritionByFood = {};
    for (var prediction in nutritionPredictions) {
      if (!nutritionByFood.containsKey(prediction.foodName)) {
        nutritionByFood[prediction.foodName] = {
          'calories': 0,
          'protein': 0,
          'carbs': 0,
          'fats': 0,
          'count': 0,
        };
      }
      nutritionByFood[prediction.foodName]!['calories'] =
          (nutritionByFood[prediction.foodName]!['calories']! +
              (prediction.calories ?? 0));
      nutritionByFood[prediction.foodName]!['protein'] =
          (nutritionByFood[prediction.foodName]!['protein']! +
              (prediction.protein ?? 0));
      nutritionByFood[prediction.foodName]!['carbs'] =
          (nutritionByFood[prediction.foodName]!['carbs']! +
              (prediction.carbs ?? 0));
      nutritionByFood[prediction.foodName]!['fats'] =
          (nutritionByFood[prediction.foodName]!['fats']! +
              (prediction.fats ?? 0));
      nutritionByFood[prediction.foodName]!['count'] =
          (nutritionByFood[prediction.foodName]!['count']! + 1);
    }

    // Calculate averages
    nutritionByFood.forEach((food, data) {
      final count = data['count']!;
      data['calories'] = data['calories']! / count;
      data['protein'] = data['protein']! / count;
      data['carbs'] = data['carbs']! / count;
      data['fats'] = data['fats']! / count;
    });

    // Sort by calories
    final sortedFoods = nutritionByFood.entries.toList()
      ..sort((a, b) => b.value['calories']!.compareTo(a.value['calories']!));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nutritional Comparison',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: sortedFoods.isEmpty
                    ? 100
                    : sortedFoods.first.value['calories']! * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final food = sortedFoods[groupIndex].key;
                      final data = sortedFoods[groupIndex].value;
                      return BarTooltipItem(
                        '$food\nCalories: ${data['calories']!.toStringAsFixed(1)}\n'
                        'Protein: ${data['protein']!.toStringAsFixed(1)}g\n'
                        'Carbs: ${data['carbs']!.toStringAsFixed(1)}g\n'
                        'Fats: ${data['fats']!.toStringAsFixed(1)}g',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= sortedFoods.length || value < 0)
                          return const SizedBox();
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              sortedFoods[value.toInt()].key,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true),
                barGroups: List.generate(sortedFoods.length, (index) {
                  final food = sortedFoods[index].key;
                  final data = sortedFoods[index].value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data['calories']!,
                        color: _foodColors[food] ?? Colors.blue,
                        width: 15,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Tap on bars to see detailed nutritional information',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineChart() {
    if (_predictions.isEmpty) {
      return const Center(
        child: Text(
          'No data available for radar chart',
          style: TextStyle(fontSize: 18.0, fontStyle: FontStyle.italic),
        ),
      );
    }

    // Count occurrences of each food type
    final Map<String, int> foodCounts = {};
    for (var prediction in _predictions) {
      foodCounts[prediction.foodName] =
          (foodCounts[prediction.foodName] ?? 0) + 1;
    }

    // Sort by name for consistent display
    final sortedFoodTypes = foodCounts.keys.toList()..sort();

    // Get the highest count for scaling
    final maxCount = foodCounts.values
        .reduce((max, count) => count > max ? count : max)
        .toDouble();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Food Predictions Radar Chart',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: RadarChart(
              RadarChartData(
                radarTouchData: RadarTouchData(
                  touchCallback: (FlTouchEvent event, response) {},
                  enabled: true,
                ),
                dataSets: [
                  RadarDataSet(
                    dataEntries: sortedFoodTypes.map((foodName) {
                      return RadarEntry(
                        value: foodCounts[foodName]!.toDouble(),
                      );
                    }).toList(),
                    borderWidth: 2,
                    entryRadius: 5,
                    borderColor: Colors.red,
                    fillColor: Colors.red.withOpacity(0.2),
                  ),
                ],
                radarBorderData: const BorderSide(color: Colors.grey),
                tickBorderData: const BorderSide(color: Colors.transparent),
                gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ticksTextStyle:
                    const TextStyle(color: Colors.black, fontSize: 10),
                tickCount: 5,
                getTitle: (index, angle) {
                  if (index >= sortedFoodTypes.length)
                    return RadarChartTitle(text: '', angle: angle);
                  return RadarChartTitle(
                      text: sortedFoodTypes[index], angle: angle);
                },
                titlePositionPercentageOffset: 0.15,
                titleTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
                radarShape: RadarShape.polygon,
              ),
              swapAnimationDuration: const Duration(milliseconds: 400),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 16.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: sortedFoodTypes.map((foodName) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: _foodColors[foodName] ?? Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text('$foodName (${foodCounts[foodName]})'),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
