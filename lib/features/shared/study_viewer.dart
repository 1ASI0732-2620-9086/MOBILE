import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/app_controller.dart';
import '../../core/widgets/max_widgets.dart';
import '../../domain/models.dart';

Future<void> openStudyViewer(BuildContext context, Study study) async {
  try {
    final uri = await AppScope.of(context).studyAccessUrl(study);
    if (!context.mounted) return;
    if (uri.toString().isEmpty) throw const FormatException();
    if (study.isPdf) {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        showResult(context, 'No se encontró una aplicación para abrir el PDF.');
      }
      return;
    }
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => _StudyImageViewer(
        title: study.fileName ?? study.type,
        url: uri.toString(),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      showResult(
        context,
        'No se pudo obtener una URL vigente para este estudio.',
      );
    }
  }
}

class _StudyImageViewer extends StatelessWidget {
  const _StudyImageViewer({required this.title, required this.url});
  final String title;
  final String url;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Abrir externamente',
            onPressed: () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: .5,
        maxScale: 5,
        child: Center(
          child: StudyImage(url: url),
        ),
      ),
    ),
  );
}

/// Admite las referencias históricas embebidas y las URLs HTTP vigentes.
class StudyImage extends StatelessWidget {
  const StudyImage({super.key, required this.url});
  final String url;

  static Widget _error() => const Text(
    'No se pudo mostrar la imagen.',
    style: TextStyle(color: Colors.white),
  );

  @override
  Widget build(BuildContext context) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'data') {
        final data = uri.data!;
        if (!data.mimeType.startsWith('image/')) return _error();
        return Image.memory(data.contentAsBytes(), fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _error());
      }
      return Image.network(url, fit: BoxFit.contain,
        loadingBuilder: (_, child, loading) => loading == null ? child : const CircularProgressIndicator(),
        errorBuilder: (_, _, _) => _error());
    } on FormatException {
      return _error();
    }
  }
}
