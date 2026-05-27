import 'package:cloud_firestore/cloud_firestore.dart';

class Campaign {
  final String id;
  final String title;
  final String location;
  final DateTime date;
  final String details;
  final String posterUrl; // The main cover image
  final List<String> imageUrls; // Gallery images

  Campaign({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.details,
    required this.posterUrl,
    required this.imageUrls,
  });

  // Factory to create a Campaign from a Firestore document
  factory Campaign.fromFirestore(DocumentSnapshot doc) {
    // Robust casting
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Campaign(
      id: doc.id,
      title: data['title'] ?? 'Untitled Campaign',
      location: data['location'] ?? 'Location TBD',
      // Safe Timestamp handling
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      details: data['details'] ?? 'More details to come.',
      posterUrl: data['posterUrl'] ?? 'assets/images/home/drives/recycle.jpeg',
      // ✅ CEVUS FIX: Crash-proof list parsing
      imageUrls: (data['imageUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }

  // ✅ ADDED: Standard 'toJson' for debugging or future uploads
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'location': location,
      'date': Timestamp.fromDate(date),
      'details': details,
      'posterUrl': posterUrl,
      'imageUrls': imageUrls,
    };
  }
}