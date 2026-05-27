// lib/widgets/pickup_tracker.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../pickup_details_page.dart';

// Constants
const kPrimaryColor = Color(0xFF013856);
const kAccentColor = Color(0xFFa7cd47);

class PickupTracker extends StatelessWidget {
  final int currentStep;
  final DateTime? pickupDate;
  final bool showUpcomingTag;
  final String? pickupId;

  const PickupTracker({
    super.key,
    required this.currentStep,
    this.pickupDate,
    this.showUpcomingTag = false,
    this.pickupId,
  });

  static const List<IconData> _stepIcons = [
    Icons.inventory_2_outlined,
    Icons.thumb_up_alt_outlined,
    Icons.local_shipping_outlined,
    Icons.check_circle_outline,
  ];

  static const List<String> _stepLabels = [
    "Pending",
    "Confirmed",
    "Out for\nPickup",
    "Completed",
  ];

  @override
  Widget build(BuildContext context) {
    final String formattedDate = pickupDate != null
        ? DateFormat('MMMM d, yyyy').format(pickupDate!)
        : 'Date TBD';

    return GestureDetector(
      onTap: () {
        if (pickupId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PickupDetailsPage(pickupId: pickupId!),
            ),
          );
        }
      },
      child: Stack(
        children: [
          // Main Card Content
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20), // More rounded
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), // Softer, deeper shadow
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date Row
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_month,
                            color: kPrimaryColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Scheduled Pickup",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Steps Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align tops
                  children: [
                    for (var i = 0; i < _stepLabels.length; i++) ...[
                      if (i > 0) _buildConnector(isActive: i < currentStep),
                      _buildStep(
                        context: context,
                        icon: _stepIcons[i],
                        label: _stepLabels[i],
                        isActive: (i + 1) == currentStep,
                        isCompleted: (i + 1) < currentStep,
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),

          // Upcoming Tag
          if (showUpcomingTag)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: kAccentColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.bolt, size: 14, color: kPrimaryColor),
                    SizedBox(width: 4),
                    Text(
                      "UPCOMING",
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
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

  Widget _buildConnector({required bool isActive}) {
    return Expanded(
      child: Container(
        // Push down to align with circle center (approx 44/2 - height/2)
        margin: const EdgeInsets.only(top: 20),
        height: 3,
        color: isActive ? kAccentColor : const Color(0xFFEEEEEE),
      ),
    );
  }

  Widget _buildStep({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    final bool isDoneOrActive = isActive || isCompleted;

    // Circle Color Logic
    final Color borderColor = isDoneOrActive ? kAccentColor : Colors.grey.shade300;
    final Color fillColor = isActive ? kAccentColor.withOpacity(0.15) : (isCompleted ? kAccentColor : Colors.transparent);
    final Color iconColor = isCompleted ? Colors.white : (isActive ? kPrimaryColor : Colors.grey.shade400);

    // Text Style Logic
    final TextStyle textStyle = TextStyle(
      fontSize: 11,
      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
      color: isActive ? kPrimaryColor : Colors.grey.shade500,
      height: 1.2,
    );

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: isCompleted ? 0 : 2),
            color: fillColor,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}