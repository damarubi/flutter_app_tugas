import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/services/session_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nipController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  late final LoginUseCase _loginUseCase;
  late final SessionService _sessionService;

  @override
  void initState() {
    super.initState();
    // Initialize services
    _sessionService = SessionService.instance;

    // Initialize use case with dependencies
    final authDataSource = AuthRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    );
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: authDataSource,
      sessionService: _sessionService,
    );
    _loginUseCase = LoginUseCase(authRepository);
  }

  @override
  void dispose() {
    _nipController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Call login use case
      // Hapus "final user =" karena variabelnya tidak dipakai
      await _loginUseCase.call(
        nip: _nipController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Session sudah disimpan otomatis di repository

      if (mounted) {
        // 3. Navigate ke main page
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.login), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const FlutterLogo(size: 100),
                const SizedBox(height: 30),
                const Text(
                  AppStrings.welcome,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  AppStrings.loginToContinue,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),

                // NIP Input
                CustomTextField(
                  controller: _nipController,
                  labelText: AppStrings.nip,
                  prefixIcon: Icons.badge,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateNIP,
                ),
                const SizedBox(height: 16),

                // Password Input
                CustomTextField(
                  controller: _passwordController,
                  labelText: AppStrings.password,
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 8),

                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Login Button
                CustomButton(
                  text: AppStrings.login,
                  onPressed: _login,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(AppStrings.dontHaveAccount),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.register);
                      },
                      child: const Text(AppStrings.register),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
