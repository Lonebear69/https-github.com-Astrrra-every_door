import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverlayButtonOptions extends LayerOptions {
  /// Padding for the button.
  final EdgeInsets padding;

  /// To which corner of the map should the button be aligned.
  final Alignment alignment;

  /// Function to call when the button is pressed.
  final VoidCallback onPressed;

  /// Function to call on long tap.
  final VoidCallback? onLongPressed;

  /// Icon to display.
  final IconData icon;

  /// Set to false to hide the button.
  final bool enabled;

  /// Tooltip and semantics message.
  final String? tooltip;

  /// Add safe area to the bottom padding. Enable when the map is full-screen.
  final bool safeBottom;

  /// Add safe area to the right side padding.
  final bool safeRight;

  OverlayButtonOptions({
    Key? key,
    Stream<void>? rebuild,
    this.alignment = Alignment.topRight,
    required this.padding,
    required this.onPressed,
    this.onLongPressed,
    required this.icon,
    this.enabled = true,
    this.tooltip,
    this.safeBottom = false,
    this.safeRight = false,
  }) : super(key: key, rebuild: rebuild);
}

class OverlayButtonPlugin implements MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<void> stream) {
    if (options is OverlayButtonOptions) {
      return OverlayButtonLayer(options);
    }
    throw Exception(
        'Wrong options for TrackButtonPlugin: ${options.runtimeType}');
  }

  @override
  bool supportsLayer(LayerOptions options) => options is OverlayButtonOptions;
}

class OverlayButtonLayer extends ConsumerWidget {
  final OverlayButtonOptions _options;

  const OverlayButtonLayer(this._options);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_options.enabled) return Container();

    final button = GestureDetector(
      onTap: _options.onPressed,
      onLongPress: _options.onLongPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25.0),
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            _options.icon,
            size: 30.0,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
      ),
    );

    EdgeInsets safePadding = MediaQuery.of(context).padding;
    return Positioned(
      bottom: _options.alignment.y > 0
          ? (_options.safeBottom ? safePadding.bottom : 0.0)
          : null,
      top: _options.alignment.y <= 0 ? safePadding.top : null,
      right: _options.alignment.x >= 0
          ? (_options.safeRight ? safePadding.right : 0.0)
          : null,
      left: _options.alignment.x < 0 ? safePadding.left : null,
      child: Padding(
        padding: _options.padding + EdgeInsets.symmetric(horizontal: 10.0),
        child: _options.tooltip == null
            ? button
            : Tooltip(
                message: _options.tooltip,
                child: button,
              ),
      ),
    );
  }
}
