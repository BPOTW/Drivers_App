import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _NICController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _loginKeyController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();

  String _selectedRole = 'Driver';
  String _selectedStatus = 'Active';
  bool _isSubmitting = false;
  bool _isCheckingKey = false;

  Future<bool> _isLoginKeyAvailable(String loginKey) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('login_key', isEqualTo: loginKey.trim())
          .get();
      
      return snapshot.docs.isEmpty; // Returns true if no documents found (key is available)
    } catch (e) {
      print('Error checking login key: $e');
      return false; // Return false on error to prevent creation
    }
  }

  Future<bool> _isNICAvailable(String nic) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('nic', isEqualTo: nic.trim())
          .get();
      
      return snapshot.docs.isEmpty; // Returns true if no documents found (NIC is available)
    } catch (e) {
      print('Error checking NIC: $e');
      return false; // Return false on error to prevent creation
    }
  }

  Future<void> addUser() async {
    try {
      if (!_formKey.currentState!.validate()) return;
      
      // Check if login key and NIC are available
      setState(() {
        _isCheckingKey = true;
      });
      
      final isKeyAvailable = await _isLoginKeyAvailable(_loginKeyController.text);
      final isNICAvailable = await _isNICAvailable(_NICController.text);
      
      if (!isKeyAvailable) {
        setState(() {
          _isCheckingKey = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login key is already in use. Please choose a different key."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (!isNICAvailable) {
        setState(() {
          _isCheckingKey = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("NIC number is already registered. Please check the details."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _isSubmitting = true;
        _isCheckingKey = false;
      });
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc();

      batch.set(userRef, {
        'name': _nameController.text,
        'age': _ageController.text,
        'gender': _genderController.text,
        'phone_no': _phoneController.text,
        'nic': _NICController.text,
        'role': _selectedRole,
        'login_key': _loginKeyController.text,
        'key_active': false,
        'is_delivery_assigned': false,
        'route_id' : '',
        'status': _selectedStatus,
        'vehicle_id': _vehicleNoController.text,
        'dealer_info': {'name': '', 'phone_no': ''},
        'createdAt': FieldValue.serverTimestamp(),
      });
      final liveLocationRef = FirebaseFirestore.instance.collection('live_locations').doc(userRef.id);

      batch.set(liveLocationRef,{
        'driver_id': userRef.id,
        'driver_name': _nameController.text,
        'location': GeoPoint(0,0),
        'route_id': '',
        'status': 'Not Moving',
        'last_updated': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      print('User added successfully!');
      Navigator.pop(context);
    } catch (e) {
      print('Error adding user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong!")),
      );
    }
    setState(() {
        _isSubmitting = false;
      });
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("Create New User"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ageController,
                    label: 'Age',
                    icon: Icons.person,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _genderController,
                    label: 'Gender',
                    icon: Icons.person,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _NICController,
                    label: 'NIC No.',
                    icon: Icons.person,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter phone number' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _loginKeyController,
                    label: 'Login Key',
                    icon: Icons.key,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter login key' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _vehicleNoController,
                    label: 'Vehicle No (optional)',
                    icon: Icons.directions_car,
                    
                  ),
                  const SizedBox(height: 16),

                  // Role Dropdown
                  _buildDropdownField(
                    label: 'Role',
                    value: _selectedRole,
                    items: const ['Driver', 'Dealer'],
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                  const SizedBox(height: 16),

                  // Status Dropdown
                  _buildDropdownField(
                    label: 'Status',
                    value: _selectedStatus,
                    items: const ['Active', 'Non-Active'],
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: (_isSubmitting || _isCheckingKey) ? null : addUser,
                      icon: (_isSubmitting || _isCheckingKey)
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
                        _isCheckingKey ? "Checking Key..." : (_isSubmitting ? "Creating..." : "Create User"),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
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
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.tealAccent),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.grey[850],
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
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
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

}
