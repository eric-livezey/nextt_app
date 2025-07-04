import 'package:flutter/material.dart';
import '../t_stops.dart';
import '../device-storage-services.dart'; // Import t_stops.dart to access train stops

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Color lineColor = const Color.fromARGB(204, 255, 0, 0);
  late String selectedLine = 'Red Ashmont';
  late List<TrainStop> currentStops = redLineAshmontStops;

  @override
  void initState() {
    super.initState();
    otherDeviceStorage.getDefaultLine().then((defaultLine) {
      if (defaultLine != null) {
        _onLineChanged(defaultLine);
      } else {
        _onLineChanged(selectedLine);
      }
    });
  }

  void _onLineChanged(String? value) {
    if (value == null) return;
    setState(() {
      selectedLine = value;
      if (value == 'Green E') {
        currentStops = greenEStops;
        lineColor = const Color.fromARGB(204, 0, 149, 0);
      } else if (value == 'Green B') {
        lineColor = const Color.fromARGB(204, 0, 149, 0);
        currentStops = greenBStops;
      } else if (value == 'Green C') {
        currentStops = greenCStops;
        lineColor = const Color.fromARGB(204, 0, 149, 0);
      } else if (value == 'Green D') {
        currentStops = greenDStops;
        lineColor = const Color.fromARGB(204, 0, 149, 0);
      } else if (value == 'Orange') {
        currentStops = orangeStops;
        lineColor = const Color.fromARGB(204, 255, 153, 0);
      } else if (value == 'Blue') {
        currentStops = blueStops;
        lineColor = const Color.fromARGB(204, 0, 0, 255);
      } else if (value == 'Red Ashmont') {
        currentStops = redLineAshmontStops;
        lineColor = const Color.fromARGB(204, 255, 0, 0);
      } else if (value == 'Red Braintree') {
        currentStops = redLineBraintreeStops;
        lineColor = const Color.fromARGB(204, 255, 0, 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(176, 255, 255, 255), // Set main background to white
      body: Column(
        children: [
          // Header area (Dropdown for line selection)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[50]!,
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App title
                    const Text(
                      'NextT',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a1a1a),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Dropdown subtitle
                    const Text(
                      'Choose your line',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                     const SizedBox(height: 10),
                    // Dropdown container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: lineColor.withValues(alpha: .3),
                          width: 2,
                        ),
                        
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          children: [
                            // Line color indicator
                            Container(
                              width: 4,
                              height: 32,
                              decoration: BoxDecoration(
                                color: lineColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Dropdown
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedLine,
                                isExpanded: true,
                                // remove underline
                                underline: const SizedBox(),
                                dropdownColor: Colors.white,
                                style: const TextStyle(
                                  color: Color(0xFF1a1a1a),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                icon: Icon(
                                  Icons.expand_more,
                                  color: lineColor,
                                  size: 24,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Red Ashmont', child: Text('Red Line - Ashmont Branch')),
                                  DropdownMenuItem(value: 'Red Braintree', child: Text('Red Line - Braintree Branch')),
                                  DropdownMenuItem(value: 'Orange', child: Text('Orange Line')),
                                  DropdownMenuItem(value: 'Blue', child: Text('Blue Line')),
                                  DropdownMenuItem(value: 'Green B', child: Text('Green Line - B Branch')),
                                  DropdownMenuItem(value: 'Green C', child: Text('Green Line - C Branch')),
                                  DropdownMenuItem(value: 'Green D', child: Text('Green Line - D Branch')),
                                  DropdownMenuItem(value: 'Green E', child: Text('Green Line - E Branch')),
                                ],
                                onChanged: _onLineChanged,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  // Map function to build train stop widgets
                  ...currentStops.map((trainstop) => Padding(
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
                                          trainstop.name,
                                          style: const TextStyle(
                                            fontSize: 20, 
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      content: Column(
                                        children: [
                                          const SizedBox(height: 16),
                                          // API BACK END CONNECTION BELONGS HERE
                                          const Text('Next Trains:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          const Text('Medford Tufts: 5 min'),
                                          const Text('Heath Street: 3 min'),
                                          const SizedBox(height: 16),
                                          const Text('Alerts:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          const Text('No current alerts'),
                                        ],
                                      ),
                                      actions: [
                                        Center(
                                          child: Column(
                                            children: [
                                              TextButton(
                                                onPressed: () => FavoritesService.addFavorite(trainstop.name), // TODO FIGURE OUT HOW TO GIVE FEEDBACK IT WAS ADDED
                                                child: const Text('Favorite'),
                                              ),
                                              const SizedBox(height: 5),
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
                                    color: lineColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.train, color: Colors.white),
                                ),                
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(trainstop.name, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// comments 1