import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ==== Constants ====
const kPrimaryColor = Color(0xFF013D5A);
const kAccentColor = Color(0xFFA6CB4E);
const kCreamColor = Color(0xFFFCF3E3);

class CompletedPickupCard extends StatelessWidget {
  final DocumentSnapshot pickupDoc;

  const CompletedPickupCard({super.key, required this.pickupDoc});

  // ✅ Helper to pick image based on scrap type
  String _getScrapImage(List<dynamic> items) {
    if (items.isEmpty) return 'assets/images/home/scraps/bottle.png'; // Default

    final String firstItem = items.first.toString().toLowerCase();

    if (firstItem.contains('paper') || firstItem.contains('book')) return 'assets/images/home/scraps/newspaper.jpg';
    if (firstItem.contains('metal') || firstItem.contains('iron')) return 'assets/images/home/scraps/metal.png';
    if (firstItem.contains('electronic') || firstItem.contains('e-waste')) return 'assets/images/home/scraps/ewaste.jpg';
    if (firstItem.contains('plastic')) return 'assets/images/home/scraps/bottle.png';

    return 'assets/images/home/scraps/bottle.png';
  }

  @override
  Widget build(BuildContext context) {
    final data = pickupDoc.data() as Map<String, dynamic>;

    // Data Extraction
    final String status = data['status'] as String? ?? 'Completed';
    final DateTime? pickupDate = (data['pickupDate'] as Timestamp?)?.toDate();
    final String timeSlot = data['pickupTimeSlot'] as String? ?? '';
   final double amount =
    double.tryParse(
      data['finalPrice']
          .toString(),
    ) ?? 0.0;
    final List<dynamic> itemsList = data['scrapCategories'] ?? data['scrapTypes'] ?? [];
    final String itemsString = itemsList.join(', ');
    final String orderId = pickupDoc.id.substring(0, 6).toUpperCase();

    // Formatters
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final String dateString = pickupDate != null
        ? DateFormat('d MMM yyyy').format(pickupDate)
        : 'Date N/A';

    final bool isCancelled = status == 'Cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.red.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCancelled ? Border.all(color: Colors.red.withOpacity(0.1)) : null,
        boxShadow: [
          if (!isCancelled)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ✅ 1. Leading Image (Restored to Filled/Cover Style)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                _getScrapImage(itemsList),
                width: 70, // Restored size
                height: 70,
                fit: BoxFit.cover, // ✅ Fills the square perfectly
                errorBuilder: (c, o, s) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, color: Colors.grey)
                ),
              ),
            ),

            const SizedBox(width: 14),

            // ✅ 2. Main Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dateString,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isCancelled ? Colors.grey[700] : kPrimaryColor,
                        ),
                      ),
                      if (timeSlot.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text("•", style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(width: 6),
                        Text(
                          timeSlot.split('-')[0].trim(),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  if (itemsString.isNotEmpty)
                    Text(
                      itemsString,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 4),
                  Text(
                    'ID: #$orderId',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),

            // ✅ 3. Trailing Status / Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isCancelled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Cancelled',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: kAccentColor,
                          fontFamily: 'RedHatDisplay',
                        ),
                      ),
                      const Text(
                        "Earned",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}