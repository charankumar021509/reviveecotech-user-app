import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ 1. Rotating Placeholder Assets
// These are used for the "Coming Soon" cards
final List<String> _placeholderImages = [
  'assets/images/home/drives/plastic.jpeg',
  'assets/images/home/drives/recycle.jpeg',
  // Add more here if needed
];

class Drive {
  final String id;
  final String title;
  final String location;
  final DateTime date;
  final String details;
  final String imageUrl;
  final bool isPlaceholder;

  Drive({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.details,
    required this.imageUrl,
    this.isPlaceholder = false,
  });

  // ✅ 2. CEVUS STANDARD: Robust Factory
  factory Drive.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Drive(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Drive',
      location: data['location'] as String? ?? 'Location TBD',
      // Safe Timestamp handling (Fall back to Now if missing)
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      details: data['details'] as String? ?? 'More details to come.',
      // Fallback image if URL is missing
      imageUrl: data['imageUrl'] as String? ?? 'assets/images/home/drives/recycle.jpeg',
      isPlaceholder: false,
    );
  }

  // ✅ 3. SMART PLACEHOLDER GENERATOR
  // Creates a dummy "Coming Soon" drive for empty slots in the UI
  factory Drive.placeholder({required int uniqueId}) {
    // Rotates through the images list based on the ID so cards look varied
    final imagePath = _placeholderImages[uniqueId % _placeholderImages.length];

    return Drive(
      id: 'placeholder_$uniqueId',
      title: 'Drive Coming Soon!',
      location: 'Your Society Could Be Next!',
      date: DateTime.now().add(const Duration(days: 30)), // Future date
      details: 'We are actively looking for new partners. Check back soon for more details on upcoming drives in your area.',
      imageUrl: imagePath,
      isPlaceholder: true,
    );
  }

  // ✅ 4. ADDED: Standard Serialization
  // Useful for debugging or sending data back to a server
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': Timestamp.fromDate(date),
      'details': details,
      'imageUrl': imageUrl,
      'isPlaceholder': isPlaceholder,
    };
  }
}