import 'package:flutter/material.dart';
import 'package:revive_eco_tech_app/widgets/campaign_model.dart';
import 'package:intl/intl.dart';
import 'package:revive_eco_tech_app/gallery_viewer_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- Constants ---
const kPrimaryColor = Color(0xFF013856);
const kAccentColor = Color(0xFFa7cd47);
const kCreamColor = Color(0xFFfcf3e2);
const kCreamLight = Color(0xFFfefaef);

class CampaignDetailsPage extends StatelessWidget {
  final Campaign campaign;

  const CampaignDetailsPage({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ FIX 1: Navy Background.
      // When you pull down (top) or pull up (bottom), you see Navy, not white.
      backgroundColor: kPrimaryColor,
      body: Container(
        // Ensure the main content area usually looks Cream
        color: kPrimaryColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- 1. Curvy Hero App Bar ---
            SliverAppBar(
              expandedHeight: 340, // Taller for better visual
              pinned: true,
              stretch: true, // ✅ Allows image to stretch when pulled down
              backgroundColor: kPrimaryColor,
              elevation: 0,

              // ✅ FIX 2: The Signature Curve
              // This applies to the AppBar in BOTH expanded and collapsed states.
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),

              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kCreamColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground, // Image zooms in when pulled
                  StretchMode.blurBackground,
                ],
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 16),
                title: Text(
                  campaign.title,
                  style: const TextStyle(
                    color: kCreamLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                background: ClipRRect(
                  // Ensure image respects the curve even when zooming
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'campaign_poster_${campaign.id}',
                        child: _buildImage(campaign.posterUrl),
                      ),
                      // Gradient for Text Readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black26, // Status bar area
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.8) // Title area
                            ],
                            stops: const [0.0, 0.3, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- 2. Content Body ---
            SliverToBoxAdapter(
              child: Container(
                // Creates a gap so the curved header casts a shadow/stands out
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: kCreamColor,
                  // ✅ FIX 3: Curvy Bottom
                  // When you scroll to the very bottom, this curve lifts off the Navy background.
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),

                    // --- Date & Location ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _buildInfoChip(
                            Icons.calendar_month_rounded,
                            DateFormat('MMM d, yyyy').format(campaign.date),
                          ),
                          _buildInfoChip(
                            Icons.location_on_rounded,
                            campaign.location,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Description ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "About this Campaign",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            campaign.details,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              height: 1.6,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- Gallery ---
                    if (campaign.imageUrls.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "Gallery",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: campaign.imageUrls.length,
                          itemBuilder: (context, index) {
                            final imageUrl = campaign.imageUrls[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GalleryViewerPage(
                                      imageUrls: campaign.imageUrls,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: imageUrl,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: _buildImage(imageUrl),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),

            // Spacer to show the bottom curve nicely when overscrolling
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  // ✅ FIX 4: Cached Network Image (Disk Caching)
  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        // Shows image immediately if cached
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: kAccentColor,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
        ),
      );
    } else {
      // Local Assets
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.image_not_supported_rounded, color: Colors.grey)),
        ),
      );
    }
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kCreamLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kPrimaryColor, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}