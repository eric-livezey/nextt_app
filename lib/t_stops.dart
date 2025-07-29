import 'package:flutter/material.dart';

class TrainStop {
  final String name;
  final Color color;
  final String routeId;
  final String stopId;
  TrainStop(this.name, this.color, this.routeId, this.stopId);
}

const Color greenLineColor = Color.fromARGB(204, 0, 149, 0);
const Color orangeLineColor = Color.fromARGB(204, 255, 153, 0);
const Color blueLineColor = Color.fromARGB(204, 0, 0, 255);
const Color redLineColor = Color.fromARGB(204, 255, 0, 0);

final Map<String, TrainStop> _stopLookupMap = () {
  final map = <String, TrainStop>{};
  final allStops = [
    ...greenBStops,
    ...greenCStops,
    ...greenDStops,
    ...greenEStops,
    ...orangeStops,
    ...blueStops,
    ...redLineStops,
    ...mattapanTrolleyStops,
  ];
  
  for (final stop in allStops) {
    map['${stop.stopId}_${stop.routeId}'] = stop;
  }
  return map;
}();

TrainStop? findTrainStopByIds(String stopId, String routeId) {
  return _stopLookupMap['${stopId}_$routeId'];
}

// GREEN B Line stops
final List<TrainStop> greenBStops = [
  TrainStop("Boston College", greenLineColor, "Green-B", "place-lake"),
  TrainStop("South Street", greenLineColor, "Green-B", "place-sougr"),
  TrainStop("Chestnut Hill Avenue", greenLineColor, "Green-B", "place-chill"),
  TrainStop("Chiswick Road", greenLineColor, "Green-B", "place-chswk"),
  TrainStop("Sutherland Road", greenLineColor, "Green-B", "place-sthld"),
  TrainStop("Washington Street", greenLineColor, "Green-B", "place-wascm"),
  TrainStop("Warren Street", greenLineColor, "Green-B", "place-wrnst"),
  TrainStop("Allston Street", greenLineColor, "Green-B", "place-alsgr"),
  TrainStop("Griggs Street", greenLineColor, "Green-B", "place-grigg"),
  TrainStop("Harvard Avenue", greenLineColor, "Green-B", "place-harvd"),
  TrainStop("Packard's Corner", greenLineColor, "Green-B", "place-brico"),
  TrainStop("Babcock Street", greenLineColor, "Green-B", "place-babck"),
  TrainStop("Amory Street", greenLineColor, "Green-B", "place-amory"),
  TrainStop("Boston University Central", greenLineColor, "Green-B", "place-bucen"),
  TrainStop("Boston University East", greenLineColor, "Green-B", "place-buest"),
  TrainStop("Blandford Street", greenLineColor, "Green-B", "place-bland"),
  TrainStop("Kenmore", greenLineColor, "Green-B", "place-kencl"),
  TrainStop("Hynes Convention Center", greenLineColor, "Green-B", "place-hymnl"),
  TrainStop("Copley", greenLineColor, "Green-B", "place-coecl"),
  TrainStop("Arlington", greenLineColor, "Green-B", "place-armnl"),
  TrainStop("Boylston", greenLineColor, "Green-B", "place-boyls"),
  TrainStop("Park Street", greenLineColor, "Green-B", "place-pktrm"),
  TrainStop("Government Center", greenLineColor, "Green-B", "place-gover"),
];

