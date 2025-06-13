import 'package:flutter/material.dart';
import '../t_stops.dart';

// Remove TrainStop class from here if it's already in t_stops.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      } else if (value == 'Green B') {
        currentStops = greenBStops;
      }
      // ADD MORE LINES LUCAS
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
                                title: Text(trainstop.name),
                                content: const Text('connect with backend to display real time info'),
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
                              color: const Color.fromARGB(204, 0, 149, 0),
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