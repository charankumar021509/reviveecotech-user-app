import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:revive_eco_tech_app/widgets/drive_model.dart';
import 'package:revive_eco_tech_app/widgets/drive_card.dart'; // Re-use the card
import 'package:revive_eco_tech_app/drive_details_page.dart';
import 'package:revive_eco_tech_app/society_campaign_page.dart';

// --- Constants ---
const kPrimaryColor = Color(0xFF013856);
const kAccentColor = Color(0xFFa7cd47);
const kCreamColor = Color(0xFFfcf3e2);

class AllDrivesPage extends StatelessWidget {
  const AllDrivesPage({super.key});

  void _goToDriveDetails(BuildContext context, Drive drive) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriveDetailsPage(drive: drive),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      // ✅ 1. CEVUS: Consistent Curved Header
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          centerTitle: true,
          toolbarHeight: 70,
          title: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Upcoming Drives",
              style: TextStyle(
                fontFamily: 'RedHatDisplay',
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1.0,
                color: kCreamColor,
              ),
            ),
          ),
          backgroundColor: kPrimaryColor,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kCreamColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        // Query Firestore for all drives from today onwards
        stream: FirebaseFirestore.instance
            .collection('drives')
            .where('date', isGreaterThanOrEqualTo: Timestamp.now())
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          // --- Loading State ---
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }

          // --- Error State ---
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text("Could not load drives.\n${snapshot.error}", textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final driveDocs = snapshot.data!.docs;

          // --- Empty State ---
          if (driveDocs.isEmpty) {
            return _buildEmptyState(context);
          }

          // --- Data State ---
          final drives = driveDocs.map((doc) => Drive.fromFirestore(doc)).toList();

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
            physics: const BouncingScrollPhysics(),
            // ✅ 2. CEVUS: Responsive Grid Layout
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220, // Cards won't get wider than this
              childAspectRatio: 0.8, // Taller cards for better image display
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: drives.length,
            itemBuilder: (context, index) {
              final drive = drives[index];
              return DriveCard(
                drive: drive,
                onTap: () => _goToDriveDetails(context, drive),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ 3. CEVUS: Polished Empty State with CTA
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: const Icon(Icons.event_busy_rounded, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Upcoming Drives",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
                fontFamily: 'RedHatDisplay',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Check back soon for events in your area, or take the initiative!",
              style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Call To Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.volunteer_activism, color: kPrimaryColor),
                label: const Text(
                  "Start a Society Campaign",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SocietyCampaignPage()),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}