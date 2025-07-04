import 'package:flutter/material.dart';
import '../t_stops.dart';
import '../device-storage-services.dart'; // Import t_stops.dart to access train stops

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
    if (allGreenStops.any((stop) => stop.name == trainstop)) {
      return const Color.fromARGB(204, 0, 149, 0);
    } else if (orangeStops.any((stop) => stop.name == trainstop)) {
      return const Color.fromARGB(204, 255, 153, 0);
    } else if (blueStops.any((stop) => stop.name == trainstop)) {
      return const Color.fromARGB(204, 0, 0, 255);
    } else if (redLineAshmontStops.any((stop) => stop.name == trainstop) || redLineBraintreeStops.any((stop) => stop.name == trainstop)) {
      return const Color.fromARGB(204, 255, 0, 0);
    }
    return const Color.fromARGB(204, 166, 166, 166);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),          
            SizedBox(height: 20),
            // Map function to build train stop widgets
            ..._favorites.map((trainstop) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    // Wrapped InkWell with Material to provide ripple effect
                    child: InkWell(
                      onTap: () {
                        // Extra train stop info pop up
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
                                    trainstop,
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
                                            Navigator.pop(context); // closes the dialog
                                          },
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
                      customBorder: const CircleBorder(),
                      hoverColor: const Color.fromRGBO(0, 0, 0, 0.3),
                      child: Column(
                        children: [
                          Ink(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: getLineColor(trainstop),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.train, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(trainstop, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }
}

// comments 1