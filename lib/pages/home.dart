import 'package:flutter/material.dart';
import '../t_stops.dart';

// Remove TrainStop class from here if it's already in t_stops.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color lineColor = const Color.fromARGB(204, 0, 149, 0);
  String selectedLine = 'Green E';
  late List<TrainStop> currentStops;

  @override
  void initState() {
    super.initState();
    currentStops = greenEStops;
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
      } else if (value == 'Red Ashmont') {
        currentStops = redLineAshmontStops;
        lineColor = const Color.fromARGB(204, 255, 0, 0);
      } else if (value == 'Red Braintree') {
        currentStops = redLineBraintreeStops;
        lineColor = const Color.fromARGB(204, 255, 0, 0);
      }
      // ADD MORE LINES AS BUILDING
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            // Dropdown to select line
            DropdownButton<String>(
              value: selectedLine,
              items: const [
                DropdownMenuItem(value: 'Green E', child: Text('Green Line - E Branch')),
                DropdownMenuItem(value: 'Green B', child: Text('Green Line - B Branch')),
                DropdownMenuItem(value: 'Red Ashmont', child: Text('Red Line - Ashmont Branch')),
                DropdownMenuItem(value: 'Red Braintree', child: Text('Red Line - Braintree Branch')),
              ],
              onChanged: _onLineChanged,
            ),
            SizedBox(height: 20),
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
                                    style: TextStyle(
                                      fontSize: 20, 
                                      fontWeight: FontWeight.bold,
                                      
                                      ),
                                    ),
                                  ),
                                
                                content: Column(
                                  children: [
                                    SizedBox(height: 16),
                                    const Text('Next Trains:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const Text('Medford Tufts: 5 min'),
                                    const Text('Heath Street: 3 min'),
                                    SizedBox(height: 16),
                                    const Text('Alerts:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const Text('No current alerts'),
                                  ],
                                ),
                                
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
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
                  const SizedBox(height: 15),
                  Text(trainstop.name, style: const TextStyle(fontSize: 16)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}

// comments