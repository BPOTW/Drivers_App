import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateRouteScreen extends StatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _dealerNameController = TextEditingController();
  final TextEditingController _dealerPhoneController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _endPointController = TextEditingController();
  final TextEditingController _driverIdController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverPhoneController = TextEditingController();
  final TextEditingController _totalDistanceController =
      TextEditingController();
  final TextEditingController _expectedTimeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _selectedDriverId; // Track selected driver

  List<Map<String, dynamic>> _checkpoints = [];

  Future<void> addRouteDataToDatabase(
    Map<String, dynamic> routeData,
    List<Map<String, dynamic>> checkpoints,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      final routeRef = firestore.collection('routes').doc();
      final routeId = routeRef.id;      

      // Add driver info directly to route document
      // final routeDataWithDriver = {
      //   ...routeData['route'],
      //   {'driver_id': routeData['driver_info']['driver_id'],
      //   'driver_name': routeData['driver_info']['name'],
      //   'driver_phone': routeData['driver_info']['phone_no'],
      //   'vehicle_no': routeData['driver_info']['vehicle_no'],
      //   'assigned_at': routeData['driver_info']['assigned_at'],}
      // };

      print(routeData);

      batch.set(routeRef, routeData);
      // batch.set(assignedDriversRef, routeData['driver_info']);

      // batch.set(routeRef, routeDataWithDriver);

      int i = 1;
      for (var checkpoint in checkpoints) {
        final checkpointRef = routeRef.collection('checkpoints').doc();
        final lat = checkpoint['latitude'].text != '' ? double.parse(checkpoint['latitude'].text) : 0.0;
        final long = checkpoint['longitude'].text != '' ? double.parse(checkpoint['longitude'].text) : 0.0;
        batch.set(checkpointRef, {
          'name': checkpoint['name'].text,
          'expected_time': int.parse(checkpoint['expected_time'].text),
          'location': GeoPoint(
            lat,long
          ),
          'time_reached': Timestamp.now(),
          'order': i,
          'has_reached': false,
          'status': "Pending",
        });
        i++;
      }

      // Update user with routeId
      final userRef = firestore
          .collection('users')
          .doc(routeData['driver_info']['driver_id']);
      batch.update(userRef, {
        'route_id': routeId,
        'route_name': routeData['name'],
        'dealer_info':{
          'name':routeData['dealer_name'],
          'id':'',
          'phone_no':routeData['dealer_phone'],
        },
        'key_active':true,
        'is_delivery_assigned':true,
      });

      // Update live location with routeId
      final liveLocationRef = firestore
          .collection('live_locations')
          .doc(routeData['driver_info']['driver_id']);
      batch.update(liveLocationRef, {'route_id': routeId});

      // Commit all writes atomically
      await batch.commit();

      setState(() => _isSubmitted = true);
    } catch (e) {
      
    setState(() {
      _isSubmitting = false;
    });
      debugPrint("Error adding route data: $e");
    }
    setState(() {
      _isSubmitting = false;
    });
  }

  void _addCheckpoint() {
    setState(() {
      _checkpoints.add({
        'name': TextEditingController(),
        'expected_time': TextEditingController(),
        'latitude': TextEditingController(),
        'longitude': TextEditingController(),
      });
    });
  }

  void _removeCheckpoint(int index) {
    setState(() {
      _checkpoints.removeAt(index);
    });
  }

  Future<List<Map<String, dynamic>>> fetchDrivers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          // .where('is_delivery_assigned', isEqualTo: false)
          .get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error fetching drivers: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("Create New Route"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Driver (Single Selection)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchDrivers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.tealAccent,
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "Error: ${snapshot.error}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          final drivers = snapshot.data ?? [];

                          if (drivers.isEmpty) {
                            return const Center(
                              child: Text(
                                "No drivers found.",
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            radius: const Radius.circular(8),
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: drivers.length,
                              itemBuilder: (context, index) {
                                final driver = drivers[index];
                                final isSelected = _selectedDriverId == driver['id'];
                                return Card(
                                  color: isSelected 
                                      ? Colors.tealAccent.withOpacity(0.3)
                                      : Colors.teal.withOpacity(0.15),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: isSelected 
                                        ? const BorderSide(color: Colors.tealAccent, width: 2)
                                        : BorderSide.none,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: isSelected 
                                        ? const Icon(Icons.check_circle, color: Colors.tealAccent)
                                        : const Icon(Icons.person, color: Colors.white70),
                                    title: Text(
                                      driver['name'] ?? 'Unnamed',
                                      style: TextStyle(
                                        color: isSelected ? Colors.tealAccent : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Driver ID: ${driver['id']}",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          "Vehicle: ${driver['vehicle_id'] ?? '-'}",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          "Phone: ${driver['phone_no'] ?? '-'}",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedDriverId = driver['id'];
                                        _driverIdController.text =
                                            driver['id'] ?? '';
                                        _driverNameController.text =
                                            driver['name'] ?? '';
                                        _driverPhoneController.text =
                                            driver['phone_no'] ?? '';
                                        _vehicleNoController.text =
                                            driver['vehicle_id'] ?? '';
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Driver ${driver['name']} selected",
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Right Side - Route Form
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: _routeNameController,
                            label: "Route Name",
                            icon: Icons.alt_route,
                            validator: (v) =>
                                v!.isEmpty ? "Please enter route name" : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _driverIdController,
                            label: "Driver Id",
                            icon: Icons.drive_eta,
                            validator: (v) =>
                                v!.isEmpty ? "Please enter driver id" : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _driverNameController,
                            label: "Driver Name",
                            icon: Icons.person,
                            validator: (v) =>
                                v!.isEmpty ? "Please enter driver name" : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _driverPhoneController,
                            label: "Driver Phone No.",
                            icon: Icons.phone,
                            validator: (v) => v!.isEmpty
                                ? "Please enter driver phone no."
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _vehicleNoController,
                            label: "Vehicle No",
                            icon: Icons.local_shipping,
                            validator: (v) =>
                                v!.isEmpty ? "Please enter vehicle no" : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _dealerNameController,
                            label: "Dealer Name",
                            icon: Icons.store,
                            validator: (v) =>
                                v!.isEmpty ? "Please enter dealer name" : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _dealerPhoneController,
                            label: "Dealer Phone No",
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.isEmpty
                                ? "Please enter dealer phone no"
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _startPointController,
                            label: "Starting Point Name",
                            icon: Icons.location_on_outlined,
                            validator: (v) => v!.isEmpty
                                ? "Please enter starting point name"
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _endPointController,
                            label: "End Point Name",
                            icon: Icons.flag,
                            validator: (v) => v!.isEmpty
                                ? "Please enter end point name"
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _totalDistanceController,
                            label: "Total Distance in KM",
                            icon: Icons.location_on,
                            validator: (v) => v!.isEmpty
                                ? "Please enter total distance in km"
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _expectedTimeController,
                            label: "Expected Time in Hours ",
                            icon: Icons.access_time,
                            validator: (v) => v!.isEmpty
                                ? "Please enter expected time"
                                : null,
                          ),
                          const SizedBox(height: 30),
                          const Divider(color: Colors.white24),
                          const Text(
                            "Checkpoints",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Add Checkpoint Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _addCheckpoint,
                              icon: const Icon(Icons.add_location_alt),
                              label: const Text("Add Checkpoint"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent[700],
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Checkpoints List
                          if (_checkpoints.isNotEmpty)
                            ListView.builder(
                              itemCount: _checkpoints.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final checkpoint = _checkpoints[index];
                                return Card(
                                  color: Colors.grey[850],
                                  margin: const EdgeInsets.only(bottom: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.tealAccent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "Checkpoint ${index + 1}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              onPressed: () =>
                                                  _removeCheckpoint(index),
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _buildTextField(
                                          controller: checkpoint['name'],
                                          label: "Checkpoint Name",
                                          icon: Icons.location_pin,
                                          validator: (v) => v!.isEmpty
                                              ? "Enter checkpoint name"
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(
                                          controller:
                                              checkpoint['expected_time'],
                                          label: "Expected Time (In Hours)",
                                          icon: Icons.access_time,
                                          validator: (v) => v!.isEmpty
                                              ? "Enter expected time"
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    checkpoint['latitude'],
                                                label: "Latitude (optional)",
                                                icon: Icons.my_location,
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                      signed: true,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _buildTextField(
                                                controller:
                                                    checkpoint['longitude'],
                                                label: "Longitude (optional)",
                                                icon:
                                                    Icons.my_location_outlined,
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                      signed: true,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 30),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller, 
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.tealAccent) : null,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[850],
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.tealAccent.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.tealAccent),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.tealAccent[700],
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _isSubmitting ? null : _handleSubmit,
        icon: _isSubmitting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.save, color: Colors.black),
        label: Text(
          _isSubmitting ? "Creating..." : "Create Route",
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // final routeData = {
    //   'route':{'checkpoints': _checkpoints.length,
    //   'created_at': DateTime.now().toIso8601String(),
    //   'dealer_name': _dealerNameController.text.trim(),
    //   'dealer_phone': _dealerPhoneController.text.trim(),
    //   'distance_km': _totalDistanceController.text.trim(),
    //   'end': _endPointController.text.trim(),
    //   'expected_time': _expectedTimeController.text.trim(),
    //   'is_active': true,
    //   'name': _routeNameController.text.trim(),
    //   'start': _startPointController.text.trim(),
    //   'is_completed':false,
    //   'status': 'Pending',},
    //   'driver_info': {
    //     'driver_id': _driverIdController.text.trim(),
    //     'name': _driverNameController.text.trim(),
    //     'phone_no': _driverPhoneController.text.trim(),
    //     'vehicle_no': _vehicleNoController.text.trim(),
    //     'assigned_at': DateTime.now().toIso8601String(),
    //   }
    // };
    final routeData = {
      'checkpoints': _checkpoints.length,
      'created_at': DateTime.now().toIso8601String(),
      'dealer_name': _dealerNameController.text.trim(),
      'dealer_phone': _dealerPhoneController.text.trim(),
      'distance_km': _totalDistanceController.text.trim(),
      'end': _endPointController.text.trim(),
      'expected_time': _expectedTimeController.text.trim(),
      'is_active': true,
      'name': _routeNameController.text.trim(),
      'start': _startPointController.text.trim(),
      'is_completed':false,
      'status': 'Pending',
      'driver_info': {
        'driver_id': _driverIdController.text.trim(),
        'name': _driverNameController.text.trim(),
        'phone_no': _driverPhoneController.text.trim(),
        'vehicle_no': _vehicleNoController.text.trim(),
        'assigned_at': DateTime.now().toIso8601String(),
      }
    };

    await addRouteDataToDatabase(routeData, _checkpoints);

    if (mounted && _isSubmitted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Route created successfully!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong! Try again')),
      );
    }
  }
}
