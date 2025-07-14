import 'package:flutter/material.dart';

class TrainStop {
  final String name;
  final Color color;
  TrainStop(this.name, this.color);
}

const Color greenLineColor = Color.fromARGB(204, 0, 149, 0);
const Color orangeLineColor = Color.fromARGB(204, 255, 153, 0);
const Color blueLineColor = Color.fromARGB(204, 0, 0, 255);
const Color redLineColor = Color.fromARGB(204, 255, 0, 0);

// GREEN B Line stops
final List<TrainStop> greenBStops = [
  TrainStop("Boston College", greenLineColor),
  TrainStop("South Street", greenLineColor),
  TrainStop("Chestnut Hill Avenue", greenLineColor),
  TrainStop("Chiswick Road", greenLineColor),
  TrainStop("Cleveland Circle", greenLineColor),
  TrainStop("Sutherland Road", greenLineColor),
  TrainStop("Washington Street", greenLineColor),
  TrainStop("Warren Street", greenLineColor),
  TrainStop("Allston Street", greenLineColor),
  TrainStop("Griggs Street", greenLineColor),
  TrainStop("Harvard Avenue", greenLineColor),
  TrainStop("Packard's Corner", greenLineColor),
  TrainStop("Babcock Street", greenLineColor),
  TrainStop("Armory Street", greenLineColor),
  TrainStop("Boston University Central", greenLineColor),
  TrainStop("Boston University East", greenLineColor),
  TrainStop("Blandford Street", greenLineColor),
  TrainStop("Kenmore", greenLineColor),
  TrainStop("Hynes Convention Center", greenLineColor),
  TrainStop("Copley", greenLineColor),
  TrainStop("Arlington", greenLineColor),
  TrainStop("Boylston", greenLineColor),
  TrainStop("Park Street", greenLineColor),
  TrainStop("Government Center", greenLineColor),
];

// GREEN C Line Stops
final List<TrainStop> greenCStops = [
  TrainStop("Cleveland Circle", greenLineColor),
  TrainStop("Englewood Avenue", greenLineColor),
  TrainStop("Dean Road", greenLineColor),
  TrainStop("Tappan Street", greenLineColor),
  TrainStop("Washington Square", greenLineColor),
  TrainStop("Fairbanks Street", greenLineColor),
  TrainStop("Summit Avenue", greenLineColor),
  TrainStop("Coolidge Corner", greenLineColor),
  TrainStop("Saint Paul Street", greenLineColor),
  TrainStop("Kent Street", greenLineColor),
  TrainStop("Hawes Street", greenLineColor),
  TrainStop("Saint Mary's Street", greenLineColor),
  TrainStop("Kenmore", greenLineColor),
  TrainStop("Hynes Convention Center", greenLineColor),
  TrainStop("Copley", greenLineColor),
  TrainStop("Arlington", greenLineColor),
  TrainStop("Boylston", greenLineColor),
  TrainStop("Park Street", greenLineColor),
  TrainStop("Government Center", greenLineColor),
];

// GREEN D Line Stops
final List<TrainStop> greenDStops = [
  TrainStop("Riverside", greenLineColor),
  TrainStop("Woodland", greenLineColor),
  TrainStop("Waban", greenLineColor),
  TrainStop("Eliot", greenLineColor),
  TrainStop("Newton Highlands", greenLineColor),
  TrainStop("Newton Centre", greenLineColor),
  TrainStop("Chestnut Hill", greenLineColor),
  TrainStop("Reservoir", greenLineColor),
  TrainStop("Beaconsfield", greenLineColor),
  TrainStop("Brookline Hills", greenLineColor),
  TrainStop("Brookline Village", greenLineColor),
  TrainStop("Longwood", greenLineColor),
  TrainStop("Fenway", greenLineColor),
  TrainStop("Kenmore", greenLineColor),
  TrainStop("Hynes Convention Center", greenLineColor),
  TrainStop("Copley", greenLineColor),
  TrainStop("Arlington", greenLineColor),
  TrainStop("Boylston", greenLineColor),
  TrainStop("Park Street", greenLineColor),
  TrainStop("Government Center", greenLineColor),
  TrainStop("Haymarket", greenLineColor),
  TrainStop("North Station", greenLineColor),
  TrainStop("Science Park/West End", greenLineColor),
  TrainStop("Lechmere", greenLineColor),
  TrainStop("Union Square", greenLineColor),
];

