import 'package:nextt_app/t_stops.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';



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
  static Future<void> addFavorite(String stop, Color stopColor, String line, String routeId, String stopId) async {
    final storageReference = await SharedPreferences.getInstance();
    List<String> favorites = storageReference.getStringList(_favoritesKey) ?? [];
    
    String stopWithColor = '${stopColor.toARGB32().toString()},$stop,$line,$routeId,$stopId';

    if (!favorites.contains(stopWithColor)) {
      favorites.add(stopWithColor);
      await storageReference.setStringList(_favoritesKey, favorites);
    }
  }

  // Collect stop info to store a favorite from map
  static Future<bool> addFavoriteFromMap(String stopId, String routeId, String stopName) async {
    // Try to find the corresponding TrainStop
    final trainStop = findTrainStopByIds(stopId, routeId);
    
    if (trainStop != null) {
      await addFavorite(
        trainStop.name,
        trainStop.color,
        trainStop.routeId,
        trainStop.routeId,
        trainStop.stopId,
      );
      return true;
    } else {
      return false;
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

// comments 1