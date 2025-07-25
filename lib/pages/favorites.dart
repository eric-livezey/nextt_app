import 'package:flutter/material.dart';
import 'package:nextt_app/t_stops.dart';
import '../device-storage-services.dart';
import '../stop_sheet.dart';



class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoritesPage> {

  List<String> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final favorites = await FavoritesService.getFavorites();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      //TODO Look into error handling
    }

    _favorites.reversed;
  }

  Color getLineColor(String trainstop) {
    // Determine the line color based on the train stop name
    final splitted = trainstop.split(','); 
    return Color(int.parse(splitted[0]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(176, 255, 255, 255),
      body: Column(
        // PRAISE BE TO THE LORD FOR THIS ALIGNMENT OPTION!!!!!!!!!!!!
        // CrossAxisAlignment.stretch ensures the children of this column
        // take full width so it can be aligned with LTRB with context of the entire screen
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header area (Banner)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Page title
                  const Text(
                    'Favorites',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a1a1a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your favorite train stops',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                ],
              ),
            ),
          ),
          // Scrollable content area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _favorites.isEmpty
                   // if there are no favorites, show this message
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [                           
                            Icon(
                              Icons.favorite_border,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No favorites yet',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Press and hold on a stop to favorite it!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        itemCount: _favorites.length,
                        // call back function to build each item in the list
                        itemBuilder: (context, index) {
                          final trainstop = _favorites[index];                         
                          final stopName = trainstop.split(",")[1];
                          final lineName = trainstop.split(",")[2];
                          final routeId = trainstop.split(",")[3];
                          final stopId = trainstop.split(",")[4];

                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            elevation: 6,
                            color: Colors.white,                         
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // allegedly helps with rounded cornors in hover effect
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 8.0,
                              ),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: getLineColor(trainstop),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.train,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                stopName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1a1a1a),
                                ),
                              ),
                              subtitle: Text(
                                lineName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Color(0xFF666666),
                              ),
                              onTap: () {
                                showBottomSheet(
                                  context: context,
                                  constraints: BoxConstraints.loose(
                                    Size(
                                      MediaQuery.of(context).size.width,
                                      MediaQuery.of(context).size.height / 2.0,
                                    ),
                                  ),
                                  builder: (context) => StopSheet.fromStopId(
                                    stopId,
                                    {routeId},
                                  ),
                                );
                              },
                              onLongPress: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Center(child: const Text('Remove Favorite')),
                                    content: const Text('Are you sure you want to remove this favorite?'),
                                    actionsAlignment: MainAxisAlignment.center,
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context); // Close dialog first
                                          await FavoritesService.removeFavorite(trainstop);
                                          await loadFavorites(); // Reload the list
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Removed $stopName from favorites!'),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Remove',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// comments 2