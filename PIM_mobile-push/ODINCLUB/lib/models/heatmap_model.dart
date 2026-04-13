enum HeatmapZoneId {
  head,
  shoulderLeft,
  shoulderRight,
  hamstringLeft,
  hamstringRight,
  kneeLeft,
  kneeRight,
  ankleLeft,
  ankleRight,
}

class HeatmapZone {
  const HeatmapZone({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final HeatmapZoneId id;
  final double left;
  final double top;
  final double width;
  final double height;
}
