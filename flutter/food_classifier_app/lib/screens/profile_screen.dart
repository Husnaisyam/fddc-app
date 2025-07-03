import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  User? _currentUser;
  bool _isLoading = true;
  bool _isEditing = false;

  // Form controllers
  late TextEditingController _fullNameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  String? _selectedGender;
  String? _selectedActivityLevel;

  final List<String> _genderOptions = ['male', 'female', 'other'];
  final List<Map<String, String>> _activityLevels = [
    {'value': 'sedentary', 'label': 'Sedentary (little or no exercise)'},
    {'value': 'lightly_active', 'label': 'Lightly Active (1-3 times/week)'},
    {
      'value': 'moderately_active',
      'label': 'Moderately Active (3-5 times/week)'
    },
    {'value': 'very_active', 'label': 'Very Active (6-7 times/week)'},
    {'value': 'super_active', 'label': 'Super Active (twice per day)'},
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
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

        // Initialize form controllers with current values
        _fullNameController.text = user?.fullName ?? '';
        _weightController.text = user?.weight?.toString() ?? '';
        _heightController.text = user?.height?.toString() ?? '';
        _selectedGender = user?.gender;
        _selectedActivityLevel = user?.activityLevel;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_currentUser == null || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = await _authService.updateProfile(
        _currentUser!.id,
        _fullNameController.text,
        double.tryParse(_weightController.text),
        double.tryParse(_heightController.text),
        _selectedGender,
        _selectedActivityLevel,
      );

      if (!mounted) return;

      if (updatedUser != null) {
        setState(() {
          _currentUser = updatedUser;
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  String _formatActivityLevel(String level) {
    return level
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildBMICard() {
    final bmi = _currentUser?.calculateBMI();
    final bmiCategory = _currentUser?.getBMICategory();

    if (bmi == null) return const SizedBox();

    Color categoryColor;
    if (bmi < 18.5) {
      categoryColor = Colors.blue;
    } else if (bmi < 25) {
      categoryColor = Colors.green;
    } else if (bmi < 30) {
      categoryColor = Colors.orange;
    } else {
      categoryColor = Colors.red;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'BMI Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      bmi.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('BMI'),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bmiCategory ?? 'Unknown',
                    style: TextStyle(
                      color: categoryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditablePhysicalInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Physical Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Height field
            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final height = double.tryParse(value);
                  if (height == null || height <= 0) {
                    return 'Please enter a valid height';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Weight field
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return 'Please enter a valid weight';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Gender dropdown
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: _genderOptions.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(
                    gender[0].toUpperCase() + gender.substring(1),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Activity level dropdown
            DropdownButtonFormField<String>(
              value: _selectedActivityLevel,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Activity Level',
                border: OutlineInputBorder(),
              ),
              items: _activityLevels.map((level) {
                return DropdownMenuItem(
                  value: level['value'],
                  child: Text(
                    level['label']!,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedActivityLevel = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalInfoCard() {
    if (_isEditing) {
      return _buildEditablePhysicalInfoCard();
    }
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Physical Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Height',
                '${_currentUser?.height?.toStringAsFixed(1) ?? "N/A"} cm'),
            _buildInfoRow('Weight',
                '${_currentUser?.weight?.toStringAsFixed(1) ?? "N/A"} kg'),
            _buildInfoRow(
                'Gender', _currentUser?.gender?.toUpperCase() ?? 'N/A'),
            _buildInfoRow(
                'Activity Level',
                _currentUser?.activityLevel != null
                    ? _formatActivityLevel(_currentUser!.activityLevel!)
                    : 'N/A'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Profile',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _currentUser == null
              ? const Center(
                  child: Text('Not logged in'),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Profile avatar
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.purple.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_isEditing) ...[
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          Text(
                            _currentUser!.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '@${_currentUser!.username}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // BMI Card
                        if (!_isEditing) _buildBMICard(),
                        const SizedBox(height: 16),

                        // Physical Information Card
                        _buildPhysicalInfoCard(),
                        const SizedBox(height: 16),

                        if (_isEditing) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    // Reset form values
                                    _fullNameController.text =
                                        _currentUser?.fullName ?? '';
                                    _weightController.text =
                                        _currentUser?.weight?.toString() ?? '';
                                    _heightController.text =
                                        _currentUser?.height?.toString() ?? '';
                                    _selectedGender = _currentUser?.gender;
                                    _selectedActivityLevel =
                                        _currentUser?.activityLevel;
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: _saveChanges,
                                child: const Text('Save Changes'),
                              ),
                            ],
                          ),
                        ],

                        if (!_isEditing) ...[
                          // Basic Information Card
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Contact Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow('Email', _currentUser!.email),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}