// GREEN C Line Stops
final List<TrainStop> greenCStops = [
  TrainStop("Cleveland Circle", greenLineColor, "Green-C", "place-clmnl"),
  TrainStop("Englewood Avenue", greenLineColor, "Green-C", "place-engav"),
  TrainStop("Dean Road", greenLineColor, "Green-C", "place-denrd"),
  TrainStop("Tappan Street", greenLineColor, "Green-C", "place-tapst"),
  TrainStop("Washington Square", greenLineColor, "Green-C", "place-bcnwa"),
  TrainStop("Fairbanks Street", greenLineColor, "Green-C", "place-fbkst"),
  TrainStop("Summit Avenue", greenLineColor, "Green-C", "place-sumav"),
  TrainStop("Coolidge Corner", greenLineColor, "Green-C", "place-cool"),
  TrainStop("Saint Paul Street", greenLineColor, "Green-C", "place-stpul"),
  TrainStop("Kent Street", greenLineColor, "Green-C", "place-kntst"),
  TrainStop("Hawes Street", greenLineColor, "Green-C", "place-hwsst"),
  TrainStop("Saint Mary's Street", greenLineColor, "Green-C", "place-smary"),
  TrainStop("Kenmore", greenLineColor, "Green-C", "place-kencl"),
  TrainStop("Hynes Convention Center", greenLineColor, "Green-C", "place-hymnl"),
  TrainStop("Copley", greenLineColor, "Green-C", "place-coecl"),
  TrainStop("Arlington", greenLineColor, "Green-C", "place-armnl"),
  TrainStop("Boylston", greenLineColor, "Green-C", "place-boyls"),
  TrainStop("Park Street", greenLineColor, "Green-C", "place-pktrm"),
  TrainStop("Government Center", greenLineColor, "Green-C", "place-gover"),
];

// GREEN D Line Stops
final List<TrainStop> greenDStops = [
  TrainStop("Riverside", greenLineColor, "Green-D", "place-river"),
  TrainStop("Woodland", greenLineColor, "Green-D", "place-woodl"),
  TrainStop("Waban", greenLineColor, "Green-D", "place-waban"),
  TrainStop("Eliot", greenLineColor, "Green-D", "place-eliot"),
  TrainStop("Newton Highlands", greenLineColor, "Green-D", "place-newtn"),
  TrainStop("Newton Centre", greenLineColor, "Green-D", "place-newto"),
  TrainStop("Chestnut Hill", greenLineColor, "Green-D", "place-chhil"),
  TrainStop("Reservoir", greenLineColor, "Green-D", "place-rsmnl"),
  TrainStop("Beaconsfield", greenLineColor, "Green-D", "place-bcnfd"),
  TrainStop("Brookline Hills", greenLineColor, "Green-D", "place-brkhl"),
  TrainStop("Brookline Village", greenLineColor, "Green-D", "place-bvmnl"),
  TrainStop("Longwood", greenLineColor, "Green-D", "place-longw"),
  TrainStop("Fenway", greenLineColor, "Green-D", "place-fenwy"),
  TrainStop("Kenmore", greenLineColor, "Green-D", "place-kencl"),
  TrainStop("Hynes Convention Center", greenLineColor, "Green-D", "place-hymnl"),
  TrainStop("Copley", greenLineColor, "Green-D", "place-coecl"),
  TrainStop("Arlington", greenLineColor, "Green-D", "place-armnl"),
  TrainStop("Boylston", greenLineColor, "Green-D", "place-boyls"),
  TrainStop("Park Street", greenLineColor, "Green-D", "place-pktrm"),
  TrainStop("Government Center", greenLineColor, "Green-D", "place-gover"),
  TrainStop("Haymarket", greenLineColor, "Green-D", "place-haecl"),
  TrainStop("North Station", greenLineColor, "Green-D", "place-north"),
  TrainStop("Science Park/West End", greenLineColor, "Green-D", "place-spmnl"),
  TrainStop("Lechmere", greenLineColor, "Green-D", "place-lech"),
  TrainStop("East Somerville", greenLineColor, "Green-D", "place-esomr"),
  TrainStop("Ball Square", greenLineColor, "Green-D", "place-balsq"),
  TrainStop("Magoun Square", greenLineColor, "Green-D", "place-mgngl"),
  TrainStop("Gilman Square", greenLineColor, "Green-D", "place-gilmn"),
  TrainStop("Medford/Tufts", greenLineColor, "Green-D", "place-mdftf"),
];

