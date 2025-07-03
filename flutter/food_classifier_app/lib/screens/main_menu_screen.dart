import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
// Removed Lottie import

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = true;
  bool _isCalorieLoading = false;
  double _caloriesConsumed = 0;
  double _calorieTarget = 2000; // Default value
  List<Map<String, dynamic>> _calorieBreakdown = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final user = await _authService.getCurrentUser();

    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      if (user != null) {
        // Get user's recommended calorie intake if available
        final targetCalories = user.calculateDailyCalories();
        if (targetCalories != null) {
          setState(() {
            _calorieTarget = targetCalories;
          });
        }

        // Load user's calorie consumption for today
        _loadCalorieData(user.id);
      }
    }
  }

  Future<void> _loadCalorieData(int userId) async {
    try {
      // Set a loading state
      setState(() {
        _isCalorieLoading = true;
      });

      final calorieData = await _apiService.getUserCalorieData(userId);

      if (mounted) {
        // Use a small delay to allow animation to be visible
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _caloriesConsumed = calorieData['totalCalories'];
              _calorieBreakdown = calorieData['calorieBreakdown'];
              _isCalorieLoading = false;
            });
          }
        });
      }
    } catch (e) {
      print('Error loading calorie data: $e');
      if (mounted) {
        setState(() {
          _isCalorieLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading calorie data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null) {
      // If not logged in, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Classifier'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.camera_alt),
          //   onPressed: () => Navigator.pushNamed(context, '/classify'),
          //   tooltip: 'Camera',
          // ),
          // IconButton(
          //   icon: const Icon(Icons.photo_library),
          //   onPressed: () {
          //     Navigator.of(context)
          //         .pushNamed('/classify', arguments: 'open_gallery');
          //   },
          //   tooltip: 'Gallery',
          // ),
          // IconButton(
          //   icon: const Icon(Icons.restaurant_menu),
          //   onPressed: () => Navigator.pushNamed(context, '/food_info'),
          //   tooltip: 'Food Info',
          // ),
          // IconButton(
          //   icon: const Icon(Icons.history),
          //   onPressed: () => Navigator.pushNamed(context, '/history'),
          //   tooltip: 'History',
          // ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${_currentUser?.fullName ?? _currentUser?.username ?? "User"}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'What would you like to do today?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Calorie meter widget
            _buildCalorieMeter(),

            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  _buildMenuCard(
                    title: 'Camera Capture',
                    icon: Icons.camera_alt,
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/classify'),
                  ),
                  _buildMenuCard(
                    title: 'Gallery Upload',
                    icon: Icons.photo_library,
                    color: Colors.lightBlue,
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed('/classify', arguments: 'open_gallery');
                    },
                  ),
                  _buildMenuCard(
                    title: 'Food Info',
                    icon: Icons.restaurant_menu,
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/food_info'),
                  ),
                  _buildMenuCard(
                    title: 'History',
                    icon: Icons.history,
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/history'),
                  ),
                  // _buildMenuCard(
                  //   title: 'Profile',
                  //   icon: Icons.person,
                  //   color: Colors.purple,
                  //   onTap: () => Navigator.pushNamed(context, '/profile'),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieMeter() {
    // Calculate percentage of calorie target consumed (capped at 100%)
    final double percentage =
        (_caloriesConsumed / _calorieTarget).clamp(0.0, 1.0);
    final Color gaugeColor = percentage < 0.7
        ? Colors.green
        : (percentage < 0.9 ? Colors.orange : Colors.red);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Today\'s Calorie Consumption',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Expanded(child: SizedBox()),
              if (_isCalorieLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () {
                    if (_currentUser != null) {
                      _loadCalorieData(_currentUser!.id);
                    }
                  },
                  tooltip: 'Refresh calorie data',
                ),
            ],
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1.6,
            child: SfRadialGauge(
              animationDuration: 1500,
              enableLoadingAnimation: true,
              axes: [
                RadialAxis(
                  minimum: 0,
                  maximum: _calorieTarget,
                  startAngle: 150,
                  endAngle: 30,
                  showLabels: true,
                  showTicks: true,
                  radiusFactor: 0.8,
                  axisLabelStyle: const GaugeTextStyle(fontSize: 10),
                  ranges: [
                    GaugeRange(
                      startValue: 0,
                      endValue: _calorieTarget * 0.7,
                      color: Colors.green.withOpacity(0.3),
                      startWidth: 10,
                      endWidth: 10,
                    ),
                    GaugeRange(
                      startValue: _calorieTarget * 0.7,
                      endValue: _calorieTarget * 0.9,
                      color: Colors.orange.withOpacity(0.3),
                      startWidth: 10,
                      endWidth: 10,
                    ),
                    GaugeRange(
                      startValue: _calorieTarget * 0.9,
                      endValue: _calorieTarget,
                      color: Colors.red.withOpacity(0.3),
                      startWidth: 10,
                      endWidth: 10,
                    ),
                  ],
                  pointers: [
                    NeedlePointer(
                      value: _caloriesConsumed,
                      needleLength: 0.6,
                      needleStartWidth: 1,
                      needleEndWidth: 5,
                      knobStyle: const KnobStyle(
                        knobRadius: 8,
                        sizeUnit: GaugeSizeUnit.logicalPixel,
                      ),
                      enableAnimation: true,
                      animationType: AnimationType.ease,
                      needleColor: gaugeColor,
                    ),
                    RangePointer(
                      value: _caloriesConsumed,
                      width: 10,
                      color: gaugeColor,
                      enableAnimation: true,
                      animationType: AnimationType.ease,
                    ),
                  ],
                  annotations: [
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_caloriesConsumed.toInt()}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      positionFactor: 0.5,
                      angle: 90,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(_caloriesConsumed / _calorieTarget * 100).toInt()}% of daily target (${_calorieTarget.toInt()} kcal)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
