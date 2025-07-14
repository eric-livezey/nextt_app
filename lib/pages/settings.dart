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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header area (match Favorites/Home)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a1a1a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'App settings',
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Default line dropdown
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a default line:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 320,
                          child: DropdownButtonFormField<String>(
                            value: currentDefaultLine,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Clear favorites button
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.delete),
                      label: Text('Clear Favorites'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red[400],
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        FavoritesService.clearFavorites().then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Favorites cleared')),
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]
      )
    );
 }
}

// comments 1