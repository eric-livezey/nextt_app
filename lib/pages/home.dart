import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../device-storage-services.dart';
import '../stop_sheet.dart';
import '../t_stops.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Color lineColor = redLineColor;
  late String selectedLine = 'Red Line - Braintree/Ashmont';
  late List<TrainStop> currentStops = redLineStops;

  // Dropdown items
  static List<DropdownMenuItem<String>> dropdownItems = [
    DropdownMenuItem(
      value: 'Red Line - Braintree/Ashmont',
      child: _DropdownItemWithColor(
        text: 'Red Line  Braintree/Ashmont',
        color: redLineColor,
      ),
    ),
    DropdownMenuItem(
      value: 'Mattapan Trolley',
      child: _DropdownItemWithColor(
        text: 'Mattapan Trolley',
        color: redLineColor,
      ),
    ),
    DropdownMenuItem(
      value: 'Orange',
      child: _DropdownItemWithColor(
        text: 'Orange Line',
        color: orangeLineColor,
      ),
    ),
    DropdownMenuItem(
      value: 'Blue',
      child: _DropdownItemWithColor(
        text: 'Blue Line',
        color: blueLineColor,
      ),
    ),
    DropdownMenuItem(
      value: 'Green B',
      child: _DropdownItemWithColor(
        text: 'Green Line - B Branch',
        color: greenLineColor,
      ),
    ),
    DropdownMenuItem(
      value: 'Green C',
      child: _DropdownItemWithColor(
        text: 'Green Line - C Branch',
        color: greenLineColor,
      ),
    ),
    DropdownMenuItem(
      value: 'Green D',
      child: _DropdownItemWithColor(
        text: 'Green Line - D Branch',
        color: greenLineColor,
      ),
    ),
    DropdownMenuItem(
      value: 'Green E',
      child: _DropdownItemWithColor(
        text: 'Green Line - E Branch',
        color: greenLineColor,
      ),
    ),
  ];

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

      // GREEN
      if (value == 'Green B') {
        currentStops = greenBStops;
        lineColor = greenLineColor;
      } else if (value == 'Green C') {
        currentStops = greenCStops;
        lineColor = greenLineColor;
      } else if (value == 'Green D') {
        currentStops = greenDStops;
        lineColor = greenLineColor;
      } else if (value == 'Green E') {
        currentStops = greenEStops;
        lineColor = greenLineColor;
      }
      // ORANGE
      else if (value == 'Orange') {
        currentStops = orangeStops;
        lineColor = orangeLineColor;
      }
      // BLUE
      else if (value == 'Blue') {
        currentStops = blueStops;
        lineColor = blueLineColor;
      }
      // RED
      else if (value == 'Red Line - Braintree/Ashmont') {
        currentStops = redLineStops;
        lineColor = redLineColor;
      } 
      // MATTAPAN TROLLEY
      else if (value == 'Mattapan Trolley') {
        currentStops = mattapanTrolleyStops;
        lineColor = redLineColor;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(176, 255, 255, 255),
      body: Column(
        children: [
          // Header area (Dropdown for line selection)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App title
                  const SizedBox(height: 12),
                  const Text(
                    'NextT',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a1a1a),
                    ),
                  ),
                  const SizedBox(height: 4),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4.0),
                      child: Row(
                        children: [
                          // --- DROP DOWN MENNU ---
                          Expanded(
                            child: DropdownButton2<String>(
                              value: selectedLine,
                              isExpanded: true,
                              // this removes underline by replacing it with an empty undefined box
                              underline: const SizedBox(),
                              style: const TextStyle(
                                color: Color(0xFF1a1a1a),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              iconStyleData: IconStyleData(
                                icon: const Icon(
                                  Icons.expand_more,
                                ),
                                iconSize: 24,
                                iconEnabledColor: lineColor,
                                iconDisabledColor: lineColor,
                              ),

                              dropdownStyleData: DropdownStyleData(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                elevation: 4,
                                offset: const Offset(0, 8),
                              ),
                              items: dropdownItems,
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
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Column(
                children: [
                  // Map function to build train stop widgets
                  ...currentStops.map(
                    (trainstop) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            // Wrapped InkWell with Material to provide ripple effect
                            child: InkWell(
                              onTap: () {
                                // Open StopSheet instead of dialog
                                showBottomSheet(
                                  context: context,
                                  constraints: BoxConstraints.loose(
                                    Size(
                                      MediaQuery.of(context).size.width,
                                      MediaQuery.of(context).size.height / 2.0,
                                    ),
                                  ),
                                  builder: (context) => StopSheet.fromStopId(
                                    trainstop.stopId,
                                    {trainstop.routeId},
                                  ),
                                );
                              },
                              onLongPress: () {
                                FavoritesService.addFavorite(trainstop.name, trainstop.color, selectedLine, trainstop.routeId, trainstop.stopId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${trainstop.name} added to favorites!'),
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
                                    child: const Icon(Icons.train,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(trainstop.name,
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom widget for buiding drop down menu items with colored line indicators
class _DropdownItemWithColor extends StatelessWidget {
  final String text;
  final Color color;

  const _DropdownItemWithColor({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Colored line indicator
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        // Text
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// comments 2