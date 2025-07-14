import 'package:flutter/material.dart';
import 'package:nextt_app/t_stops.dart';
//import '../t_stops.dart';
import '../device-storage-services.dart';

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
                              'Add train stops to your favorites\nfrom the Home page',
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
                                // TRAIN STOP DIALOG BOX
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    child: Container(
                                      // Ideally it's reactive to screen size
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      height: MediaQuery.of(context).size.height * 0.6,
                                      constraints: const BoxConstraints(
                                        maxWidth: 400,
                                        maxHeight: 500,
                                        minWidth: 250,
                                        minHeight: 300,
                                      ),
                                      child: AlertDialog(
                                        title: Center(
                                          child: Text(
                                            trainstop.split(",")[1],
                                            style: TextStyle(
                                              fontSize: 20, 
                                              fontWeight: FontWeight.bold,                                               
                                              ),
                                            ),
                                          ),
                                        
                                        content: Column(
                                          children: [
                                            SizedBox(height: 16),
                                            // API BACK END CONNECTION BELONGS HERE
                                            const Text('Next Trains:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            const Text('Medford Tufts: 5 min'),
                                            const Text('Heath Street: 3 min'),
                                            SizedBox(height: 16),
                                            const Text('Alerts:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            const Text('No current alerts'),
                                          ],
                                        ),
                                        
                                        actions: [
                                          Center(
                                            child: Column(
                                              children: [
                                                TextButton(
                                                  onPressed: () async {
                                                    await FavoritesService.removeFavorite(trainstop);
                                                    await loadFavorites(); // reloads the list and calls setState
                                                    Navigator.pop(context); // closes the dialog box
                                                  },        
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),                                          
                                                  child: const Text('Remove Favorite'),
                                                                
                                                ),
                                                SizedBox(height: 5),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            ),
                                          ),                                          
                                        ],
                                      ),
                                    ),
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