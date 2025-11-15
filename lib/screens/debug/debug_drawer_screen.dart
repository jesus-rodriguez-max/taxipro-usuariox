import 'package:flutter/material.dart';
import 'package:taxipro_usuariox/widgets/app_drawer.dart';
import 'package:taxipro_usuariox/theme.dart';

class DebugDrawerScreen extends StatefulWidget {
  const DebugDrawerScreen({super.key, this.forceDark, this.forceLight});
  final bool? forceDark;
  final bool? forceLight;

  @override
  State<DebugDrawerScreen> createState() => _DebugDrawerScreenState();
}

class _DebugDrawerScreenState extends State<DebugDrawerScreen> {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _key.currentState?.openDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
        key: _key,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _key.currentState?.openDrawer(),
          ),
        ),
        body: const Center(child: Text('Debug Drawer Preview')));

    if (widget.forceDark == true) {
      return Theme(data: AppTheme.dark(), child: content);
    }
    if (widget.forceLight == true) {
      return Theme(data: AppTheme.light(), child: content);
    }
    return content;
  }
}
