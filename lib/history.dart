import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:revive_eco_tech_app/widgets/completed_pickup_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pickup_details_page.dart';

// ==== Constants ====
const kPrimaryColor = Color(0xFF013856);
const kCreamColor = Color(0xFFfcf3e2);
const kAccentColor = Color(0xFFa7cd47);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Filter State: 'All', 'Completed', 'Cancelled'
  String _selectedFilter = 'All';

  // ✅ Stream of Past Pickups (Completed or Cancelled)
  Stream<QuerySnapshot> _getHistoryStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.empty();

    return FirebaseFirestore.instance
        .collection('pickups')
        .where('userId', isEqualTo: user.uid)
    // We only fetch the "Past" statuses
        .where('status', whereIn: ['Completed', 'Cancelled'])
        .orderBy('pickupDate', descending: true) // Newest past orders first
        .snapshots();
  }

  void _navigateToDetails(String pickupId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickupDetailsPage(pickupId: pickupId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: kCreamColor,
        // ✅ CEVUS: Premium Curvy AppBar
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Pickup History',
            style: TextStyle(
              fontFamily: 'RedHatDisplay',
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.0,
              color: kCreamColor,
            ),
          ),
          backgroundColor: kPrimaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
          ),
        ),

        body: Column(
          children: [
            // ✅ CEVUS: Filter Chips Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Completed'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Cancelled'),
                ],
              ),
            ),

            // ✅ CEVUS: Real-time List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getHistoryStream(),
                builder: (context, snapshot) {
                  // --- Loading ---
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                  }

                  // --- Error ---
                  if (snapshot.hasError) {
                    return Center(child: Text('Something went wrong.\n${snapshot.error}', textAlign: TextAlign.center));
                  }

                  // --- Data Processing ---
                  var docs = snapshot.data?.docs ?? [];

                  // Apply Client-Side Filter
                  if (_selectedFilter != 'All') {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == _selectedFilter;
                    }).toList();
                  }

                  // --- Empty State ---
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: 0.6,
                            child: Image.asset(
                              'assets/images/home/history/completed.png', // Ensure this asset exists
                              width: 150,
                              errorBuilder: (c, o, s) => Icon(Icons.history, size: 80, color: Colors.grey.shade400),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == 'All'
                                ? 'No history found.'
                                : 'No $_selectedFilter pickups.',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }

                  // --- List View ---
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      // Use GestureDetector to make the card clickable
                      return GestureDetector(
                        onTap: () => _navigateToDetails(doc.id),
                        child: CompletedPickupCard(pickupDoc: doc),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Helper for Filter Chips
  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? kAccentColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? kAccentColor : Colors.grey.shade300,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: kAccentColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? kPrimaryColor : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}