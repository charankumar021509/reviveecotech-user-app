import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

// ==== Constants ====
const kPrimaryColor = Color(0xFF013D5A);
const kCreamColor = Color(0xFFFCF3E3);
const kAccentColor = Color(0xFFA6CB4E);

// ==== Custom Map Style (Minimalist - Hides Clutter) ====
const String _mapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.business",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  }
]
''';

class AddAddress extends StatefulWidget {
  final DocumentSnapshot? existingAddress;

  const AddAddress({super.key, this.existingAddress});

  @override
  State<AddAddress> createState() => _AddAddressState();
}

class _AddAddressState extends State<AddAddress> {
  late GoogleMapController googleMapController;

  // State
  bool _isLoadingAddress = false;
  bool _isSaving = false;
  bool _isEditMode = false;

  LatLng? _mapCenter;
  String _sAddress = "Drag map to select location";
  String? _sAddressType;

  // Controllers
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Sheet Control
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final ValueNotifier<double> _sheetPosition = ValueNotifier<double>(0.35);

  // Debouncer for Map Movement (Prevents API spam)
  Timer? _debounceTimer;

  // ⚠️ API KEY
  final String _apiKey = "AIzaSyDzz4Aysry1F51chHm16SmrfUXWek7XueQ";

  @override
  void initState() {
    super.initState();

    if (widget.existingAddress != null) {
      _isEditMode = true;
      final data = widget.existingAddress!.data() as Map<String, dynamic>;
      _buildingController.text = data['line1'] ?? '';
      _sAddress = data['fullAddress'] ?? 'Location Selected';
      _sAddressType = data['addressType'];
      _mapCenter = LatLng(data['latitude'], data['longitude']);
    } else {
      _isEditMode = false;
      _mapCenter = const LatLng(20.5937, 78.9629);
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  // ==== Map Logic ====

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await _determinePosition();
      final latLng = LatLng(position.latitude, position.longitude);

      googleMapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
      setState(() => _mapCenter = latLng);
      _fetchAddressFromLatLng(latLng);
    } catch (e) {
      // Quietly fail or log, don't spam snackbar on init
      print("Location Error: $e");
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('Location permissions are denied.');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _onCameraMove(CameraPosition position) {
    _mapCenter = position.target;
    // Reset timer
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // Wait 600ms after movement stops before fetching address
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _fetchAddressFromLatLng(_mapCenter!);
    });
  }

  Future<void> _fetchAddressFromLatLng(LatLng position) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAddress = true;
      _sAddress = "Fetching address...";
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
          place.administrativeArea
        ].where((e) => e != null && e.isNotEmpty).toSet().join(', ');

        setState(() => _sAddress = address);
      } else {
        setState(() => _sAddress = "Unknown Location");
      }
    } catch (e) {
      setState(() => _sAddress = "Could not fetch address");
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  // ==== Save Logic ====

  Future<void> _saveAddress() async {
    if (_mapCenter == null) {
      _showSnackBar("Please select a location.", isError: true);
      return;
    }
    if (_buildingController.text.trim().isEmpty) {
      _showSnackBar("Enter Building Name / House No.", isError: true);
      return;
    }
    if (_sAddressType == null) {
      _showSnackBar("Select an address type.", isError: true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Login required.", isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final addressData = {
        'line1': _buildingController.text.trim(),
        'fullAddress': _sAddress,
        'latitude': _mapCenter!.latitude,
        'longitude': _mapCenter!.longitude,
        'addressType': _sAddressType,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!_isEditMode) {
        addressData['createdAt'] = FieldValue.serverTimestamp();
      }

      final collectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses');

      if (_isEditMode) {
        await collectionRef.doc(widget.existingAddress!.id).update(addressData);
        _showSnackBar("Address updated successfully!");
      } else {
        await collectionRef.add(addressData);
        _showSnackBar("Address saved successfully!");
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Failed to save: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.red.shade700 : kAccentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: kCreamColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _isEditMode ? 'Edit Address' : 'Add Address',
          style: const TextStyle(
            fontFamily: 'RedHatDisplay',
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
      ),
      body: Stack(
        children: [
          // 1. Google Map
          ValueListenableBuilder<double>(
            valueListenable: _sheetPosition,
            builder: (context, extent, _) {
              double mapHeight = MediaQuery.of(context).size.height * (1.0 - (extent * 0.6));
              return SizedBox(
                height: mapHeight,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _mapCenter ?? const LatLng(20.5937, 78.9629),
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    googleMapController = controller;
                    // ✅ Apply Custom Style
                    googleMapController.setMapStyle(_mapStyle);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onCameraMove: _onCameraMove,
                ),
              );
            },
          ),

          // 2. Center Pin
          Positioned(
            top: 0, bottom: 100,
            left: 0, right: 0,
            child: const Center(
              child: Icon(Icons.location_on_sharp, size: 45, color: Colors.redAccent),
            ),
          ),

          // 3. Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _searchController,
                googleAPIKey: _apiKey,
                inputDecoration: const InputDecoration(
                  hintText: "Search location...",
                  prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                debounceTime: 500,
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  if (prediction.lat != null && prediction.lng != null) {
                    final lat = double.parse(prediction.lat!);
                    final lng = double.parse(prediction.lng!);
                    final newPos = LatLng(lat, lng);

                    googleMapController.animateCamera(CameraUpdate.newLatLngZoom(newPos, 17));
                    setState(() => _mapCenter = newPos);
                    _fetchAddressFromLatLng(newPos);

                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  }
                },
                itemClick: (Prediction prediction) {
                  _searchController.text = prediction.description ?? "";
                  _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
                },
              ),
            ),
          ),

          // 4. Bottom Sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.38,
            minChildSize: 0.25,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  _sheetPosition.value = notification.extent;
                  return true;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2)),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding + 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40, height: 5,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        // Fetched Address
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: kPrimaryColor, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _isLoadingAddress
                                    ? SizedBox(height: 20, child: LinearProgressIndicator(color: kPrimaryColor, backgroundColor: Colors.grey.shade100))
                                    : Text(_sAddress, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Building Name
                        TextFormField(
                          controller: _buildingController,
                          decoration: InputDecoration(
                            labelText: 'Building / House No. / Landmark',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Chips
                        const Text("Save as", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildTypeChip("Home", Icons.home),
                            const SizedBox(width: 10),
                            _buildTypeChip("Office", Icons.work),
                            const SizedBox(width: 10),
                            _buildTypeChip("Other", Icons.location_city),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: (_isSaving || _isLoadingAddress) ? null : _saveAddress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                            child: _isSaving
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(
                              _isEditMode ? "Update Address" : "Save Address",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'RedHatDisplay'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 5. FAB
          ValueListenableBuilder<double>(
            valueListenable: _sheetPosition,
            builder: (context, extent, _) {
              double bottomPos = (MediaQuery.of(context).size.height * extent) + 20;
              if (bottomPos > MediaQuery.of(context).size.height - 200) bottomPos = MediaQuery.of(context).size.height - 200;

              return Positioned(
                right: 16,
                bottom: bottomPos,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: kPrimaryColor),
                  onPressed: () => _getCurrentLocation(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon) {
    bool isSelected = _sAddressType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sAddressType = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor : Colors.white,
            border: Border.all(color: isSelected ? kPrimaryColor : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}