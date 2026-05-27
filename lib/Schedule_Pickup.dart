import 'package:flutter/material.dart';
import 'package:revive_eco_tech_app/Add_Address.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting the currency
import 'manage_addresses.dart';
import 'package:easy_localization/easy_localization.dart';

// ==== Constants ====
const kPrimaryColor = Color(0xFF013D5A);
const kCreamColor = Color(0xFFFCF3E3);
const kAccentColor = Color(0xFFA6CB4E);

// ==== Data Model for Selected Item ====
class SelectedScrapItem {
  final String categoryId;
  final String categoryName;
  final String itemId;
  final String itemName;
  double amount; // Can be weight (kg) or count (pieces)
  final String unit;
  final double pricePerUnit;
  double calculatedCost;

  SelectedScrapItem({
    required this.categoryId,
    required this.categoryName,
    required this.itemId,
    required this.itemName,
    required this.amount,
    required this.unit,
    required this.pricePerUnit,
  }) : calculatedCost = amount * pricePerUnit;

  void updateAmount(double newAmount) {
    amount = newAmount;
    calculatedCost = amount * pricePerUnit;
  }

  String get displayAmount {
    return (unit == 'kg') ? amount.toStringAsFixed(1) : amount.round().toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'itemId': itemId,
      'itemName': itemName,
      'amount': amount,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'calculatedCost': calculatedCost,
    };
  }
}

class SchedulePickup extends StatefulWidget {
  final String? pickupId;
  final VoidCallback? onPickupScheduled;
  final bool isTab;

  const SchedulePickup({
    super.key,
    this.pickupId,
    this.onPickupScheduled,
    this.isTab = false,
  });

  @override
  State<SchedulePickup> createState() => _SchedulePickupState();
}

TextEditingController dateController = TextEditingController();

class _SchedulePickupState extends State<SchedulePickup> {
  DateTime selectedPickupDate =
    DateTime.now();
  final TextEditingController _descriptionController = TextEditingController();

  // Address State
  List<DocumentSnapshot> _addresses = [];
  DocumentSnapshot? _selectedAddress;
  String? _selectedTimeSlot;

  // Loading States
  bool _isLoadingAddresses = true;
  bool _isLoadingPrices = true;
  bool _isSubmitting = false;

  // State Variables for Edit Mode
  bool _isLoadingPickupData = false;
  bool _isEditMode = false;

  Map<String, Map<String, dynamic>> _availableCategories = {};
  List<SelectedScrapItem> _selectedItems = [];

  // Totals
  double _totalEstimatedCost = 0.0;
  double _totalEstimatedWeight = 0.0;

