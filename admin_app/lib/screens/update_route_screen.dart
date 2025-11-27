import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_app/components/log_data_to_server.dart';

class UpdateRouteScreen extends StatefulWidget {
  final Map<String, dynamic> routeData;
  
  const UpdateRouteScreen({super.key, required this.routeData});

  @override
  State<UpdateRouteScreen> createState() => _UpdateRouteScreenState();
}

class _UpdateRouteScreenState extends State<UpdateRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _dealerNameController = TextEditingController();
  final TextEditingController _dealerPhoneController = TextEditingController();
  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _endPointController = TextEditingController();
  final TextEditingController _totalDistanceController = TextEditingController();
  final TextEditingController _expectedTimeController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  List<Map<String, dynamic>> _checkpoints = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _routeNameController.text = widget.routeData['name'] ?? '';
    _dealerNameController.text = widget.routeData['dealer_name'] ?? '';
    _dealerPhoneController.text = widget.routeData['dealer_phone'] ?? '';
    _startPointController.text = widget.routeData['start'] ?? '';
    _endPointController.text = widget.routeData['end'] ?? '';
    _totalDistanceController.text = widget.routeData['distance_km'] ?? '';
    _expectedTimeController.text = widget.routeData['expected_time'] ?? '';
    
    // Fetch checkpoints
    _fetchCheckpoints();
  }

  Future<void> _fetchCheckpoints() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('routes')
          .doc(widget.routeData['id'])
          .collection('checkpoints')
          .orderBy('order')
          .get();
      
      setState(() {
        _checkpoints = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      });
    } catch (e) {
      print('Error fetching checkpoints: $e');
    }
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _dealerNameController.dispose();
    _dealerPhoneController.dispose();
    _startPointController.dispose();
    _endPointController.dispose();
    _totalDistanceController.dispose();
    _expectedTimeController.dispose();
    super.dispose();
  }

  Future<void> updateRouteData() async {
    final firestore = FirebaseFirestore.instance;
    
    setState(() => _isSubmitting = true);

    try {
      await firestore.collection('routes').doc(widget.routeData['id']).update({
        'name': _routeNameController.text.trim(),
        'dealer_name': _dealerNameController.text.trim(),
        'dealer_phone': _dealerPhoneController.text.trim(),
        'start': _startPointController.text.trim(),
        'end': _endPointController.text.trim(),
        'distance_km': _totalDistanceController.text.trim(),
        'expected_time': _expectedTimeController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await logEvent(
        event: 'Route Updated',
        message: 'Successfully updated route: ${widget.routeData['id']}',
        type: 'INFO',
      );

      setState(() => _isSubmitted = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      await logEvent(
        event: 'App Error',
        message: 'Error updating route Page:update_route_screen.',
        type: 'ERROR',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateCheckpoint(Map<String, dynamic> checkpoint) async {
    final nameController = TextEditingController(text: checkpoint['name']);
    final timeController = TextEditingController(text: checkpoint['expected_time'].toString());
    final latController = TextEditingController(text: checkpoint['location']?.latitude?.toString() ?? '');
    final longController = TextEditingController(text: checkpoint['location']?.longitude?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Update Checkpoint",
          style: TextStyle(color: Colors.tealAccent),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Checkpoint Name",
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: timeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Expected Time (Hours)",
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Latitude",
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: longController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Longitude",
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('routes')
                    .doc(widget.routeData['id'])
                    .collection('checkpoints')
                    .doc(checkpoint['id'])
                    .update({
                  'name': nameController.text.trim(),
                  'expected_time': int.tryParse(timeController.text.trim()) ?? 0,
                  'location': GeoPoint(
                    double.tryParse(latController.text.trim()) ?? 0.0,
                    double.tryParse(longController.text.trim()) ?? 0.0,
                  ),
                });
                
                Navigator.pop(context);
                _fetchCheckpoints(); // Refresh checkpoints
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Checkpoint updated successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating checkpoint: $e')),
                );
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCheckpoint(Map<String, dynamic> checkpoint) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Checkpoint'),
        content: Text('Are you sure you want to delete "${checkpoint['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('routes')
            .doc(widget.routeData['id'])
            .collection('checkpoints')
            .doc(checkpoint['id'])
            .delete();
        
        _fetchCheckpoints(); // Refresh checkpoints
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Checkpoint deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting checkpoint: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("Update Order"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Update Order Information",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  _buildTextField(
                    controller: _routeNameController,
                    label: "Order Name",
                    icon: Icons.alt_route,
                    validator: (v) => v!.isEmpty ? "Please enter order name" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _dealerNameController,
                    label: "Dealer Name",
                    icon: Icons.store,
                    validator: (v) => v!.isEmpty ? "Please enter dealer name" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _dealerPhoneController,
                    label: "Dealer Phone No",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? "Please enter dealer phone no" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _startPointController,
                    label: "Starting Point Name",
                    icon: Icons.location_on_outlined,
                    validator: (v) => v!.isEmpty ? "Please enter starting point name" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _endPointController,
                    label: "End Point Name",
                    icon: Icons.flag,
                    validator: (v) => v!.isEmpty ? "Please enter end point name" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _totalDistanceController,
                    label: "Total Distance in KM",
                    icon: Icons.location_on,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Please enter total distance in km" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _expectedTimeController,
                    label: "Expected Time in Hours",
                    icon: Icons.access_time,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Please enter expected time" : null,
                  ),
                  const SizedBox(height: 30),
                  
                  // Checkpoints Section
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      onPressed: () => _updateCheckpoint(checkpoint),
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blueAccent,
                                      ),
                                      tooltip: 'Edit Checkpoint',
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteCheckpoint(checkpoint),
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Delete Checkpoint',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Name: ${checkpoint['name']}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Expected Time: ${checkpoint['expected_time']} hours",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                if (checkpoint['location'] != null)
                                  Text(
                                    "Location: ${checkpoint['location'].latitude}, ${checkpoint['location'].longitude}",
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                Text(
                                  "Status: ${checkpoint['status']}",
                                  style: TextStyle(
                                    color: checkpoint['status'] == 'Reached'
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  else
                    const Center(
                      child: Text(
                        "No checkpoints found.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  
                  const SizedBox(height: 30),
                  
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
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
        onPressed: _isSubmitting ? null : () {
          if (_formKey.currentState!.validate()) {
            updateRouteData();
          }
        },
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
          _isSubmitting ? "Updating..." : "Update Order",
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
