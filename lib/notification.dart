import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:revive_eco_tech_app/widgets/notification_card.dart';
import 'package:revive_eco_tech_app/pickup_details_page.dart';

// Constants
const kPrimaryColor = Color(0xFF013D5A);
const kCreamColor = Color(0xFFFCF3E3);

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    _markNotificationsAsRead();
  }

  // MARK AS READ
  Future<void> _markNotificationsAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final snapshots = await FirebaseFirestore.instance
        .collection("notifications")
        .doc(user.uid)
        .collection("userNotifications")
        .where('read', isEqualTo: false)
        .get();

    if (snapshots.docs.isEmpty) return;

    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // ✅ NEW: CLEAR ALL NOTIFICATIONS
  Future<void> _clearAllNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show Confirmation Dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All?"),
        content: const Text("This will permanently delete all your notifications."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Execute Batch Delete
    final collection = FirebaseFirestore.instance
        .collection("notifications")
        .doc(user.uid)
        .collection("userNotifications");

    final snapshots = await collection.get();

    // Firestore batch limit is 500, we loop just in case
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
      count++;
      if (count >= 400) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        count = 0;
      }
    }
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All notifications cleared"), backgroundColor: kPrimaryColor),
      );
    }
  }

  // ✅ NEW: DELETE SINGLE NOTIFICATION
  Future<void> _deleteNotification(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(user.uid)
        .collection("userNotifications")
        .doc(docId)
        .delete();
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final String? pickupId = data['pickupId'];
    if (pickupId != null && pickupId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PickupDetailsPage(pickupId: pickupId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("System Notification"), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kCreamColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          centerTitle: true,
          toolbarHeight: 70,
          title: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Notifications',
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
          // ✅ ADDED: Clear All Button
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 12),
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: kCreamColor),
                tooltip: "Clear All",
                onPressed: _clearAllNotifications,
              ),
            )
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Please log in to view notifications."))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .doc(user.uid)
            .collection("userNotifications")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No notifications yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 8),
                  Text("We'll let you know when updates arrive.", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;

              Timestamp t = data['timestamp'] is Timestamp ? data['timestamp'] : Timestamp.now();
              DateTime dt = t.toDate();
              // DateFormat handles local time conversion automatically
              String formattedDate = DateFormat('MMM d').format(dt);
              String formattedTime = DateFormat('jm').format(dt);
              bool isRead = data['read'] ?? true;

              // ✅ WRAPPED IN DISMISSIBLE FOR SWIPE-TO-DELETE
              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                ),
                onDismissed: (direction) {
                  _deleteNotification(doc.id);
                  // Do NOT use setState here; StreamBuilder handles the UI update automatically
                },
                child: NotificationCard(
                  date: formattedDate,
                  time: formattedTime,
                  title: data["title"] ?? "Update",
                  description: data["description"] ?? "No Description",
                  isNew: !isRead,
                  onTap: () => _handleNotificationTap(data),
                ),
              );
            },
          );
        },
      ),
    );
  }
}