import 'package:flutter/material.dart';
import '../widgets/app_sidebar.dart';

class SidebarPage extends StatelessWidget {
  final String title;
  final String path;
  final Widget body;
  final List<Widget>? actions;
  const SidebarPage({super.key, required this.title, required this.path, required this.body, this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leading: Builder(builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        )),
      ),
      drawer: AppSidebar(currentPath: path),
      body: body,
    );
  }
}
