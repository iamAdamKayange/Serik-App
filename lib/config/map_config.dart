enum MapEngine {
  google,
  mapbox,
}

class MapConfig {
  static const MapEngine engine = MapEngine.mapbox;

  static bool get useMapbox => engine == MapEngine.mapbox;
}
