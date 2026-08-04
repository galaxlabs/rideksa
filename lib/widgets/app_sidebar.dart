import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class AppSidebar extends StatelessWidget {
  final String currentPath;
  const AppSidebar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role;
    final isDriver = role == UserRole.driver;
    final isAdmin = role == UserRole.customerCompany ||
        role == UserRole.partnerCompany ||
        role == UserRole.admin ||
        role == UserRole.travelAgent;

    final sections = <_SidebarSection>[
      _SidebarSection('MAIN', [
        _SidebarItem(icon: Icons.home_outlined, label: 'Home', path: isDriver ? '/driver' : isAdmin ? '/admin' : '/passenger'),
        _SidebarItem(icon: Icons.search, label: 'Search', path: '/passenger/search'),
      ]),
      _SidebarSection('RIDES', [
        _SidebarItem(icon: Icons.receipt_long_outlined, label: 'My Rides', path: '/passenger/my-rides'),
        _SidebarItem(icon: Icons.history, label: 'History', path: '/passenger/history'),
        _SidebarItem(icon: Icons.local_taxi_outlined, label: 'Bookings', path: '/passenger/bookings'),
        _SidebarItem(icon: Icons.groups_outlined, label: 'Groups', path: '/passenger/groups'),
      ]),
      _SidebarSection('FINANCE', [
        _SidebarItem(icon: Icons.wallet_outlined, label: 'Wallet', path: '/passenger/wallet'),
        _SidebarItem(icon: Icons.receipt_outlined, label: 'Invoices', path: '/passenger/invoices'),
      ]),
      _SidebarSection('ACCOUNT', [
        _SidebarItem(icon: Icons.notifications_outlined, label: 'Notifications', path: '/passenger/notifications'),
        _SidebarItem(icon: Icons.chat_bubble_outline, label: 'Chat', path: '/passenger/chat'),
        _SidebarItem(icon: Icons.person_outline, label: 'Profile', path: '/profile'),
        _SidebarItem(icon: Icons.settings_outlined, label: 'Settings', path: '/settings'),
      ]),
    ];

    return Drawer(
      child: Container(
        color: AppColors.darkSurface,
        child: SafeArea(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.directions_car, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text(AppConstants.appName, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(auth.user?.roleLabel ?? 'Choose your purpose', style: TextStyle(color: Colors.white.withAlpha(170), fontSize: 12)),
                ])),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final section in sections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                      child: Text(section.title, style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                    for (final item in section.items)
                      _SidebarTile(item: item, currentPath: currentPath),
                  ],
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: OutlinedButton.icon(
                      onPressed: () => auth.logout().then((_) => context.go('/auth/login')),
                      icon: const Icon(Icons.logout, size: 18, color: Colors.white70),
                      label: const Text('Sign Out', style: TextStyle(color: Colors.white70)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withAlpha(30)),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SidebarSection {
  final String title;
  final List<_SidebarItem> items;
  const _SidebarSection(this.title, this.items);
}

class _SidebarItem {
  final IconData icon;
  final String label;
  final String path;
  const _SidebarItem({required this.icon, required this.label, required this.path});
}

class _SidebarTile extends StatelessWidget {
  final _SidebarItem item;
  final String currentPath;
  const _SidebarTile({required this.item, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final selected = currentPath == item.path;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: selected ? AppColors.primary.withAlpha(35) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            context.go(item.path);
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Icon(item.icon, size: 20, color: selected ? AppColors.accentLight : Colors.white.withAlpha(160)),
              const SizedBox(width: 14),
              Text(item.label, style: TextStyle(
                color: selected ? Colors.white : Colors.white.withAlpha(180),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              )),
              const Spacer(),
              if (selected) Icon(Icons.chevron_right, size: 18, color: AppColors.accentLight.withAlpha(150)),
            ]),
          ),
        ),
      ),
    );
  }
}
