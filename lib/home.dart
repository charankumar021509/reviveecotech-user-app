  import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:revive_eco_tech_app/history.dart';
import 'package:revive_eco_tech_app/pricelist.dart';
import 'package:revive_eco_tech_app/setting.dart';
import 'package:revive_eco_tech_app/profile.dart';
import 'Schedule_Pickup.dart';
import 'notification.dart';
import 'widgets/pickup_tracker.dart';
import 'package:revive_eco_tech_app/all_trackers_page.dart';
import 'package:revive_eco_tech_app/society_campaign_page.dart';

// IMPORTS FOR NEW DRIVE FEATURE
import 'dart:math';
import 'package:revive_eco_tech_app/widgets/drive_model.dart';
import 'package:revive_eco_tech_app/widgets/drive_card.dart';
import 'package:revive_eco_tech_app/all_drives_page.dart';
import 'package:revive_eco_tech_app/drive_details_page.dart';

// IMPORT THE BANNER MODEL
import 'package:revive_eco_tech_app/widgets/banner_model.dart';

// IMPORT URL_LAUNCHER
import 'package:url_launcher/url_launcher.dart';

// IMPORT NOTIFICATION SERVICE
import 'package:revive_eco_tech_app/utilities/notification_service.dart';
import 'package:easy_localization/easy_localization.dart';

// ==== Constants ====
const kPrimaryColor = Color(0xFF013856);
const kAccentColor = Color(0xFFa7cd47);
const kCreamColor = Color(0xFFfcf3e2);
const kCreamLight = Color(0xFFfefaef);
const kGreenLight = Color(0xFFd3e7b4);
const kRedColor = Color(0xFFE53935);

Color shadowColor = Colors.white;

// ==== HomePage ====
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String userName = "User";
 

  // State variables for live data
  bool _isLoadingStats = true;
  bool _isLoadingTracker = true;
  bool _isLoadingScraps = true;
  double _totalWeight = 0;
  double _totalEarnings = 0;
  
 
  DocumentSnapshot? _latestPendingPickup;
  //List<MapEntry<String, int>> _topScrapsList = [];
  //Map<String, double> _scrapWeights = {};

  // STATE FOR UPCOMING DRIVES
  bool _isLoadingDrives = true;
  List<Drive> _homePageDrives = [];

  // STATE FOR BANNERS
  bool _isLoadingBanners = true;
  List<BannerModel> _banners = [];

  // STATE FOR NAVIGATION
  int _currentIndex = 0;

  // STATE FOR NOTIFICATION COUNT
  int _notificationCount = 0;

  // ✅ SIMPLE LOCATION STATE
  String _currentLocation = "India"; // Default fallback

  // Helper for Professional SnackBar
  void _showFeatureToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // CEVUS: Cached Image Loader
 Widget buildCroppedAssetCard(String path, double topTrim, double bottomTrim) {
  return ClipRect(
    clipper: UnevenCropClipper(
      topTrim: topTrim,
      bottomTrim: bottomTrim,
    ),
    child: path.startsWith('http')
       ? Image.network(
    path,
    fit: BoxFit.cover,
    width: double.infinity,

    loadingBuilder: (context, child, progress) {

      if (progress == null) {
        return child;
      }

      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: kAccentColor,
        ),
      );
    },

    errorBuilder: (context, error, stackTrace) {

      print("FAILED IMAGE:");
print(path);
print(error);

      return Image.asset(
        'assets/images/home/15.png',
        fit: BoxFit.cover,
        width: double.infinity,
      );
    },
  )
        : Image.asset(
            path,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[500],
                ),
              );
            },
          ),
  );
}

 @override
