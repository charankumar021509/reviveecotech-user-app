import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'schedule_pickup.dart'; // IMPORT SchedulePickup

// Constants from your theme
const kPrimaryColor = Color(0xFF013D5A);
const kCreamColor = Color(0xFFFCF3E3);
const kAccentColor = Color(0xFFA6CB4E);

class PickupDetailsPage extends StatefulWidget {
  final String pickupId;

  const PickupDetailsPage({super.key, required this.pickupId});

  @override
  State<PickupDetailsPage> createState() => _PickupDetailsPageState();
}

class _PickupDetailsPageState extends State<PickupDetailsPage> {
  bool _isCancelling = false;

  // Function to show confirmation before cancelling
  Future<void> _confirmCancellation(BuildContext context, DocumentReference pickupRef) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cancel Pickup?', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to cancel this pickup request? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('No, Keep it', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
              ),
              child: const Text('Yes, Cancel'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _cancelPickup(pickupRef);
    }
  }

  // Function to update status to Cancelled
  Future<void> _cancelPickup(DocumentReference pickupRef) async {
    setState(() => _isCancelling = true);
    try {
     await pickupRef.update({
  'status': 'Cancelled',
  'cancelledBy': 'user',
  'cancelledAt': FieldValue.serverTimestamp(),
  'cancellationReason': 'User cancelled the pickup',
});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pickup cancelled successfully'),
            backgroundColor: kPrimaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
        Navigator.pop(context); // Go back after cancellation
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel pickup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  // Helper to map status string to tracker step integer
  

  // Helper to check if editing is allowed (before cutoff time)
  bool _canEditPickup(DateTime? pickupDate, String? timeSlot) {
    if (pickupDate == null || timeSlot == null) return false;

    // Define the cutoff duration (e.g., 24 hours before)
    const Duration cutoffDuration = Duration(hours: 24);

    int startHour = 0;
    try {
      final timeOnly = timeSlot.split(' ')[0]; // Get "09:00" from "09:00AM"
      final hourMinute = timeOnly.split(':');
      startHour = int.parse(hourMinute[0]);
      // Handle PM
      if (timeSlot.toLowerCase().contains('pm') && startHour != 12) {
        startHour += 12;
      }
      // Handle 12 AM
      if (timeSlot.toLowerCase().contains('am') && startHour == 12) {
        startHour = 0;
      }
    } catch (e) {
      return false;
    }

    DateTime pickupStartTime;
    try {
      pickupStartTime = DateTime(pickupDate.year, pickupDate.month, pickupDate.day, startHour);
    } catch (e) {
      return false;
    }

    final DateTime cutoffTime = pickupStartTime.subtract(cutoffDuration);
    return DateTime.now().isBefore(cutoffTime);
  }

  // ✅ CEVUS Helper: Standard Section Builder
  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kCreamColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: kPrimaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final pickupRef = FirebaseFirestore.instance.collection('pickups').doc(widget.pickupId);

    return Scaffold(
      backgroundColor: kCreamColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Pickup Details',
          style: TextStyle(
            fontFamily: 'RedHatDisplay',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.0,
            color: kCreamColor,
          ),
        ),
        backgroundColor: kPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // ✅ CEVUS: Premium Curve
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: pickupRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading pickup details.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Pickup not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final addressDetails = data['addressDetails'] as Map<String, dynamic>? ?? {};
          final pickupDate = (data['pickupDate'] as Timestamp?)?.toDate();
          final timeSlot = data['pickupTimeSlot'] as String?;
          final status = data['status'] as String? ?? 'Unknown';

          final bool isEditableStatus = ['Pending', 'Confirmed'].contains(status);
          final bool canEdit = isEditableStatus && _canEditPickup(pickupDate, timeSlot);
          final int estimateVersion =
    (data['estimateVersion'] as num?)?.toInt() ?? 0;

final bool canCancel =
    ['Pending', 'Confirmed', 'Out-for-Pickup'].contains(status) ||
    (status == 'Estimate Sent' && estimateVersion >= 2);

          bool isOverdue = false;
          if (pickupDate != null && ['Pending', 'Confirmed', 'Out-for-Pickup'].contains(status)) {
            final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
            final pickupDay = DateTime(pickupDate.year, pickupDate.month, pickupDate.day);
            isOverdue = pickupDay.isBefore(today);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // --- Overdue Alert ---
                if(isOverdue)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                        const SizedBox(width: 10),
                        const Text('Pickup is Overdue', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                // --- Cancelled Alert ---
                if (status == 'Cancelled')
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.grey),
                        const SizedBox(width: 10),
                        Text('This pickup was cancelled.', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                // --- Pickup Status ---
_buildSection(
  title: "Pickup Status",
  icon: Icons.info_outline,
  child: Container(
    width: double.infinity,

    padding: const EdgeInsets.all(18),

    decoration: BoxDecoration(
      color: kCreamColor,

      borderRadius:
          BorderRadius.circular(16),
    ),

    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(
          status,

          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,

            color:
                status == 'Completed'
                    ? Colors.green
                    : status ==
                            'Cancelled'
                        ? Colors.red
                        : kPrimaryColor,
          ),
        ),

        const SizedBox(height: 8),

     Text(
  status == 'Pending'
      ? 'Waiting for rider confirmation.'
      : status == 'Confirmed'
          ? 'Pickup confirmed successfully.'
          : status == 'Out-for-Pickup'
              ? 'Rider is on the way.'
              : status == 'Estimate Sent'
                  ? 'Estimate sent by rider. Please review.'
                  : status == 'Declined'
                      ? 'Estimate declined. Waiting for rider to send a new estimate.'
                      : status == 'OTP Generated'
                          ? 'Share OTP with rider.'
                          : status == 'Completed'
                              ? 'Pickup completed successfully.'
                              : 'Pickup cancelled.',
  style: TextStyle(
    color: Colors.grey.shade700,
    height: 1.4,
  ),
),

const SizedBox(height: 16),

if ((data['riderName'] ?? '').toString().isNotEmpty)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kAccentColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Assigned Rider",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Name: ${data['riderName'] ?? ''}",
        ),
        if ((data['riderPhone'] ?? '').toString().trim().isNotEmpty) ...[
  const SizedBox(height: 6),
  Text(
    "Contact: ${data['riderPhone']}",
  ),
],
      ],
    ),
  ),
      ],
    ),
  ),
),

                // --- Location & Time ---
                _buildSection(
                  title: "Logistics",
                  icon: Icons.location_on,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address
                      Text(addressDetails['addressType'] ?? 'Address', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        "${addressDetails['line1'] ?? ''}\n${addressDetails['fullAddress'] ?? ''}",
                        style: TextStyle(color: Colors.grey.shade700, height: 1.3),
                      ),

                      const Divider(height: 24),

                      // Date & Time
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Date", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(pickupDate != null ? DateFormat('MMM d, yyyy').format(pickupDate) : 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Time Slot", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(timeSlot ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

               

if (data['estimateSent'] == true)
  _buildSection(
    title: "Pickup Estimate",
    icon: Icons.payments_rounded,
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [

            const Text(
              "Estimated Weight",

              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(
              "${data['finalWeight'] ?? 0} kg",

              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,

                color: kPrimaryColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [

            const Text(
              "Final Price",

              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(
              "₹${data['finalPrice'] ?? 0}",

              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,

                color: kAccentColor,

                fontSize: 18,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        /// ACCEPT / DECLINE
       if (status == 'Estimate Sent' &&
    data['priceApproved'] != true)
          Row(
            children: [

              Expanded(
                child: ElevatedButton(

                  onPressed: () async {

                    final otp =
                        1000 +
                        (DateTime.now()
                                .millisecondsSinceEpoch %
                            9000);

                    await FirebaseFirestore
                        .instance
                        .collection('pickups')
                        .doc(widget.pickupId)
                        .update({

                      'priceApproved':
                          true,

                      'pickupOtp': otp,

                      'status':
                          'OTP Generated',
                    });

                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(

                      const SnackBar(
                        content: Text(
                          'Estimate Accepted',
                        ),
                      ),
                    );
                  },

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        kPrimaryColor,
                  ),

                  child: const Text(
                    "Accept",

                    style: TextStyle(
                      color:
                          Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton(

                  onPressed: () async {

  await FirebaseFirestore.instance
    .collection('pickups')
    .doc(widget.pickupId)
    .update({
  'priceApproved': false,
  'status': 'Declined',
  'declinedStatus': true,
  'estimateSent': false,
  'estimateLocked': false,
});

  ScaffoldMessenger.of(
          context)
      .showSnackBar(

    const SnackBar(
      content: Text(
        'Estimate Declined',
      ),
    ),
  );
},

                  child:
                      const Text(
                          "Decline"),
                ),
              ),
            ],
          ),

        /// OTP CARD
        if (data['priceApproved'] ==
                true &&
            data['pickupOtp'] !=
                null)

          Container(

            margin:
                const EdgeInsets.only(
                    top: 20),

            padding:
                const EdgeInsets.all(
                    20),

            width: double.infinity,

            decoration: BoxDecoration(

              color: kCreamColor,

              borderRadius:
                  BorderRadius.circular(
                      18),

              border: Border.all(
                color: kAccentColor,
              ),
            ),

            child: Column(
              children: [

                const Text(
                  "Share OTP With Rider",

                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,

                    color:
                        kPrimaryColor,
                  ),
                ),

                const SizedBox(
                    height: 12),

                Text(
                  "${data['pickupOtp']}",

                  style:
                      const TextStyle(

                    fontSize: 34,

                    fontWeight:
                        FontWeight.bold,

                    letterSpacing: 5,

                    color:
                        kAccentColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  ),
                // --- Action Buttons (Edit / Cancel) ---
                if (canEdit || canCancel)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        if (canCancel)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isCancelling ? null : () => _confirmCancellation(context, pickupRef),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red.shade200),
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isCancelling
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                                  : const Text("Cancel"),
                            ),
                          ),

                        if (canCancel && canEdit) const SizedBox(width: 15),

                        if (canEdit)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SchedulePickup(pickupId: widget.pickupId)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                              child: const Text("Edit Pickup"),
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}