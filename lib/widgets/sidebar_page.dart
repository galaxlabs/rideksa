import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_sidebar.dart';

class SidebarPage extends StatelessWidget {
  final String title;
  final String path;
  final Widget body;
  final List<Widget>? actions;
  const SidebarPage({
    super.key,
    required this.title,
    required this.path,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    final homePath = switch (role) {
      UserRole.driver => '/driver',
      UserRole.customerCompany ||
      UserRole.partnerCompany ||
      UserRole.admin ||
      UserRole.travelAgent => '/admin',
      UserRole.superAdmin => '/super-admin',
      _ => '/passenger',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leadingWidth: 96,
        leading: Builder(
          builder: (context) => Row(
            children: [
              IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(homePath);
                  }
                },
              ),
              IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ],
          ),
        ),
      ),
      drawer: AppSidebar(currentPath: path),
      body: body,
    );
  }
}