void initState() {

  super.initState();

  WidgetsBinding.instance
      .addPostFrameCallback((_) {

   
  });

    WidgetsBinding.instance.addObserver(this);
    NotificationService().initNotifications(context);
    _listenToNotificationCount();
    _fetchAllData();
  }

  void _listenToNotificationCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _notificationCount = snapshot.docs.length;
          });
        }
      });
    }
  }

  void _onPickupScheduled() {
    _refreshTrackerData();
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTrackerData();
    }
  }

  void _fetchAllData() {
    fetchUserName();
    _fetchStatsAndScraps();
    _fetchLatestPickup();
    _fetchUpcomingDrives();
    _fetchBanners();
  }

  void _refreshTrackerData() {
    if (mounted) {
      setState(() {
        _isLoadingTracker = true;
        _isLoadingStats = true;
      });
      _fetchLatestPickup();
      _fetchStatsAndScraps();
      fetchUserName();
    }
  }

  // ✅ UPDATED PROFILE & LOCATION LOADER
  Future<void> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;

          // 1. Get Name
          String fetchedName = data["name"] ?? "User";
          if (fetchedName.isEmpty) fetchedName = "User-${user.uid.substring(0, 6)}";

          // 2. Get Location from 'currentAddress' map
          String detectedLocation = "India"; // Default

          // Safely check if currentAddress exists and has fullAddress
          if (data['currentAddress'] != null && data['currentAddress'] is Map) {
            String fullAddress = data['currentAddress']['fullAddress'] ?? "";

            // Smart Check
            if (fullAddress.contains("Telangana") || fullAddress.contains("Hyderabad")) {
              detectedLocation = "Telangana";
            } else if (fullAddress.contains("Andhra") ||
                fullAddress.contains("Visakhapatnam") ||
                fullAddress.contains("Vijayawada")) {
              detectedLocation = "Andhra Pradesh";
            }
          }

          if (mounted) {
            setState(() {
              userName = fetchedName;
              _currentLocation = detectedLocation; // Updates UI automatically
            });
          }
        }
      } catch (e) {
        print("Error fetching profile: $e");
      }
    }
  }

  // Future<void> _fetchStatsAndScraps() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     if (mounted)
  //       setState(() {
  //         _isLoadingStats = false;
  //         _isLoadingScraps = false;
  //       });
  //     return;
  //   }
  //
  //   double tempTotalWeight = 0;
  //   double tempTotalEarnings = 0;
  //   Map<String, int> tempScrapTimes = {};
  //   Map<String, double> tempScrapWeights = {};
  //
  //   try {
  //     final snapshot = await FirebaseFirestore.instance
  //         .collection('pickups')
  //         .where('userId', isEqualTo: user.uid)
  //         .where('status', isEqualTo: 'Completed')
  //         .get();
  //
  //     for (final doc in snapshot.docs) {
  //       final data = doc.data();
  //       final weight = (data['finalWeight'] ?? data['totalEstimatedWeight_kg'] ?? 0).toDouble();
  //       final amount = (data['amount'] ?? data['estimatedCost'] ?? 0).toDouble();
  //
  //       tempTotalWeight += weight;
  //       tempTotalEarnings += amount;
  //
  //       List<String> scraps = List<String>.from(data['scrapTypes'] ?? data['scrapCategories'] ?? []);
  //       double weightPerType = weight / (scraps.isEmpty ? 1 : scraps.length);
  //
  //       for (String scrap in scraps) {
  //         tempScrapTimes[scrap] = (tempScrapTimes[scrap] ?? 0) + 1;
  //         tempScrapWeights[scrap] =
  //             (tempScrapWeights[scrap] ?? 0) + weightPerType;
  //       }
  //     }
  //
  //     final sortedByTimes = tempScrapTimes.entries.toList()
  //       ..sort((a, b) => b.value.compareTo(a.value));
  //
  //     if (mounted) {
  //       setState(() {
  //         _totalWeight = tempTotalWeight;
  //         _totalEarnings = tempTotalEarnings;
  //         _isLoadingStats = false;
  //        // _topScrapsList = sortedByTimes.take(3).toList();
  //        // _scrapWeights = tempScrapWeights;
  //        // _isLoadingScraps = false;
  //       });
  //     }
  //   } catch (e) {
  //     print("Error fetching stats: $e");
  //     if (mounted)
  //       setState(() {
  //         _isLoadingStats = false;
  //        // _isLoadingScraps = false;
  //       });
  //   }
  // }



  Future<void> _fetchStatsAndScraps() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingStats = false);
      return;
    }

    try {
      // 1. THE PURE CACHE APPROACH: One single read for maximum speed and lowest cost.
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
final pickupsSnapshot =

    await FirebaseFirestore.instance

        .collection('pickups')

        .where(
          'userId',
          isEqualTo: user.uid,
        )

        .get();

double totalEarnings = 0;

for (var doc in pickupsSnapshot.docs) {
  final data = doc.data();

  // Only include completed orders that are not declined
  if (data['status'] == 'Completed' &&
      data['declinedStatus'] != true) {

    totalEarnings +=
        (data['finalPrice'] as num?)?.toDouble() ?? 0;
  }
}
    if (mounted) {

  setState(() {

    _totalWeight =
    (userData['totalWeight']
        as num? ?? 0)
        .toDouble();

    _totalEarnings =
        totalEarnings;

    _isLoadingStats = false;
  });
}
    } catch (e) {
      print("Error fetching stats: $e");
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchLatestPickup() async {
    if (!mounted) return;
    setState(() => _isLoadingTracker = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingTracker = false);
      return;
    }
    try {
    final snapshot =
    await FirebaseFirestore.instance

        .collection('pickups')

        .where(
          'userId',
          isEqualTo: user.uid,
        )

        .where(
          'status',
          whereIn: [

            'Pending',

            'Confirmed',

            'Out-for-Pickup',

            'Estimate Sent',

            'OTP Generated',
          ],
        )

        .orderBy(
          'createdAt',
          descending: true,
        )

        .limit(1)

        .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) setState(() { _latestPendingPickup = null; _isLoadingTracker = false; });
        return;
      }
      final status =
    snapshot.docs.first['status'];