  void showCustomPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        int? selectedIndex;
        List<String> slots = [
          '09:00AM - 11:00AM',
          '11:00AM - 01:00PM',
          '03:00PM - 05:00PM',
          '05:00PM - 07:00PM',
        ];
     List<String> availableSlots = [];

DateTime now = DateTime.now();

for (String slot in slots) {

  int endHour = 23;

  if (slot.contains('09:00AM - 11:00AM')) {

    endHour = 11;

  } else if (slot.contains('11:00AM - 01:00PM')) {

    endHour = 13;

  } else if (slot.contains('03:00PM - 05:00PM')) {

    endHour = 17;

  } else if (slot.contains('05:00PM - 07:00PM')) {

    endHour = 19;
  }

 final slotEnd = DateTime(

  selectedPickupDate.year,
  selectedPickupDate.month,
  selectedPickupDate.day,
  endHour,
);

  if (now.isBefore(slotEnd)) {

    availableSlots.add(slot);
  }
}

        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Pickup Slot',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor),
                  ),
                  SizedBox(height: 16),
                  ...List.generate(
  availableSlots.length,
  (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                          Navigator.of(context).pop();
                          _onTimeSlotSelected(
    availableSlots[index],
);
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: selectedIndex == index
                                  ? kAccentColor
                                  : Colors.white,
                              border: Border.all(width: 1, color: selectedIndex == index ? kAccentColor : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                if(selectedIndex != index)
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))
                              ]
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
  availableSlots[index],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: selectedIndex == index ? kPrimaryColor : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTimeSlotSelected(String slot) {
    setState(() {
      _selectedTimeSlot = slot;
    });
  }

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.pickupId != null;
    _fetchAddresses();
    _fetchPriceList().then((_) {
      if (_isEditMode && widget.pickupId != null) {
        _loadPickupData(widget.pickupId!);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingAddresses = false);
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _addresses = querySnapshot.docs;
          _isLoadingAddresses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAddresses = false);
        _showSnackBar("Failed to load addresses: $e", isError: true);
      }
    }
  }

  Future<void> _fetchPriceList() async {
    if (mounted) setState(() => _isLoadingPrices = true);
    Map<String, Map<String, dynamic>> tempCategories = {};

    try {
      final categorySnapshot = await FirebaseFirestore.instance
          .collection('price_list')
          .orderBy('order')
          .get();

      for (var categoryDoc in categorySnapshot.docs) {
        final categoryData = categoryDoc.data();
        final categoryId = categoryDoc.id;
        final categoryName = categoryData['name'] as String? ?? 'Unnamed Category';
        List<Map<String, dynamic>> itemsList = [];

        final itemsSnapshot = await categoryDoc.reference
            .collection('items')
            .orderBy('order')
            .get();

        for (var itemDoc in itemsSnapshot.docs) {
          final itemData = itemDoc.data();
          itemsList.add({
            'id': itemDoc.id,
            'name': itemData['name'] ?? 'Unnamed Item',
            'price': (itemData['price'] as num?)?.toDouble() ?? 0.0,
            'unit': itemData['unit'] ?? 'unit',
          });
        }

        tempCategories[categoryId] = {
          'name': categoryName,
          'items': itemsList,
        };
      }

      if (mounted) {
        setState(() {
          _availableCategories = tempCategories;
          _isLoadingPrices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPrices = false);
        _showSnackBar("Failed to load scrap prices: $e", isError: true);
      }
    }
  }

  Future<void> _loadPickupData(String pickupId) async {
    if (!mounted) return;
    setState(() => _isLoadingPickupData = true);

    try {
      final pickupDoc = await FirebaseFirestore.instance.collection('pickups').doc(pickupId).get();

      if (!pickupDoc.exists || !mounted) {
        _showSnackBar("Pickup data not found.", isError: true);
        Navigator.pop(context);
        return;
      }

      final data = pickupDoc.data() as Map<String, dynamic>;

      DocumentSnapshot? matchingAddress;
      try {
        matchingAddress = _addresses.firstWhere(
              (addrDoc) => addrDoc.id == data['addressId'],
        );
      } catch (e) {
        matchingAddress = null;
      }
      _selectedAddress = matchingAddress;

      final pickupDate = (data['pickupDate'] as Timestamp?)?.toDate();
      if (pickupDate != null) {
        dateController.text = pickupDate.toLocal().toString().split(" ")[0];
      } else {
        dateController.clear();
      }

      _selectedTimeSlot = data['pickupTimeSlot'] as String?;
      _descriptionController.text = data['description'] ?? '';

      final List<dynamic> itemsFromDb = data['scrapItems'] ?? [];
      _selectedItems = itemsFromDb.whereType<Map<String, dynamic>>().map((itemMap) {
        return SelectedScrapItem(
          categoryId: itemMap['categoryId'] ?? '',
          categoryName: itemMap['categoryName'] ?? '',
          itemId: itemMap['itemId'] ?? '',
          itemName: itemMap['itemName'] ?? 'Unknown Item',
          amount: (itemMap['amount'] as num?)?.toDouble() ?? 0.0,
          unit: itemMap['unit'] ?? 'unit',
          pricePerUnit: (itemMap['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      _updateTotals();

    } catch (e) {
      _showSnackBar("Error loading pickup data: $e", isError: true);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoadingPickupData = false);
    }
  }

  void _updateTotals() {
    double newCost = 0.0;
    double newWeight = 0.0;

    for (var item in _selectedItems) {
      newCost += item.calculatedCost;
      if (item.unit.toLowerCase() == 'kg') {
        newWeight += item.amount;
      }
    }

    setState(() {
      _totalEstimatedCost = newCost;
      _totalEstimatedWeight = newWeight;
    });
  }

  // ✅ CEVUS: Popup Overhaul
  void _showItemSelectionPopup(BuildContext context, String categoryId) {
    final categoryData = _availableCategories[categoryId];
    if (categoryData == null || (categoryData['items'] as List).isEmpty) return;

    final String categoryName = categoryData['name'];
    final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(categoryData['items']);

    Map<String, dynamic>? selectedSubItem = items.isNotEmpty ? items[0] : null;
    SelectedScrapItem? existingCartItem;
    if (selectedSubItem != null) {
      existingCartItem = _selectedItems.firstWhere(
              (item) => item.itemId == selectedSubItem!['id'],
          orElse: () => SelectedScrapItem(categoryId: '', categoryName: '', itemId: '', itemName: '', amount: 0, unit: '', pricePerUnit: 0)
      );
    }
    double localAmount = existingCartItem?.amount ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final String unit = selectedSubItem?['unit'] ?? 'kg';
            final bool isKg = unit.toLowerCase() == 'kg';
            final double maxSliderValue = isKg ? 200.0 : 50.0;
            final int divisions = isKg ? 400 : 50;
            final double price = selectedSubItem?['price'] ?? 0.0;
            final double estimatedCost = localAmount * price;

            // Helper to modify amount safely
            void modifyAmount(double delta) {
              double newValue = localAmount + delta;
              if (newValue < 0) newValue = 0;
              if (newValue > maxSliderValue) newValue = maxSliderValue;
              setModalState(() {
                localAmount = newValue;
              });
            }

            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add $categoryName',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: Colors.grey))
                    ],
                  ),
                  SizedBox(height: 15),

                  // Item Dropdown
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: selectedSubItem,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: kPrimaryColor),
                        items: items.map((item) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: item,
                            child: Text("${item['name']} (₹${item['price']}/${item['unit']})", style: TextStyle(fontWeight: FontWeight.w500)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setModalState(() {
                              selectedSubItem = newValue;
                              existingCartItem = _selectedItems.firstWhere(
                                      (item) => item.itemId == selectedSubItem!['id'],
                                  orElse: () => SelectedScrapItem(categoryId: '', categoryName: '', itemId: '', itemName: '', amount: 0, unit: '', pricePerUnit: 0)
                              );
                              localAmount = existingCartItem?.amount ?? 0.0;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 25),

                  // Amount Slider with +/- Controls
                  if (selectedSubItem != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Est. Weight / Units:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                        Text(
                          isKg ? '${localAmount.toStringAsFixed(1)} $unit' : '${localAmount.round()} $unit',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        // Minus Button
                        IconButton.filled(
                          onPressed: () => modifyAmount(isKg ? -0.5 : -1.0),
                          icon: Icon(Icons.remove, color: kPrimaryColor),
                          style: IconButton.styleFrom(backgroundColor: kAccentColor.withOpacity(0.3)),
                        ),
                        Expanded(
                          child: Slider(
                            value: localAmount,
                            min: 0,
                            max: maxSliderValue,
                            divisions: divisions,
                            activeColor: kPrimaryColor,
                            inactiveColor: Colors.grey.shade300,
                            onChanged: (double value) {
                              setModalState(() {
                                localAmount = isKg ? value : value.roundToDouble();
                              });
                            },
                          ),
                        ),
                        // Plus Button
                        IconButton.filled(
                          onPressed: () => modifyAmount(isKg ? 0.5 : 1.0),
                          icon: Icon(Icons.add, color: kPrimaryColor),
                          style: IconButton.styleFrom(backgroundColor: kAccentColor.withOpacity(0.3)),
                        ),
                      ],
                    ),

                    // Projected Cost Display
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 20),
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: kCreamColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kAccentColor.withOpacity(0.5))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Projected Cost:", style: TextStyle(fontWeight: FontWeight.w600, color: kPrimaryColor)),
                          Text(
                            NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(estimatedCost),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor),
                          )
                        ],
                      ),
                    )
                  ],

                  // Action Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: kPrimaryColor,
                      elevation: 0,
                      minimumSize: Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: selectedSubItem == null ? null : () {
                      final itemToAddOrUpdate = selectedSubItem!;
                      final String itemId = itemToAddOrUpdate['id'];
                      final String itemName = itemToAddOrUpdate['name'];
                      final double itemPrice = itemToAddOrUpdate['price'];
                      final String itemUnit = itemToAddOrUpdate['unit'];

                      setState(() {
                        int existingIndex = _selectedItems.indexWhere((item) => item.itemId == itemId);

                        if (existingIndex != -1) {
                          if (localAmount > 0) {
                            _selectedItems[existingIndex].updateAmount(localAmount);
                          } else {
                            _selectedItems.removeAt(existingIndex);
                          }
                        } else if (localAmount > 0) {
                          _selectedItems.add(SelectedScrapItem(
                            categoryId: categoryId,
                            categoryName: categoryName,
                            itemId: itemId,
                            itemName: itemName,
                            amount: localAmount,
                            unit: itemUnit,
                            pricePerUnit: itemPrice,
                          ));
                        }
                      });

                      _updateTotals();
                      Navigator.pop(context);
                    },
                    child: Text( existingCartItem != null && existingCartItem!.amount > 0 ? 'Update Item' : 'Add to Pickup'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.red.shade700 : kPrimaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitPickup() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) { _showSnackBar("You must be logged in.", isError: true); return; }
    if (!_isEditMode && _selectedAddress == null) { _showSnackBar("Please select a pickup address.", isError: true); return; }
    if (dateController.text.isEmpty) { _showSnackBar("Please select a pickup date.", isError: true); return; }
    if (_selectedTimeSlot == null) { _showSnackBar("Please select a time slot.", isError: true); return; }
    if (_selectedItems.isEmpty) { _showSnackBar("Please add at least one scrap item.", isError: true); return; }

    setState(() => _isSubmitting = true);

    try {
      List<Map<String, dynamic>> itemsForFirestore = _selectedItems.map((item) => item.toMap()).toList();
      List<String> categoryNamesInvolved = _selectedItems.map((item) => item.categoryName).toSet().toList();

      if (_isEditMode) {
        final pickupRef = FirebaseFirestore.instance.collection('pickups').doc(widget.pickupId!);
        final updateData = {
          'scrapItems': itemsForFirestore,
          'scrapCategories': categoryNamesInvolved,
          'totalEstimatedWeight_kg': _totalEstimatedWeight,
          'estimatedCost': _totalEstimatedCost,
          'description': _descriptionController.text.trim(),
        };

        await pickupRef.update(updateData);
        _showSnackBar("Pickup updated successfully!");

      } else {
        final pickupDate = DateTime.parse(dateController.text);
        final addressData = _selectedAddress!.data() as Map<String, dynamic>;
        final userDoc =
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

final userData =
    userDoc.data() ?? {};

final customerName =
    userData['name'] ?? '';

final customerPhone =
    userData['phone'] ?? '';

        await FirebaseFirestore.instance.collection('pickups').add({
          'userId': user.uid,
          'customerName': customerName,

'customerPhone': customerPhone,
          'addressId': _selectedAddress!.id,
          'addressDetails': addressData,
          'pickupDate': Timestamp.fromDate(pickupDate),
          'pickupTimeSlot': _selectedTimeSlot,
          'scrapItems': itemsForFirestore,
          'scrapCategories': categoryNamesInvolved,
          'totalEstimatedWeight_kg': _totalEstimatedWeight,
          'estimatedCost': _totalEstimatedCost,
          'description': _descriptionController.text.trim(),
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _showSnackBar("Pickup scheduled successfully!");
      }

      if (mounted) {
        if (widget.isTab) {
          widget.onPickupScheduled?.call();
          _clearForm();
        } else {
          Navigator.pop(context);
        }
      }

    } catch (e) {
      _showSnackBar("Failed to ${_isEditMode ? 'update' : 'schedule'} pickup: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    setState(() {
      _descriptionController.clear();
      _selectedAddress = null;
      _selectedTimeSlot = null;
      dateController.clear();
      _selectedItems.clear();
      _updateTotals();
    });
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(color: kCreamColor, borderRadius: BorderRadius.circular(8)),
                      child: Icon(icon, color: kPrimaryColor, size: 22),
                    ),
                    SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                  ],
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateAndRefresh(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageAddressesPage()),
    );
    setState(() {
      _selectedAddress = null;
      _isLoadingAddresses = true;
    });
    _fetchAddresses();
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: kPrimaryColor, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {

  setState(() {

    selectedPickupDate =
        pickedDate;
         dateController.text =
        DateFormat(
          'yyyy-MM-dd',
        ).format(
          pickedDate,
        );
  });
}
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: true,
      title: Text(
        _isEditMode ? 'Edit Pickup' : 'Schedule Pickup',
        style: TextStyle(fontFamily: 'RedHatDisplay', fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 1.0, color: kCreamColor),
      ),
      backgroundColor: kPrimaryColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBody() {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final List<String> categoryIds = _availableCategories.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 100.0),
      child: Column(
        children: [
          // ==== Pickup Location ====
          _buildSection(
            icon: Icons.location_on,
            title: "pickup_location".tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AbsorbPointer(
                  absorbing: _isEditMode,
                  child: Opacity(
                    opacity: _isEditMode ? 0.6 : 1.0,
                    child: _isLoadingAddresses
                        ? Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<DocumentSnapshot>(
                      value: _selectedAddress,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        hintText: 'Select Address',
                      ),
                      items: _addresses.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<DocumentSnapshot>(
                          value: doc,
                          child: Text('${data['addressType']}: ${data['line1']}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedAddress = value),
                    ),
                  ),
                ),
                if (!_isEditMode) ...[
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => AddAddress()));
                          setState(() { _selectedAddress = null; _isLoadingAddresses = true; });
                          _fetchAddresses();
                        },
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Add New', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
                      ),
                      TextButton.icon(
                        onPressed: () => _navigateAndRefresh(context),
                        icon: Icon(Icons.settings, size: 18),
                        label: Text('Manage', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ==== Date & Time ====
          _buildSection(
            icon: Icons.calendar_month,
            title: "date_time".tr(),
            child: AbsorbPointer(
              absorbing: _isEditMode,
              child: Opacity(
                opacity: _isEditMode ? 0.6 : 1.0,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: dateController,
                        decoration: InputDecoration(
                          labelText: "Select Date",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          suffixIcon: Icon(Icons.calendar_today, color: kPrimaryColor),
                        ),
                        readOnly: true,
                        onTap: _isEditMode ? null : _selectDate,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: _selectedTimeSlot),
                        decoration: InputDecoration(
                          labelText: "Select Time",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          suffixIcon: Icon(Icons.access_time_filled, color: kPrimaryColor),
                        ),
                        onTap: _isEditMode ? null : () => showCustomPopup(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==== Scrap Items ====
          _buildSection(
            icon: Icons.recycling,
            title: "select_scraps".tr(),
            child: _isLoadingPrices
                ? Center(child: CircularProgressIndicator())
                : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categoryIds.map((categoryId) {
                String categoryName =
_availableCategories[categoryId]?['name']
?? 'Unknown';

switch (categoryName) {

  case 'Plastic':
    categoryName =
        'plastic'.tr();
    break;

  case 'Paper':
    categoryName =
        'paper'.tr();
    break;

  case 'Glass':
    categoryName =
        'glass'.tr();
    break;

  case 'Metals':
    categoryName =
        'metals'.tr();
    break;

  case 'E-waste':
    categoryName =
        'ewaste'.tr();
    break;
}
                bool categoryHasSelection = _selectedItems.any((item) => item.categoryId == categoryId);
                return ChoiceChip(
                  label: Text(categoryName),
                  labelStyle: TextStyle(
                    color: categoryHasSelection ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  selected: categoryHasSelection,
                  selectedColor: kPrimaryColor,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: categoryHasSelection ? kPrimaryColor : Colors.grey.shade300)
                  ),
                  onSelected: (bool _) => _showItemSelectionPopup(context, categoryId),
                );
              }).toList(),
            ),
          ),

          // ==== Pickup Summary ====
          _buildSection(
            icon: Icons.receipt_long,
            title: "pickup_summary".tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedAddress != null) ...[
                  Row(children: [Icon(Icons.place, size: 16, color: Colors.grey), SizedBox(width: 5), Text("Address", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]))]),
                  Padding(
                    padding: const EdgeInsets.only(left: 21.0, top: 4, bottom: 12),
                    child: Text('${(_selectedAddress!.data() as Map<String, dynamic>)['line1'] ?? ''}', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ],

                if (_selectedItems.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text('No items added yet.', style: TextStyle(color: Colors.grey.shade500))))
                else
                  ..._selectedItems.map((item) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.categoryName} - ${item.itemName}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('${item.displayAmount} ${item.unit}  •  ${currencyFormatter.format(item.calculatedCost)}', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          // ✅ CEVUS: Soft Delete Button
                          InkWell(
                            onTap: () { setState(() { _selectedItems.removeWhere((i) => i.itemId == item.itemId); }); _updateTotals(); },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                if (_selectedItems.isNotEmpty) ...[
                  Divider(height: 30),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Estimated Weight:', style: TextStyle(color: Colors.grey[600])), Text('${_totalEstimatedWeight.toStringAsFixed(1)} kg', style: TextStyle(fontWeight: FontWeight.bold))]),
                  SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Estimated Value:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor)), Text(currencyFormatter.format(_totalEstimatedCost), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kAccentColor))]),
                ],
              ],
            ),
          ),

          // ==== Description ====
          _buildSection(
            icon: Icons.edit_note,
            title: "description_optional".tr(),
            child: TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Any special instructions...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
         Padding(

  padding: const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 10,
  ),

  child: Container(

    padding: const EdgeInsets.all(14),

    decoration: BoxDecoration(

      color: Colors.orange.withAlpha(15),

      borderRadius:
          BorderRadius.circular(16),

      border: Border.all(
        color:
            Colors.orange.withAlpha(40),
      ),
    ),

    child: Row(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        const Icon(
          Icons.info_outline_rounded,
          color: Colors.orange,
          size: 20,
        ),

        const SizedBox(width: 10),

       Expanded(

  child: Text(

    "estimated_cost_note".tr(),

    style: TextStyle(
      fontSize: 12,
      height: 1.5,
      color: Colors.orange.shade900,
      fontWeight: FontWeight.w600,
    ),
  ),
),
      ],
    ),
  ),
),

          // ==== Submit Button ====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPickup,
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                foregroundColor: kPrimaryColor,
                minimumSize: Size(double.infinity, 60),
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? CircularProgressIndicator(color: kPrimaryColor)
                  : Text(_isEditMode ? 'Update Pickup' : 'Schedule Pickup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),

          // ✅ CEVUS: Bottom Padding for Nav Bar
          SizedBox(height: 120),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPickupData) {
      if (widget.isTab) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
      return Scaffold(backgroundColor: kCreamColor, appBar: _buildAppBar(), body: const Center(child: CircularProgressIndicator(color: kPrimaryColor)));
    }
    final bodyContent = _buildBody();
    if (widget.isTab) return bodyContent;
    return Scaffold(backgroundColor: kCreamColor, appBar: _buildAppBar(), body: bodyContent);
  }
}