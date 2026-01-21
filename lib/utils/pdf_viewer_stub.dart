import 'package:flutter/material.dart';

// Stub implementation for non-web platforms
void registerPdfViewFactory(String viewId, String fileUrl) {
  // No-op on non-web platforms
}

Widget buildWebPdfViewer(String fileUrl) {
  return const Center(child: Text('PDF viewer not supported on this platform'));
}
