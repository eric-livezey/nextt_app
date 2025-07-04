import 'package:shared_preferences/shared_preferences.dart';


// FEATURES
// 1. Save entire favorites list to persistent storage
// 2. Get favorites from persistent storage
// 3. Add a unique favorite stop to the favorites list
// 4. Remove a favorite stop from the favorites list

class FavoritesService {
  static const String _favoritesKey = 'favorite_stops';
  

  // Save entire favorites list to persistent storage
  static Future<void> saveFavorites(List<String> favorites) async {
    // storageReference is a SharedPreferences instance
    final storageReference = await SharedPreferences.getInstance();
    await storageReference.setStringList(_favoritesKey, favorites);
  }

  // returns a list of favorite stops from persistent storage
  static Future<List<String>> getFavorites() async {
    final storageReference = await SharedPreferences.getInstance();
    List<String> favorites = storageReference.getStringList(_favoritesKey) ?? [];
    return favorites;
  }

  // Add a unique favorite stop to the favorites list
  static Future<void> addFavorite(String stop) async {
    final storageReference = await SharedPreferences.getInstance();
    List<String> favorites = storageReference.getStringList(_favoritesKey) ?? [];
    
    if (!favorites.contains(stop)) {
      favorites.add(stop);
      await storageReference.setStringList(_favoritesKey, favorites);
    }
  }

  // Remove a favorite stop from the favorites list
  static Future<void> removeFavorite(String stop) async {
    final storageReference = await SharedPreferences.getInstance();
    List<String> favorites = storageReference.getStringList(_favoritesKey) ?? [];
    
    if (favorites.contains(stop)) {
      favorites.remove(stop);
      await storageReference.setStringList(_favoritesKey, favorites);
    }
  }

  static Future<void> clearFavorites() async {
    final storageReference = await SharedPreferences.getInstance();
    await storageReference.remove(_favoritesKey);
  }
}

class otherDeviceStorage {
  static const String _defaultLineKey = 'default_line';

  // Save the default line to persistent storage
  static Future<void> saveDefaultLine(String line) async {
    final storageReference = await SharedPreferences.getInstance();
    await storageReference.setString(_defaultLineKey, line);
  }

  // Get the default line from persistent storage
  static Future<String?> getDefaultLine() async {
    final storageReference = await SharedPreferences.getInstance();
    return storageReference.getString(_defaultLineKey);
  }
}