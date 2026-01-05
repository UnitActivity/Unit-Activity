import 'package:flutter/material.dart';

class UserPageWrapper extends StatefulWidget {
  final Widget child;
  final String pageName;

  const UserPageWrapper({
    required this.child,
    required this.pageName,
    super.key,
  });

  @override
  State<UserPageWrapper> createState() => _UserPageWrapperState();
}

class _UserPageWrapperState extends State<UserPageWrapper> {
  // Notification listener removed - implement using proper service when available

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