// GREEN E Line stops
final List<TrainStop> greenEStops = [
  TrainStop("Heath Street", greenLineColor, "Green-E", "place-hsmnl"),
  TrainStop("Back of the Hill", greenLineColor, "Green-E", "place-bckhl"),
  TrainStop("Riverway", greenLineColor, "Green-E", "place-rvrwy"),
  TrainStop("Mission Park", greenLineColor, "Green-E", "place-mispk"),
  TrainStop("Fenwood Road", greenLineColor, "Green-E", "place-fenwd"),
  TrainStop("Brigham Circle", greenLineColor, "Green-E", "place-brmnl"),
  TrainStop("Longwood Medical Area", greenLineColor, "Green-E", "place-lngmd"),
  TrainStop("Museum of Fine Arts", greenLineColor, "Green-E", "place-mfa"),
  TrainStop("Northeastern University", greenLineColor, "Green-E", "place-nuniv"),
  TrainStop("Symphony", greenLineColor, "Green-E", "place-symcl"),
  TrainStop("Prudential", greenLineColor, "Green-E", "place-prmnl"),
  TrainStop("Copley", greenLineColor, "Green-E", "place-coecl"),
  TrainStop("Arlington", greenLineColor, "Green-E", "place-armnl"),
  TrainStop("Boylston", greenLineColor, "Green-E", "place-boyls"),
  TrainStop("Park Street", greenLineColor, "Green-E", "place-pktrm"),
  TrainStop("Government Center", greenLineColor, "Green-E", "place-gover"),
  TrainStop("Haymarket", greenLineColor, "Green-E", "place-haecl"),
  TrainStop("North Station", greenLineColor, "Green-E", "place-north"),
  TrainStop("Science Park/West End", greenLineColor, "Green-E", "place-spmnl"),
  TrainStop("Lechmere", greenLineColor, "Green-E", "place-lech"),
  TrainStop("East Somerville", greenLineColor, "Green-E", "place-esomr"),
  TrainStop("Union Square", greenLineColor, "Green-E", "place-unsqu"),
];

// Orange Line Stops
final List<TrainStop> orangeStops = [
  TrainStop("Oak Grove", orangeLineColor, "Orange", "place-ogmnl"),
  TrainStop("Malden Center", orangeLineColor, "Orange", "place-mlmnl"),
  TrainStop("Wellington", orangeLineColor, "Orange", "place-welln"),
  TrainStop("Assembly", orangeLineColor, "Orange", "place-astao"),
  TrainStop("Sullivan Square", orangeLineColor, "Orange", "place-sull"),
  TrainStop("Community College", orangeLineColor, "Orange", "place-ccmnl"),
  TrainStop("North Station", orangeLineColor, "Orange", "place-north"),
  TrainStop("Haymarket", orangeLineColor, "Orange", "place-haecl"),
  TrainStop("State", orangeLineColor, "Orange", "place-state"),
  TrainStop("Downtown Crossing", orangeLineColor, "Orange", "place-dwnxg"),
  TrainStop("Chinatown", orangeLineColor, "Orange", "place-chncl"),
  TrainStop("Tufts Medical Center", orangeLineColor, "Orange", "place-tumnl"),
  TrainStop("Back Bay", orangeLineColor, "Orange", "place-bbsta"),
  TrainStop("Massachusetts Avenue", orangeLineColor, "Orange", "place-masta"),
  TrainStop("Ruggles", orangeLineColor, "Orange", "place-rugg"),
  TrainStop("Roxbury Crossing", orangeLineColor, "Orange", "place-rcmnl"),
  TrainStop("Jackson Square", orangeLineColor, "Orange", "place-jaksn"),
  TrainStop("Stony Brook", orangeLineColor, "Orange", "place-sbmnl"),
  TrainStop("Green Street", orangeLineColor, "Orange", "place-grnst"),
  TrainStop("Forest Hills", orangeLineColor, "Orange", "place-forhl"),
];

