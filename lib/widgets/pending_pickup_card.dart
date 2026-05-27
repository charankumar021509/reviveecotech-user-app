import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl

// Constants
const kAccentColor = Color(0xFFa7cd47);
const kPrimaryColor = Color(0xFF013D5A); // Assuming this is your primary color

class PendingPickupCard extends StatelessWidget {
  final DocumentSnapshot pickupDoc;

  const PendingPickupCard({Key? key, required this.pickupDoc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = pickupDoc.data() as Map<String, dynamic>;
    final pickupDate = (data['pickupDate'] as Timestamp?)?.toDate();
    final timeSlot = data['pickupTimeSlot'] as String? ?? '';
    // Reading 'scrapCategories' first for a concise list, falling back to 'scrapTypes'
    final itemsList = (data['scrapCategories'] ?? data['scrapTypes']) as List<dynamic>? ?? [];
    final items = itemsList.join(', ');

    // --- Overdue and Title Logic ---
    int daysDiff = 0; // Difference in days (+ve = future, 0 = today, -ve = past)
    String title = 'Upcoming Pickup';
    bool isOverdue = false;
    // Get today's date at midnight for accurate comparison
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    if (pickupDate != null) {
      // Get pickup date at midnight
      final pickupDay = DateTime(pickupDate.year, pickupDate.month, pickupDate.day);
      daysDiff = pickupDay.difference(today).inDays; // Calculate difference

      if (daysDiff < 0) {
        title = 'Pickup Overdue'; // Set title for overdue
        isOverdue = true;
        daysDiff = daysDiff.abs(); // Use absolute value for "days ago"
      } else if (daysDiff == 0) {
        title = 'Pickup Today'; // Set title for today
      } else {
        title = "Due in $daysDiff day${daysDiff == 1 ? '' : 's'}"; // Set title for future
      }
    } else {
      title = 'Date Not Set'; // Handle case where date might be missing
    }
    // --- End Overdue Logic ---

    final formattedDate = pickupDate != null ? DateFormat('d MMMM yyyy').format(pickupDate) : 'N/A';

    // Placeholder image logic
    String imagePath = 'assets/images/home/scraps/metal.png'; // Default image
    if (itemsList.isNotEmpty) {
      String firstItem = itemsList.first.toString().toLowerCase();
      if (firstItem.contains('paper')) imagePath = 'assets/images/home/scraps/newspaper.jpg';
      else if (firstItem.contains('plastic')) imagePath = 'assets/images/home/scraps/bottle.png';
      else if (firstItem.contains('glass')) imagePath = 'assets/images/home/scraps/bottle.png'; // Add specific icon if available
      else if (firstItem.contains('e-waste')) imagePath = 'assets/images/home/scraps/ewaste.png'; // Add specific icon if available
      // Add more specific conditions based on your assets
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 0), // Keep margin tight for ListView
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // ✅ Add Red Border if Overdue
          side: isOverdue
              ? BorderSide(color: Colors.red.shade700, width: 1.5)
              : BorderSide.none),
      elevation: 3,
      // ✅ Tint Background Red if Overdue
      color: isOverdue ? Colors.red.shade50 : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column( // Keep as Column if you need space below the Row later
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(width: 70, height: 70, color: Colors.grey.shade300, child: Icon(Icons.image_not_supported)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, // Displays "Pickup Overdue", "Pickup Today", or "Due in X days"
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          // ✅ Make Overdue Title Red
                          color: isOverdue ? Colors.red.shade900 : kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(formattedDate, style: TextStyle(color: isOverdue ? Colors.black54 : Colors.black)),
                      if (timeSlot.isNotEmpty) Text(timeSlot, style: TextStyle(color: isOverdue ? Colors.black54 : Colors.black)),
                      if (items.isNotEmpty)
                        Text(
                          items,
                          style: TextStyle(fontSize: 13, color: isOverdue ? Colors.black54 : Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // --- Days Left / Ago / Today Indicator ---
                // ✅ Show "days ago" if Overdue
                if (isOverdue)
                  SizedBox(
                    width: 65, // Slightly wider needed
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 10),
                        Text(
                          "$daysDiff", // Already positive due to .abs()
                          style: TextStyle(
                            fontSize: 26, // Slightly smaller
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800, // Red color
                          ),
                        ),
                        Text("days ago", style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
                      ],
                    ),
                  )
                // ✅ Show "days left" only if > 0 (Future)
                else if (daysDiff > 0)
                  SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 10),
                        Text(
                          "$daysDiff",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: kAccentColor,
                          ),
                        ),
                        const Text("days left", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  )
                // ✅ Show 'Today' Chip if daysDiff is 0 (Today)
                else // This covers the daysDiff == 0 case
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Chip(
                      label: Text('Today', style: TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: Colors.orange.shade700, // Orange for today
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  ),
              ],
            ),
            // Removed the Cancel/Edit buttons Row
          ],
        ),
      ),
    );
  }
}