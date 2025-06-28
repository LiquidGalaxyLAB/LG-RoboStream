import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/widgets.dart';

class LGConfigScreen extends StatefulWidget {
  final String currentHost;
  final String currentUsername;
  final String currentPassword;
  final Function(String host, String username, String password) onConfigSaved;

  const LGConfigScreen({
    Key? key,
    required this.currentHost,
    required this.currentUsername,
    required this.currentPassword,
    required this.onConfigSaved,
  }) : super(key: key);

  @override
  State<LGConfigScreen> createState() => _LGConfigScreenState();
}

class _LGConfigScreenState extends State<LGConfigScreen> {
  late TextEditingController _hostController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.currentHost);
    _usernameController = TextEditingController(text: widget.currentUsername);
    _passwordController = TextEditingController(text: widget.currentPassword);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveConfiguration() async {
    final host = _hostController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (host.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();
    
    // Simular validación/conexión
    await Future.delayed(const Duration(milliseconds: 800));
    
    widget.onConfigSaved(host, username, password);
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Liquid Galaxy Config',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6366F1)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildConfigForm(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liquid Galaxy Setup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Configure connection details to display sensor data on the Liquid Galaxy system',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigForm() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connection Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          
          CustomTextField(
            label: 'Host/IP Address',
            controller: _hostController,
            hintText: 'e.g., 192.168.1.100',
            icon: Icons.computer,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),
          
          CustomTextField(
            label: 'Username',
            controller: _usernameController,
            hintText: 'e.g., lg',
            icon: Icons.person,
          ),
          const SizedBox(height: 20),
          
          CustomTextField(
            label: 'Password',
            controller: _passwordController,
            hintText: 'Password',
            icon: Icons.lock,
            obscureText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: _isLoading ? 'Saving...' : 'Save Configuration',
        onPressed: _isLoading ? null : _saveConfiguration,
        icon: _isLoading ? null : Icons.save,
        isLoading: _isLoading,
      ),
    );
  }
}
