import 'package:flutter/material.dart';

import 'package:nextt_app/device-storage-services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? currentDefaultLine;

  @override
  void initState() {
    super.initState();
    _loadCurrentDefaultLine();
  }

  Future<void> _loadCurrentDefaultLine() async {
    final defaultLine = await otherDeviceStorage.getDefaultLine();
    setState(() {
      currentDefaultLine = defaultLine;
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
                    Center(
                      child: const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a1a1a),
                        ),
                      ),
                    ),
                  ]
                )
              )
            )
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Select a default line on launch', style: TextStyle(fontSize: 16),),
                      const SizedBox(width: 20),
                      DropdownButton<String>(
                        value: currentDefaultLine,
                        hint: Text('Choose a line'),
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
                        onChanged: (String? defaultLine) {
                          if (defaultLine != null) {
                            otherDeviceStorage.saveDefaultLine(defaultLine).then((_) {
                              setState(() {
                                currentDefaultLine = defaultLine;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Default line set to $defaultLine')),
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Clear Favorites', style: TextStyle(fontSize: 16),),
                    //button to clear favorites
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // Clear favorites using FavoritesService
                        FavoritesService.clearFavorites().then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Favorites cleared')),
                          );
                        });
                      },
                    ),
                  ],
                ),


                ]
              )
            )
          ),
        ]
      )
    );
 }
}