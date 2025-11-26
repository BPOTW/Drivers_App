import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_app/components/log_data_to_server.dart';

class UpdateUserScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const UpdateUserScreen({super.key, required this.userData});

  @override
  State<UpdateUserScreen> createState() => _UpdateUserScreenState();
}

class _UpdateUserScreenState extends State<UpdateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleIdController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController.text = widget.userData['name'] ?? '';
    _phoneController.text = widget.userData['phone_no'] ?? '';
    _vehicleIdController.text = widget.userData['vehicle_id'] ?? '';
    _ageController.text = widget.userData['age']?.toString() ?? '';
    _genderController.text = widget.userData['gender'] ?? '';
    _nicController.text = widget.userData['nic'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleIdController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  Future<void> updateUserData() async {
    final firestore = FirebaseFirestore.instance;
    
    setState(() => _isSubmitting = true);

    try {
      await firestore.collection('users').doc(widget.userData['id']).update({
        'name': _nameController.text.trim(),
        'phone_no': _phoneController.text.trim(),
        'vehicle_id': _vehicleIdController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'gender': _genderController.text.trim(),
        'nic': _nicController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await logEvent(
        event: 'User Updated',
        message: 'Successfully updated user: ${widget.userData['id']}',
        type: 'INFO',
      );

      setState(() => _isSubmitted = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      await logEvent(
        event: 'App Error',
        message: 'Error updating user Page:update_user_screen.',
        type: 'ERROR',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("Update User"),
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
                    "Update User Information",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  _buildTextField(
                    controller: _nameController,
                    label: "Full Name",
                    icon: Icons.person,
                    validator: (v) => v!.isEmpty ? "Please enter full name" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _phoneController,
                    label: "Phone Number",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? "Please enter phone number" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _vehicleIdController,
                    label: "Vehicle ID",
                    icon: Icons.drive_eta,
                    validator: (v) => v!.isEmpty ? "Please enter vehicle ID" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _ageController,
                    label: "Age",
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Please enter age" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _genderController,
                    label: "Gender",
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? "Please enter gender" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _nicController,
                    label: "NIC",
                    icon: Icons.badge,
                    validator: (v) => v!.isEmpty ? "Please enter NIC" : null,
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
            updateUserData();
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
          _isSubmitting ? "Updating..." : "Update User",
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
