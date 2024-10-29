import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager extends CacheManager {
  static const key = 'customCacheKey';

  // Singleton instance of MyCustomCacheManager
  static final CustomCacheManager _instance = CustomCacheManager._internal();

  factory CustomCacheManager() {
    return _instance;
  }

  CustomCacheManager._internal()
      : super(
          Config(
            key,
            stalePeriod: Duration(days: 10), // Duration before cache is refreshed
            maxNrOfCacheObjects: 100, // Max number of objects in the cache
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );
}