// GREEN E Line stops
final List<TrainStop> greenEStops = [
  TrainStop("Heath Street", greenLineColor),
  TrainStop("Back of the Hill", greenLineColor),
  TrainStop("Riverway", greenLineColor),
  TrainStop("Mission Park", greenLineColor),
  TrainStop("Fenwood Rd", greenLineColor),
  TrainStop("Brigham Circle", greenLineColor),
  TrainStop("Longwood Medical Center", greenLineColor),
  TrainStop("Museum of Fine Arts", greenLineColor),
  TrainStop("Northeastern", greenLineColor),
  TrainStop("Symphony", greenLineColor),
  TrainStop("Prudential", greenLineColor),
  TrainStop("Copley", greenLineColor),
  TrainStop("Arlington", greenLineColor),
  TrainStop("Boylston", greenLineColor),
  TrainStop("Park Street", greenLineColor),
  TrainStop("Government Center", greenLineColor),
  TrainStop("Haymarket", greenLineColor),
  TrainStop("North Station", greenLineColor),
];

// Orange Line Stops
final List<TrainStop> orangeStops = [
  TrainStop("Oak Grove", orangeLineColor),
  TrainStop("Malden Center", orangeLineColor),
  TrainStop("Wellington", orangeLineColor),
  TrainStop("Assembly", orangeLineColor),
  TrainStop("Sullivan Square", orangeLineColor),
  TrainStop("Community College", orangeLineColor),
  TrainStop("North Station", orangeLineColor),
  TrainStop("Haymarket", orangeLineColor),
  TrainStop("State Street", orangeLineColor),
  TrainStop("Downtown Crossing", orangeLineColor),
  TrainStop("Chinatown", orangeLineColor),
  TrainStop("Tufts Medical Center", orangeLineColor),
  TrainStop("Back Bay", orangeLineColor),
  TrainStop("Massachusetts Avenue", orangeLineColor),
  TrainStop("Ruggles", orangeLineColor),
  TrainStop("Roxbury Crossing", orangeLineColor),
  TrainStop("Jackson Square", orangeLineColor),
  TrainStop("Stony Brook", orangeLineColor),
  TrainStop("Green Street", orangeLineColor),
  TrainStop("Forest Hills", orangeLineColor),
];

// Blue Line Stops
final List<TrainStop> blueStops = [
  TrainStop("Bowdoin", blueLineColor),
  TrainStop("Government Center", blueLineColor),
  TrainStop("State", blueLineColor),
  TrainStop("Aquarium", blueLineColor),
  TrainStop("Maverick", blueLineColor),
  TrainStop("Airport", blueLineColor),
  TrainStop("Wood Island", blueLineColor),
  TrainStop("Orient Heights", blueLineColor),
  TrainStop("Suffolk Downs", blueLineColor),
  TrainStop("Beachmont", blueLineColor),
  TrainStop("Revere Beach", blueLineColor),
  TrainStop("Wonderland", blueLineColor),
];

// RED Ashmont stops
final List<TrainStop> redLineAshmontStops = [
  TrainStop("Ashmont", redLineColor),
  TrainStop("Cedar Grove", redLineColor),
  TrainStop("Butler", redLineColor),
  TrainStop("Milton", redLineColor),
  TrainStop("Central Avenue", redLineColor),
  TrainStop("Valley Road", redLineColor),
  TrainStop("Capen Street", redLineColor),
  TrainStop("Mattapan", redLineColor),
];

// RED Braintree stops
final List<TrainStop> redLineBraintreeStops = [
  TrainStop("Alewife", redLineColor),
  TrainStop("Davis", redLineColor),
  TrainStop("Porter", redLineColor),
  TrainStop("Harvard", redLineColor),
  TrainStop("Central", redLineColor),
  TrainStop("Kendall/MIT", redLineColor),
  TrainStop("Charles/MGH", redLineColor),
  TrainStop("Park Street", redLineColor),
  TrainStop("Downtown Crossing", redLineColor),
  TrainStop("South Station", redLineColor),
  TrainStop("Broadway", redLineColor),
  TrainStop("Andrew", redLineColor),
  TrainStop("JFK/UMass", redLineColor),
  TrainStop("North Quincy", redLineColor),
  TrainStop("Wollaston", redLineColor),
  TrainStop("Quincy Center", redLineColor),
  TrainStop("Quincy Adams", redLineColor),
  TrainStop("Braintree", redLineColor),
];