import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text('Create Account', style: AppTextStyles.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Join Delilah and start creating', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.xxxl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.softStone,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sign Up', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: AppSpacing.md),
                    Text('Please register through the web interface.', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.lg),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Already have an account? Sign in',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.actionBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}