// Blue Line Stops
final List<TrainStop> blueStops = [
  TrainStop("Bowdoin", blueLineColor, "Blue", "place-bomnl"),
  TrainStop("Government Center", blueLineColor, "Blue", "place-gover"),
  TrainStop("State", blueLineColor, "Blue", "place-state"),
  TrainStop("Aquarium", blueLineColor, "Blue", "place-aqucl"),
  TrainStop("Maverick", blueLineColor, "Blue", "place-mvbcl"),
  TrainStop("Airport", blueLineColor, "Blue", "place-aport"),
  TrainStop("Wood Island", blueLineColor, "Blue", "place-wimnl"),
  TrainStop("Orient Heights", blueLineColor, "Blue", "place-orhte"),
  TrainStop("Suffolk Downs", blueLineColor, "Blue", "place-sdmnl"),
  TrainStop("Beachmont", blueLineColor, "Blue", "place-bmmnl"),
  TrainStop("Revere Beach", blueLineColor, "Blue", "place-rbmnl"),
  TrainStop("Wonderland", blueLineColor, "Blue", "place-wondl"),
];

// RED Line to Braintree (Full Route: Alewife to Braintree)
final List<TrainStop> redLineStops = [
  TrainStop("Alewife", redLineColor, "Red", "place-alfcl"),
  TrainStop("Davis", redLineColor, "Red", "place-davis"),
  TrainStop("Porter", redLineColor, "Red", "place-portr"),
  TrainStop("Harvard", redLineColor, "Red", "place-harsq"),
  TrainStop("Central", redLineColor, "Red", "place-cntsq"),
  TrainStop("Kendall/MIT", redLineColor, "Red", "place-knncl"),
  TrainStop("Charles/MGH", redLineColor, "Red", "place-chmnl"),
  TrainStop("Park Street", redLineColor, "Red", "place-pktrm"),
  TrainStop("Downtown Crossing", redLineColor, "Red", "place-dwnxg"),
  TrainStop("South Station", redLineColor, "Red", "place-sstat"),
  TrainStop("Broadway", redLineColor, "Red", "place-brdwy"),
  TrainStop("Andrew", redLineColor, "Red", "place-andrw"),
  TrainStop("JFK/UMass", redLineColor, "Red", "place-jfk"),
  TrainStop("Savin Hill", redLineColor, "Red", "place-shmnl"),
  TrainStop("Fields Corner", redLineColor, "Red", "place-fldcr"),
  TrainStop("Shawmut", redLineColor, "Red", "place-smmnl"),
  TrainStop("Ashmont", redLineColor, "Red", "place-asmnl"),
  TrainStop("North Quincy", redLineColor, "Red", "place-nqncy"),
  TrainStop("Wollaston", redLineColor, "Red", "place-wlsta"),
  TrainStop("Quincy Center", redLineColor, "Red", "place-qnctr"),
  TrainStop("Quincy Adams", redLineColor, "Red", "place-qamnl"),
  TrainStop("Braintree", redLineColor, "Red", "place-brntn"),
];

// Mattapan Trolley (High Speed Line from Ashmont)
final List<TrainStop> mattapanTrolleyStops = [
  TrainStop("Ashmont", redLineColor, "Mattapan", "place-asmnl"),
  TrainStop("Cedar Grove", redLineColor, "Mattapan", "place-cedgr"),
  TrainStop("Butler", redLineColor, "Mattapan", "place-butlr"),
  TrainStop("Milton", redLineColor, "Mattapan", "place-miltt"),
  TrainStop("Central Avenue", redLineColor, "Mattapan", "place-cenav"),
  TrainStop("Valley Road", redLineColor, "Mattapan", "place-valrd"),
  TrainStop("Capen Street", redLineColor, "Mattapan", "place-capst"),
  TrainStop("Mattapan", redLineColor, "Mattapan", "place-matt"),
];