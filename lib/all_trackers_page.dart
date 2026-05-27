// lib/all_trackers_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pickup_details_page.dart';

// Constants
const kPrimaryColor = Color(0xFF013856);
const kCreamColor = Color(0xFFfcf3e2);
const kAccentColor = Color(0xFFa7cd47);

class AllTrackersPage extends StatefulWidget {
  const AllTrackersPage({super.key});

  @override
  State<AllTrackersPage> createState() =>
      _AllTrackersPageState();
}

class _AllTrackersPageState
    extends State<AllTrackersPage> {

  /// ACTIVE PICKUPS STREAM
  Stream<QuerySnapshot>
      _getPendingPickupsStream() {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.empty();
    }

    return FirebaseFirestore.instance
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
  'pickupDate',
  descending: true,
)
.snapshots();
  }

  /// OPEN DETAILS PAGE
  void _navigateToDetails(
      String pickupId) {

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) =>
            PickupDetailsPage(
          pickupId: pickupId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return AnnotatedRegion<
        SystemUiOverlayStyle>(

      value:
          const SystemUiOverlayStyle(
        statusBarColor:
            Colors.transparent,

        statusBarIconBrightness:
            Brightness.light,
      ),

      child: Scaffold(

        backgroundColor:
            kCreamColor,

        appBar: AppBar(

          centerTitle: true,

          title: const Text(
            'Active Pickups',

            style: TextStyle(
              fontFamily:
                  'RedHatDisplay',

              fontWeight:
                  FontWeight.bold,

              fontSize: 24,

              letterSpacing: 1.0,

              color: kCreamColor,
            ),
          ),

          backgroundColor:
              kPrimaryColor,

          elevation: 0,

          leading: IconButton(
            icon: const Icon(
              Icons
                  .arrow_back_ios_new_rounded,

              color: Colors.white,
            ),

            onPressed: () =>
                Navigator.pop(context),
          ),

          shape:
              const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(
              bottom:
                  Radius.circular(28),
            ),
          ),
        ),

        body: StreamBuilder<QuerySnapshot>(

          stream:
              _getPendingPickupsStream(),

          builder: (
            context,
            snapshot,
          ) {

            /// LOADING
            if (snapshot.connectionState ==
                ConnectionState.waiting) {

              return const Center(
                child:
                    CircularProgressIndicator(
                  color: kPrimaryColor,
                ),
              );
            }

            /// ERROR
            if (snapshot.hasError) {

              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                          20.0),

                  child: Text(
                    "Something went wrong.\nPlease try again later.",

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }

            /// NO ACTIVE PICKUPS
            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {

              return Center(
                child: Column(

                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [

                    Container(

                      padding:
                          const EdgeInsets
                              .all(25),

                      decoration:
                          BoxDecoration(

                        color: Colors.white,

                        shape:
                            BoxShape.circle,

                        boxShadow: [

                          BoxShadow(
                            color: Colors.black
                                .withOpacity(
                                    0.05),

                            blurRadius: 15,

                            offset:
                                const Offset(
                                    0, 5),
                          ),
                        ],
                      ),

                      child: Icon(
                        Icons
                            .check_circle_outline_rounded,

                        size: 60,

                        color:
                            kAccentColor,
                      ),
                    ),

                    const SizedBox(
                        height: 24),

                    const Text(
                      "No Active Pickup",

                      style: TextStyle(
                        fontSize: 22,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            kPrimaryColor,
                      ),
                    ),

                    const SizedBox(
                        height: 8),

                    Text(
                      "Your pickup will appear here once rider starts pickup.",

                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        fontSize: 14,

                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            /// ACTIVE PICKUPS
            final pickups =
                snapshot.data!.docs;
                final now = DateTime.now();

final activePickups =
    pickups.where((doc) {

  final data =
      doc.data()
          as Map<String, dynamic>;

  final pickupDate =
      (data['pickupDate']
              as Timestamp?)
          ?.toDate();

  if (pickupDate == null) {
    return false;
  }

  return pickupDate.isAfter(

    now.subtract(
      const Duration(days: 1),
    ),
  );
}).toList();

            return ListView.builder(

              padding:
                  const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                40,
              ),

            itemCount: activePickups.length,

              itemBuilder:
                  (context, index) {

                final pickupDoc =
    activePickups[index];

                final data =
                    pickupDoc.data()
                        as Map<String, dynamic>;

                final pickupDate =
                    (data['pickupDate']
                            as Timestamp?)
                        ?.toDate();

                final status =
                    data['status'] ??
                        'Pending';

                return Padding(

                  padding:
                      const EdgeInsets.only(
                          bottom: 16),

                  child: GestureDetector(

                    onTap: () =>
                        _navigateToDetails(
                      pickupDoc.id,
                    ),

                    child: Container(

                      padding:
                          const EdgeInsets
                              .all(20),

                      decoration:
                          BoxDecoration(

                        color: Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                                    20),

                        boxShadow: [

                          BoxShadow(
                            color: Colors.black
                                .withOpacity(
                                    0.05),

                            blurRadius: 10,

                            offset:
                                const Offset(
                                    0, 4),
                          ),
                        ],
                      ),

                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          Row(

                            children: [

                              Container(

                                padding:
                                    const EdgeInsets
                                        .all(
                                            12),

                                decoration:
                                    BoxDecoration(

                                  color:
                                      kCreamColor,

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              12),
                                ),

                                child:
                                    const Icon(

                                  Icons
                                      .local_shipping,

                                  color:
                                      kPrimaryColor,
                                ),
                              ),

                              const SizedBox(
                                  width: 14),

                              Expanded(

                                child: Column(

                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    Text(

                                      status,

                                      style:
                                          const TextStyle(

                                        fontWeight:
                                            FontWeight.bold,

                                        fontSize:
                                            18,

                                        color:
                                            kPrimaryColor,
                                      ),
                                    ),

                                    const SizedBox(
                                        height:
                                            4),

                                    Text(

                                      pickupDate !=
                                              null
                                          ? "${pickupDate.day}/${pickupDate.month}/${pickupDate.year}"
                                          : "No Date",

                                      style:
                                          TextStyle(

                                        color:
                                            Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                              height: 18),

                          Text(

                            status ==
                                    'Out-for-Pickup'

                                ? 'Rider is on the way to your location.'

                                : status ==
                                        'Confirmed'

                                    ? 'Pickup confirmed successfully.'

                                    : status ==
                                            'OTP Generated'

                                        ? 'OTP generated successfully.'

                                        : 'Waiting for rider confirmation.',

                            style: TextStyle(
                              color:
                                  Colors.grey
                                      .shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}