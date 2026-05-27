import 'package:flutter/material.dart';
import 'package:revive_eco_tech_app/widgets/drive_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- Constants ---
const kPrimaryColor = Color(0xFF013856);
const kAccentColor = Color(0xFFa7cd47);
const kCreamColor = Color(0xFFfcf3e2);
const kCreamLight = Color(0xFFfefaef);

class DriveDetailsPage extends StatefulWidget {
  final Drive drive;

  const DriveDetailsPage({super.key, required this.drive});

  @override
  State<DriveDetailsPage> createState() => _DriveDetailsPageState();
}

class _DriveDetailsPageState extends State<DriveDetailsPage> {
  // ✅ 1. Scroll Controller to track position
  late ScrollController _scrollController;
  // ✅ 2. Key to find the "About" section
  final GlobalKey _aboutSectionKey = GlobalKey();

  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Logic to show/hide title based on scroll
  void _onScroll() {
    // 260 is roughly where the main body title scrolls off-screen
    if (_scrollController.offset > 260 && !_showAppBarTitle) {
      setState(() => _showAppBarTitle = true);
    } else if (_scrollController.offset <= 260 && _showAppBarTitle) {
      setState(() => _showAppBarTitle = false);
    }
  }

  // Logic to smooth scroll to "About" section
  void _scrollToDetails() {
    final context = _aboutSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.1, // Aligns slightly below the very top
      );
    }
  }

  Future<void> _launchMaps(String location) async {
    final Uri uri = Uri.parse("geo:0,0?q=${Uri.encodeComponent(location)}");
    final Uri webUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open maps."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- 1. Immersive Curvy Header ---
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: kPrimaryColor,
            elevation: 0,
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
            // ✅ FIX 1: Animated Title that appears only when scrolled
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showAppBarTitle ? 1.0 : 0.0,
              child: Text(
                widget.drive.title,
                style: const TextStyle(
                  color: kCreamLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'drive_image_${widget.drive.id}',
                      child: _buildDriveImage(widget.drive.imageUrl),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black38, Colors.transparent],
                          stops: const [0.0, 0.4],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- 2. Curvy Body Content ---
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                color: kCreamColor,
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Title (Visible initially)
                    Text(
                      widget.drive.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Actionable Info Cards ---

                    // 1. Date & Time (Clickable "See Details")
                    InkWell(
                      onTap: _scrollToDetails, // ✅ FIX 2: Scrolls to "About"
                      borderRadius: BorderRadius.circular(16),
                      child: _buildInfoCard(
                        icon: Icons.calendar_month_rounded,
                        title: "Date & Time",
                        subtitle: DateFormat('EEEE, MMM d, yyyy').format(widget.drive.date),
                        trailing: "See Details", // Now useful!
                        isLink: true,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 2. Location (Clickable Map)
                    InkWell(
                      onTap: () => _launchMaps(widget.drive.location),
                      borderRadius: BorderRadius.circular(16),
                      child: _buildInfoCard(
                        icon: Icons.location_on_rounded,
                        title: "Location",
                        subtitle: widget.drive.location,
                        trailing: "View Map",
                        isLink: true,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- About Section (Target for scroll) ---
                    Container(key: _aboutSectionKey), // Scroll target anchor
                    const Text(
                      "About this Drive",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${widget.drive.details}\n\nThis drive is open to all residents. Please ensure you segregate your items before arrival to speed up the collection process.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ✅ FIX 3: Useful "Guidelines" Section instead of empty space
                    _buildGuidelinesSection(),

                    const SizedBox(height: 40), // Bottom breathing room
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildGuidelinesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: kPrimaryColor),
              SizedBox(width: 10),
              Text(
                "Participant Guidelines",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletPoint("Bring valid ID proof if required."),
          _buildBulletPoint("Ensure waste is clean and dry."),
          _buildBulletPoint("Separate e-waste from plastics."),
          _buildBulletPoint("Volunteers will guide you on arrival."),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kAccentColor)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
        ],
      ),
    );
  }

  Widget _buildDriveImage(String url) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator(color: kAccentColor)),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
        ),
      );
    } else {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
        ),
      );
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    bool isLink = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCreamLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLink ? kAccentColor.withOpacity(0.5) : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            // Link Indicator
            Row(
              children: [
                Text(
                  trailing,
                  style: TextStyle(
                    color: isLink ? kAccentColor : Colors.grey[600],
                    fontWeight: isLink ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                if (isLink)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.arrow_forward_ios_rounded, size: 10, color: kAccentColor),
                  )
              ],
            )
          ]
        ],
      ),
    );
  }
}