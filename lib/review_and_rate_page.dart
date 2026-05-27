import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Constants
const kPrimaryColor = Color(0xFF013D5A);
const kCreamColor = Color(0xFFFCF3E3);
const kAccentColor = Color(0xFFA6CB4E);

class ReviewAndRatePage extends StatefulWidget {
  const ReviewAndRatePage({super.key});

  @override
  State<ReviewAndRatePage> createState() => _ReviewAndRatePageState();
}

class _ReviewAndRatePageState extends State<ReviewAndRatePage> {
  double _rating = 5.0; // Start with 5 stars for positive bias
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  // Dynamic feedback based on rating
  String get _ratingLabel {
    if (_rating >= 5) return "Excellent! 😍";
    if (_rating >= 4) return "Good 😊";
    if (_rating >= 3) return "Average 😐";
    if (_rating >= 2) return "Poor 😞";
    return "Terrible 😡";
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reviewData = {
        'userId': user.uid,
        'userName': user.displayName ?? "Anonymous",
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0', // Useful for tracking analytics
      };

      await FirebaseFirestore.instance.collection('reviews').add(reviewData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thank you for your feedback!"),
            backgroundColor: kPrimaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Auto-close page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      // ✅ CEVUS: Consistent Curved AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          centerTitle: true,
          toolbarHeight: 70,
          title: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Review & Rate",
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          children: [
            // 🖼 Image Placeholder or Asset
            // Using a Container/Icon fallback in case asset is missing, but kept your asset line
            Container(
              height: 180,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/review.png'), // Ensure this exists
                  fit: BoxFit.contain,
                ),
                // Fallback icon if image fails to load or during dev
                color: Colors.transparent,
              ),
              child: Image.asset('assets/images/review.png',
                errorBuilder: (c, o, s) => const Icon(Icons.rate_review_rounded, size: 100, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              _ratingLabel, // ✅ Dynamic Label
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: kPrimaryColor,
                fontFamily: 'RedHatDisplay',
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Your opinion matters to us!',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 25),

            // ⭐ Rating Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Colors.amber),
                onRatingUpdate: (rating) => setState(() => _rating = rating),
                glow: false,
              ),
            ),

            const SizedBox(height: 30),

            // 📝 Comment Box
            TextField(
              controller: _commentController,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Tell us more about your experience...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
              ),
            ),

            const SizedBox(height: 40),

            // ✅ Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  foregroundColor: kPrimaryColor,
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: kPrimaryColor))
                    : const Text(
                  "Submit Review",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}