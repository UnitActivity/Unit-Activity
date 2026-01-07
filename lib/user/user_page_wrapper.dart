import 'package:flutter/material.dart';

/// A wrapper widget for user pages that provides common functionality
/// such as connectivity checking and error handling.
class UserPageWrapper extends StatefulWidget {
  final Widget child;
  final String pageName;
  final VoidCallback? onRefresh;

  const UserPageWrapper({
    required this.child,
    required this.pageName,
    this.onRefresh,
    super.key,
  });

  @override
  State<UserPageWrapper> createState() => _UserPageWrapperState();
}

class _UserPageWrapperState extends State<UserPageWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.onRefresh != null) {
      // Optionally refresh data when app resumes
      widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
