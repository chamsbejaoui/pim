import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/code_input_field.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isVerified = false;
  String _enteredCode = '';

  Future<void> _handleVerifyEmail() async {
    if (_enteredCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: AppTheme.blueFonce,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.verifyEmail(_enteredCode);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      setState(() {
        _isVerified = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: AppTheme.blueFonce,
          ),
        );
        // Navigate to login after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Email verification failed'),
            backgroundColor: AppTheme.blueFonce,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Email'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientDecoration,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _isVerified
                  ? _buildVerifiedView()
                  : Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 80,
                            color: AppTheme.blueFonce,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Verify Your Email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We\'ve sent a verification token to:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.darkGrey.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.email,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.blueFonce,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Please check your email and enter the 6-digit verification code:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.darkGrey.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 6-digit code input
                          CodeInputField(
                            length: 6,
                            controller: _codeController,
                            onChanged: (code) {
                              setState(() {
                                _enteredCode = code;
                              });
                            },
                            onCompleted: (code) {
                              _handleVerifyEmail();
                            },
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Enter the 6-digit code sent to your email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.darkGrey.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Verify button
                          Container(
                            decoration: AppTheme.buttonGradient,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _handleVerifyEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Verify Email',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            },
                            child: Text(
                              'Skip for now',
                              style: TextStyle(
                                color: AppTheme.darkGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          size: 100,
          color: AppTheme.primaryGreen,
        ),
        const SizedBox(height: 24),
        Text(
          'Email Verified!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your email has been successfully verified.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.darkGrey.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 32),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
        const SizedBox(height: 16),
        Text(
          'Redirecting to login...',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.darkGrey,
          ),
        ),
      ],
    );
  }
}
