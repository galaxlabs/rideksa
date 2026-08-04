import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});
  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark, AppColors.darkBackground],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 76, height: 76,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accent, AppColors.accentLight]),
                        boxShadow: [
                          BoxShadow(color: AppColors.accent.withAlpha(70), blurRadius: 24, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryLight]),
                        ),
                        child: const Icon(Icons.directions_car, color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Ride', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                        Text('KSA', style: TextStyle(color: AppColors.accentLight, fontSize: 30, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('What is your purpose of use?', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Choose first, then sign in with Google or email.', style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 12)),
                    const SizedBox(height: 32),
                    _RoleCard(
                      icon: Icons.person_outline, title: 'I want to travel', subtitle: 'Passenger: choose city, GPS pickup, or group trip',
                      onTap: () => _selectRole(context, UserRole.passenger),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      icon: Icons.directions_car_outlined, title: 'Become a Captain', subtitle: 'Driver: register vehicles, accept trips, and earn',
                      onTap: () => _selectRole(context, UserRole.driver),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      icon: Icons.business_outlined, title: 'Customer Company', subtitle: 'Register a company for staff, school, or corporate transport',
                      onTap: () => _selectRole(context, UserRole.customerCompany),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      icon: Icons.local_shipping_outlined, title: 'Partner / Transport Company', subtitle: 'Offer vehicles, drivers, rentals, travel, and transport services',
                      onTap: () => _selectRole(context, UserRole.partnerCompany),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, UserRole role) {
    context.read<AuthProvider>().selectPurpose(role);
    context.push('/auth/login', extra: role);
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryLight]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.accentLight, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13)),
            ])),
            Icon(Icons.chevron_right, color: AppColors.accent.withAlpha(160)),
          ]),
        ),
      ),
    );
  }
}
