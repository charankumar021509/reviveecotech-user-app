import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:revive_eco_tech_app/widgets/campaign_model.dart';
import 'package:revive_eco_tech_app/campaign_details_page.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ 1. Import Cache Package

// --- Constants ---
const kPrimaryColor = Color(0xFF013856);
const kAccentColor = Color(0xFFa7cd47);
const kCreamColor = Color(0xFFfcf3e2);
const kCreamLight = Color(0xFFfefaef);

class SocietyCampaignPage extends StatefulWidget {
  const SocietyCampaignPage({super.key});

  @override
  State<SocietyCampaignPage> createState() => _SocietyCampaignPageState();
}

class _SocietyCampaignPageState extends State<SocietyCampaignPage> {
  late Future<List<Campaign>> _pastCampaignsFuture;

  @override
  void initState() {
    super.initState();
    _pastCampaignsFuture = _fetchPastCampaigns();
  }

  Future<List<Campaign>> _fetchPastCampaigns() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => Campaign.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching campaigns: $e");
      return [];
    }
  }

  void _showNominationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: kCreamLight,
          title: const Row(
            children: [
              Icon(Icons.volunteer_activism, color: kPrimaryColor),
              SizedBox(width: 12),
              Text("Nominate Society", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Ready to bring recycling to your doorstep?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),
              const Text(
                "Our team is currently finalizing the digital nomination form. In the meantime, we have noted your interest and will reach out soon!",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("GREAT!", style: TextStyle(color: kCreamColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            "Society Campaigns",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 0.5,
              color: kCreamColor,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kCreamColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Hero Image Header ---
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/home/drives/campaign_hero.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: kPrimaryColor,
                      child: const Center(child: Icon(Icons.campaign, color: kCreamColor, size: 80)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, kCreamColor],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. Mission Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Start a Movement",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Partner with us to bring easy and rewarding recycling to your entire housing society! \n\n"
                        "We are a recycling service that collects materials from households, sorts them, and ensures they reach manufacturers for reuse. Our mission is to create a sustainable future through responsible consumption.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
                  ),
                ],
              ),
            ),

            // --- 3. How It Works ---
            _buildSection(
              title: "How It Works",
              child: Column(
                children: [
                  _buildStepItem(Icons.group_add_rounded, "1. Nominate", "Fill out the form to nominate your society. Our team will guide the process."),
                  _buildStepItem(Icons.calendar_month_rounded, "2. Coordinate", "We handle scheduling and provide posters to educate residents."),
                  _buildStepItem(Icons.celebration_rounded, "3. Launch", "We collect the recyclables and ensure your society gets rewarded!"),
                ],
              ),
            ),

            // --- 4. Success Stories ---
            _buildSection(
              title: "Success Stories",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("See the impact we've made together.", style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Campaign>>(
                    future: _pastCampaignsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: kPrimaryColor)));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }
                      return SizedBox(
                        height: 210,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) => _buildCampaignCard(snapshot.data![index]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- 5. Join the Network ---
            _buildSection(
              title: "Join the Network",
              child: Column(
                children: [
                  _buildInfoCard(Icons.business, "For Businesses", "Are you a manufacturer? Partner with us to source high-quality, sorted recyclables."),
                  const SizedBox(height: 12),
                  _buildInfoCard(Icons.eco, "Who Are We?", "We are a passionate team dedicated to making recycling accessible and reducing global waste."),
                ],
              ),
            ),

            // --- 6. Call to Action ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.how_to_reg_rounded, color: kPrimaryColor),
                label: const Text("Nominate Your Society", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 8,
                  shadowColor: kAccentColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _showNominationDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==== UI Helpers ====

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStepItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kCreamLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: kAccentColor, size: 26)
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4)),
          ])),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign) {
    return Container(
      width: 165,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CampaignDetailsPage(campaign: campaign))),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(tag: 'campaign_poster_${campaign.id}', child: _buildSmartImage(campaign.posterUrl)),
              Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87], stops: [0.6, 1.0]))),
              Positioned(
                  bottom: 12,
                  left: 12,
                  right: 40,
                  child: Text(
                      campaign.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis
                  )
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kAccentColor.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: kPrimaryColor, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 2. CEVUS: Updated to use CachedNetworkImage
  Widget _buildSmartImage(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 300), // Smooth fade-in
        placeholder: (context, url) => Container(
          color: Colors.grey[100],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kAccentColor)),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    }
    // Asset image fallback (no caching needed for local assets)
    return Image.asset(path, fit: BoxFit.cover);
  }

  Widget _buildInfoCard(IconData icon, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimaryColor, size: 28),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor)),
            const SizedBox(height: 4),
            Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          ])),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Center(child: Text("Success stories are being uploaded...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
    );
  }
}