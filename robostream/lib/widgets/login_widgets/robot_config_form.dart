import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/services/robot_config_manager.dart';
import 'package:robostream/assets/styles/app_styles.dart';
import 'package:robostream/assets/styles/login_styles.dart';

class RobotConfigForm extends StatefulWidget {
  final Function(String) onConfigSuccess;
  final Function(String) onError;
  final VoidCallback onSkip;
  
  const RobotConfigForm({
    super.key,
    required this.onConfigSuccess,
    required this.onError,
    required this.onSkip,
  });

  @override
  State<RobotConfigForm> createState() => _RobotConfigFormState();
}

class _RobotConfigFormState extends State<RobotConfigForm> {
  final _robotIpController = TextEditingController();
  final _robotIpFocus = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _robotIpController.addListener(() => setState(() {}));
    _loadSavedRobotIp();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFeatureNotImplementedAlert();
    });
  }

  void _loadSavedRobotIp() async {
    final savedIp = await RobotConfigManager.instance.getSavedRobotIp();
    if (savedIp != null && savedIp.isNotEmpty && mounted) {
      setState(() {
        _robotIpController.text = savedIp;
      });
    }
  }

  void _showFeatureNotImplementedAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Feature Not Implemented'),
          content: const Text(
            'This robot IP configuration feature is not yet fully implemented. '
            'You can continue with the current configuration or set a robot IP (Just symbolic for now).',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _robotIpController.dispose();
    _robotIpFocus.dispose();
    super.dispose();
  }

  Future<void> _onConfigurePressed() async {
    HapticFeedback.mediumImpact();
    
    if (_robotIpController.text.trim().isEmpty) {
      widget.onError('Please enter the robot IP address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await RobotConfigManager.instance.saveRobotIp(_robotIpController.text.trim());
      
      if (mounted) {
        widget.onConfigSuccess(_robotIpController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        widget.onError('Error saving robot IP: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onSkipPressed() async {
    HapticFeedback.mediumImpact();
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRobotIpField(),
        const SizedBox(height: 32),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildRobotIpField() {
    return AnimatedBuilder(
      animation: _robotIpFocus,
      builder: (context, child) {
        final isFocused = _robotIpFocus.hasFocus;
        final hasContent = _robotIpController.text.isNotEmpty;
        final isActive = isFocused || hasContent;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: isActive ? 24 : 0,
                padding: EdgeInsets.only(
                  left: 20,
                  bottom: isActive ? 6 : 0,
                ),
                child: AnimatedOpacity(
                  opacity: isActive ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'ROBOT IP ADDRESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFocused 
                          ? AppStyles.primaryColor
                          : Colors.grey[600],
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: isFocused 
                          ? AppStyles.primaryColor.withOpacity(0.08)
                          : Colors.black.withOpacity(0.02),
                      blurRadius: isFocused ? 16 : 4,
                      offset: Offset(0, isFocused ? 6 : 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _robotIpController,
                  focusNode: _robotIpFocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  onSubmitted: (_) => _onConfigurePressed(),
                  onTap: () => HapticFeedback.selectionClick(),
                  decoration: InputDecoration(
                    labelText: !isActive ? 'Robot IP Address' : null,
                    hintText: isActive ? 'e.g., 192.168.1.100' : null,
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    labelStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isFocused 
                            ? LinearGradient(
                                colors: [
                                  AppStyles.primaryColor,
                                  AppStyles.secondaryColor,
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey[100]!,
                                  Colors.grey[200]!,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.smart_toy,
                        color: isFocused ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    filled: true,
                    fillColor: isFocused ? Colors.white : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: hasContent 
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: AppStyles.primaryColor,
                        width: 2.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: AppStyles.mediumDuration,
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppStyles.cardShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isLoading ? null : _onSkipPressed,
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.skip_next_rounded,
                        color: Colors.grey[700],
                        size: LoginStyles.buttonIconSize,
                      ),
                      const SizedBox(width: LoginStyles.buttonIconSpacing),
                      Text(
                        'Skip',
                        style: LoginStyles.buttonTextStyle.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedContainer(
            duration: AppStyles.mediumDuration,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppStyles.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _isLoading 
                  ? AppStyles.cardShadow 
                  : AppStyles.floatingShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isLoading ? null : _onConfigurePressed,
                child: Container(
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.router_rounded,
                              color: Colors.white,
                              size: LoginStyles.buttonIconSize,
                            ),
                            SizedBox(width: LoginStyles.buttonIconSpacing),
                            Text(
                              'Continue',
                              style: LoginStyles.buttonTextStyle,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