if (status == 'Completed') {

  if (mounted)
    setState(() {

      _latestPendingPickup =
          null;

      _isLoadingTracker =
          false;
    });

  return;
}

      final docs = snapshot.docs;

      docs.sort((a, b) {
        final statusA = a['status'] as String;
        final statusB = b['status'] as String;
        final dateA = (a['pickupDate'] as Timestamp).toDate();
        final dateB = (b['pickupDate'] as Timestamp).toDate();

        final bool isUrgentA = statusA == 'Out-for-Pickup';
        final bool isUrgentB = statusB == 'Out-for-Pickup';

        if (isUrgentA && !isUrgentB) return -1;
        if (!isUrgentA && isUrgentB) return 1;

        return dateA.compareTo(dateB);
      });

      if (mounted) {
        setState(() {
          _latestPendingPickup = docs.first;
          _isLoadingTracker = false;
        });
      }
    } catch (e) {
      print("Error fetching latest pickup: $e");
      if (mounted) setState(() => _isLoadingTracker = false);
    }
  }

  Future<void> _fetchUpcomingDrives() async {
    if (!mounted) return;
    setState(() => _isLoadingDrives = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('drives')
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('date')
          .limit(3)
          .get();
      final realDrives =
      snapshot.docs.map((doc) => Drive.fromFirestore(doc)).toList();
      List<Drive> drivesForHome = List.from(realDrives);
      int placeholdersNeeded = max(0, 3 - realDrives.length);
      for (int i = 0; i < placeholdersNeeded; i++) {
        drivesForHome.add(Drive.placeholder(uniqueId: i));
      }
      if (mounted) {
        setState(() {
          _homePageDrives = drivesForHome;
          _isLoadingDrives = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _homePageDrives = [
            Drive.placeholder(uniqueId: 0),
            Drive.placeholder(uniqueId: 1),
            Drive.placeholder(uniqueId: 2),
          ];
          _isLoadingDrives = false;
        });
      }
    }
  }

  Future<void> _fetchBanners() async {
    if (!mounted) return;
    setState(() => _isLoadingBanners = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('banners')
          .orderBy('order')
          .get();
      final banners =
      snapshot.docs.map((doc) => BannerModel.fromFirestore(doc)).toList();
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoadingBanners = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBanners = false;
          _banners = [];
        });
      }
    }
  }

  void _onBannerTapped(BannerModel banner) async {
    if (banner.linkValue.isEmpty) return;
    switch (banner.linkType) {
      case 'URL':
        final uri = Uri.tryParse(banner.linkValue);
        if (uri != null) {
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            print('Could not launch ${banner.linkValue}: $e');
          }
        }
        break;
      case 'PAGE':
        if (banner.linkValue == '/schedule_pickup') {
          setState(() {
            _currentIndex = 1;
          });
          return;
        }
        if (banner.linkValue == '/settings') {
          setState(() {
            _currentIndex = 2;
          });
          return;
        }
        Widget? page;
        switch (banner.linkValue) {
          case '/pricelist':
            page = pricelist();
            break;
          case '/society_campaign':
            page = const SocietyCampaignPage();
            break;
          case '/history':
            page = HistoryScreen();
            break;
        }
        if (page != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page!),
          );
        }
        break;
      case 'NONE':
      default:
        break;
    }
  }

  void _onDriveCardTapped(Drive drive) {
    if (drive.isPlaceholder) {
      _showFeatureToast("A new drive is coming soon! Check back later.");
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriveDetailsPage(drive: drive),
        ),
      );
    }
  }

  void _onViewAllDrivesTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllDrivesPage()),
    );
  }

  int _mapStatusToStep(String? status) {
    switch (status) {
      case 'Pending':
        return 1;
      case 'Confirmed':
        return 2;
      case 'Out-for-Pickup':
        return 3;
      case 'Completed':
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ==== 1. Header ====
          Container(
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(40)),
              image: const DecorationImage(
                image: AssetImage('assets/images/home/homeheader.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 45, 24, 60),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => profile()),
                        ).then((_) => _refreshTrackerData());
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kAccentColor, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person,
                              color: kPrimaryColor, size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // User Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hello, $userName',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // ✅ SIMPLE LOCATION DISPLAY
                          Row(
                            children: [
                              Icon(Icons.location_on, color: kAccentColor, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _currentLocation, // Dynamic based on address
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Notification Bell
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NotificationPage()),
                        ).then((_) => _refreshTrackerData());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.notifications_outlined,
                                color: kAccentColor, size: 28),
                            if (_notificationCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    _notificationCount > 9
                                        ? '9+'
                                        : _notificationCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==== 2. Stats Card ====
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: kCreamLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: _isLoadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatCard(

  icon: Icons.recycling,

  label:
      '${_totalWeight.toStringAsFixed(1)} kg',

  sub:
      'recycled'.tr(),
),

StatCard(

  icon: Icons.cloud,

  label:
      '${(_totalWeight * 1.61803399).toStringAsFixed(1)} m³',

  sub:
      'co2_saved'.tr(),
),

StatCard(

  icon: Icons.currency_rupee,

  label:
      '₹${_totalEarnings.toStringAsFixed(0)}',

  sub:
      'earned'.tr(),
),
                ],
              ),
            ),
          ),

          // ==== 3. Banners ====
          _isLoadingBanners
              ? const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          )
              : _banners.isEmpty
              ? const SizedBox(height: 0)
              : ImageCardScroller(
            children: _banners.map((banner) {
              return GestureDetector(
                onTap: () => _onBannerTapped(banner),
                child: buildCroppedAssetCard(banner.imageUrl, 0, 0),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ==== 4. Shortcuts Grid ====
          Padding(
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 0.85, // ✅ NEW: Makes the box taller than it is wide
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  ShortcutButton(
                    icon: Icons.list_alt,
                    label: 'price_list'.tr(),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const pricelist()));
                    },
                  ),
                  ShortcutButton(
                    icon: Icons.history,
                   label: 'history'.tr(),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => HistoryScreen()))
                          .then((_) => _refreshTrackerData());
                    },
                  ),
                  ShortcutButton(
                    icon: Icons.track_changes,
                    label: 'tracking'.tr(),
                    onTap: () {

  Navigator.push(

    context,

    MaterialPageRoute(

      builder: (context) =>
          const AllTrackersPage(),
    ),
  );
},
                  ),
                  ShortcutButton(
                    icon: Icons.campaign,
                    label: 'campaign'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SocietyCampaignPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

         
          // ==== 6. Upcoming Drives ====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Upcoming Drives",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: kPrimaryColor),
                    ),
                    TextButton(
                      onPressed: _onViewAllDrivesTapped,
                      child: const Text(
                        "View all",
                        style: TextStyle(color: kAccentColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: _isLoadingDrives
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _homePageDrives.length,
                    itemBuilder: (context, index) {
                      final drive = _homePageDrives[index];
                      return DriveCard(
                        drive: drive,
                        onTap: () => _onDriveCardTapped(drive),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 115),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _pageTitles = [

  'home'.tr(),

  'schedule_pickup'.tr(),

  'settings'.tr(),
];

    final List<Widget> pages = [
      _buildHomeContent(),
      SchedulePickup(onPickupScheduled: _onPickupScheduled, isTab: true),
      Settings_page(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() {
          _currentIndex = 0;
        });
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: kCreamColor,
          extendBodyBehindAppBar: true,

          appBar: _currentIndex == 0
              ? null
              : PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(47),
              ),
              child: AppBar(
                centerTitle: true,
                toolbarHeight: 40,
                title: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _pageTitles[_currentIndex],
                    style: const TextStyle(
                      fontFamily: 'RedHatDisplay',
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 1.0,
                      color: kCreamColor,
                    ),
                  ),
                ),
                backgroundColor: kPrimaryColor,
                automaticallyImplyLeading: false,
                elevation: 0,
              ),
            ),
          ),

          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),

          extendBody: true,
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _navItem(Icons.home_rounded, 0),
                      _navItem(Icons.calendar_month_rounded, 1),
                      _navItem(Icons.settings_rounded, 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final bool selected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
          selected ? kAccentColor.withOpacity(0.25) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 28,
          color: selected ? kPrimaryColor : Colors.grey[600],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  const StatCard(
      {required this.icon, required this.label, required this.sub, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 32),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kPrimaryColor),
          ),
        ),
        Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}

class ShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ShortcutButton({
    required this.icon,
    required this.label,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: kAccentColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kPrimaryColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class UnevenCropClipper extends CustomClipper<Rect> {
  final double topTrim;
  final double bottomTrim;
  UnevenCropClipper({required this.topTrim, required this.bottomTrim});

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, topTrim, size.width, size.height - bottomTrim);

  @override
  bool shouldReclip(covariant UnevenCropClipper oldClipper) =>
      topTrim != oldClipper.topTrim || bottomTrim != oldClipper.bottomTrim;
}

class ImageCardScroller extends StatefulWidget {
  final List<Widget> children;
  const ImageCardScroller({super.key, required this.children});

  @override
  _ImageCardScrollerState createState() => _ImageCardScrollerState();
}

class _ImageCardScrollerState extends State<ImageCardScroller> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
  }

  @override
  void didUpdateWidget(ImageCardScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      _controller.jumpToPage(0);
      _currentIndex = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.children.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: widget.children[index],
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.children.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 12 : 8,
              height: _currentIndex == index ? 12 : 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? const Color(0xFFa8ce4c)
                    : Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}