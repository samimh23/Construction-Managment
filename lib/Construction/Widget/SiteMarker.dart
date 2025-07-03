import 'package:flutter/material.dart';

import '../Model/Constructionsite/ConstructionSiteModel.dart';

class SiteMarker extends StatelessWidget {
  final ConstructionSite site;
  final bool isZoomedIn;
  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final VoidCallback? onHoverEnter;
  final VoidCallback? onHoverExit;

  const SiteMarker({
    super.key,
    required this.site,
    required this.isZoomedIn,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.onHoverEnter,
    this.onHoverExit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart?.call(),
      onLongPressEnd: (_) => onLongPressEnd?.call(),
      child: MouseRegion(
        onEnter: (_) => onHoverEnter?.call(),
        onExit: (_) => onHoverExit?.call(),
        child: Icon(
          Icons.location_on,
          color: isZoomedIn ? Colors.blue : Colors.red,
          size: 40,
        ),
      ),
    );
  }
}