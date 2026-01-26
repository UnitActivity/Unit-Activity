import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:html' as html show IFrameElement;

// Web implementation for PDF viewer
void registerPdfViewFactory(String viewId, String fileUrl) {
  // Add #toolbar=0 to hide PDF viewer toolbar
  final pdfUrl = fileUrl.contains('#')
      ? '$fileUrl&toolbar=0'
      : '$fileUrl#toolbar=0';

  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = pdfUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    return iframe;
  });
}

Widget buildWebPdfViewer(String fileUrl) {
  final viewId = 'pdf-viewer-${fileUrl.hashCode}';
  registerPdfViewFactory(viewId, fileUrl);
  return HtmlElementView(viewType: viewId);
}
