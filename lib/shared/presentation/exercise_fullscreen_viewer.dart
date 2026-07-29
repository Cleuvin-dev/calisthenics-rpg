import 'package:flutter/material.dart';

import 'exercise_media_placeholder.dart';

/// Visualização em tela cheia da imagem de um exercício
/// (VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md, tela de execução): pinça,
/// pan e duplo toque para ampliar/reduzir, com transição `Hero` a partir
/// de `ExerciseImageCard`. Empurrada como rota nova (não substitui a
/// atual) para que o cronômetro da série continue rodando por baixo,
/// intacto.
class ExerciseFullscreenViewer extends StatefulWidget {
  const ExerciseFullscreenViewer({
    super.key,
    required this.assetPath,
    required this.namePtBr,
    required this.pattern,
  });

  final String assetPath;
  final String namePtBr;
  final String pattern;

  @override
  State<ExerciseFullscreenViewer> createState() =>
      _ExerciseFullscreenViewerState();
}

class _ExerciseFullscreenViewerState extends State<ExerciseFullscreenViewer> {
  final _transformationController = TransformationController();
  TapDownDetails? _lastDoubleTapDown;

  static const _doubleTapZoomScale = 2.5;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value.getMaxScaleOnAxis() > 1.01) {
      _transformationController.value = Matrix4.identity();
      return;
    }
    final position = _lastDoubleTapDown?.localPosition ?? Offset.zero;
    _transformationController.value = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (_doubleTapZoomScale - 1),
        -position.dy * (_doubleTapZoomScale - 1),
        0,
        1,
      )
      ..scaleByDouble(
        _doubleTapZoomScale,
        _doubleTapZoomScale,
        _doubleTapZoomScale,
        1,
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTapDown: (details) => _lastDoubleTapDown = details,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Hero(
                      tag: widget.assetPath,
                      child: Semantics(
                        label: 'Demonstração de ${widget.namePtBr}, ampliada',
                        image: true,
                        child: Image.asset(
                          widget.assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              ExerciseMediaPlaceholder(
                                pattern: widget.pattern,
                                size: 160,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Semantics(
                button: true,
                label: 'Fechar visualização ampliada',
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
