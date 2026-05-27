import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

// ==== Constants ====
const kPrimaryColor = Color(0xFF013D5A);
const kPrimaryLight = Color(0xFF025075); // Slightly lighter for gradient
const kCreamColor = Color(0xFFFCF3E3);
const kAccentColor = Color(0xFFA6CB4E);

class pricelist extends StatefulWidget {
  const pricelist({super.key});

  @override
  State<pricelist> createState() => _pricelistState();
}

class _pricelistState extends State<pricelist> {
  final Stream<QuerySnapshot> _categoriesStream = FirebaseFirestore.instance
      .collection('price_list')
      .orderBy('order')
      .snapshots();

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('paper') || name.contains('book')) return Icons.menu_book_rounded;
    if (name.contains('plastic') || name.contains('bottle')) return Icons.local_drink_rounded;
    if (name.contains('metal') || name.contains('iron')) return Icons.build_circle_outlined;
    if (name.contains('e-waste') || name.contains('electronic')) return Icons.phonelink_setup_rounded;
    if (name.contains('glass')) return Icons.wine_bar_rounded;
    if (name.contains('cloth')) return Icons.checkroom_rounded;
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      // ✅ FIX: Flat AppBar that merges with the body
      appBar: AppBar(
        centerTitle: true,
       title: Text(
  'price_list'.tr(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'RedHatDisplay',
            color: kCreamColor,
          ),
        ),
        backgroundColor: kPrimaryColor, // Matches the container below
        elevation: 0, // Removes shadow line
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kCreamColor),
        ),
      ),

      body: Column(
        children: [
          // ✅ FIX: Seamless Header Container
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              // Gradient makes it look premium
              gradient: LinearGradient(
                colors: [kPrimaryColor, kPrimaryLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 30), // Top padding 0 to touch AppBar
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.currency_rupee_rounded, color: kPrimaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(

  "current_market_rates".tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                       Text(
  "market_rates_note".tr(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ The List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _categoriesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error loading prices', style: TextStyle(color: Colors.grey[600])));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off_rounded, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text("No prices available", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final categoryDoc = snapshot.data!.docs[index];
                    final categoryData = categoryDoc.data()! as Map<String, dynamic>;
                    final categoryName = categoryData['name'] ?? 'Unnamed';

                    return _buildCategoryCard(categoryDoc, categoryName);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Category Card (Accordion)
  Widget _buildCategoryCard(DocumentSnapshot categoryDoc, String categoryName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kCreamColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(categoryName),
              color: kPrimaryColor,
              size: 26,
            ),
          ),
          title: Text(
            categoryName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          children: [
            // Nested StreamBuilder for Items
            StreamBuilder<QuerySnapshot>(
              stream: categoryDoc.reference.collection('items').orderBy('order').snapshots(),
              builder: (context, itemSnapshot) {
                if (itemSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor))),
                  );
                }
                if (!itemSnapshot.hasData || itemSnapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Coming soon...", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
                  );
                }

                var items = itemSnapshot.data!.docs;
                return Column(
                  children: List.generate(items.length, (index) {
                    final itemData = items[index].data()! as Map<String, dynamic>;
                    final bool isEven = index % 2 == 0;
                    return _buildPriceRow(itemData, isEven);
                  }),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

 // ✅ Price Row Item
Widget _buildPriceRow(
    Map<String, dynamic> itemData,
    bool isEven,
) {

  final double price =
      (itemData['price'] as num?)
          ?.toDouble() ?? 0.0;

  return Container(

    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 14,
    ),

    decoration: BoxDecoration(
      color: isEven
          ? const Color(0xFFF8F9FA)
          : Colors.white,
    ),

    child: Row(

      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [

        Expanded(

          child: Text(

            _translateCategoryName(
              itemData['name'] ?? 'Unnamed',
            ),

            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),

        Row(

          crossAxisAlignment:
              CrossAxisAlignment.baseline,

          textBaseline:
              TextBaseline.alphabetic,

          children: [

            Text(

              "₹$price",

              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),

            const SizedBox(width: 4),

            Text(

              "/${itemData['unit'] ?? 'unit'}",

              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ✅ Translate Category Name
String _translateCategoryName(
    String categoryName) {

  final lowerName =
      categoryName.toLowerCase();

  // Plastic
  if (

      lowerName.contains('plastic') ||

      lowerName.contains('pet') ||

      lowerName.contains('bottle')

  ) {

    return 'plastic'.tr();
  }

  // Paper
  else if (

      lowerName.contains('paper') ||

      lowerName.contains('book') ||

      lowerName.contains('newspaper')

  ) {

    return 'paper'.tr();
  }

  // Glass
  else if (
      lowerName.contains('glass')) {

    return 'glass'.tr();
  }

  // Metals
  else if (

      lowerName.contains('metal') ||

      lowerName.contains('iron') ||

      lowerName.contains('steel')

  ) {

    return 'metals'.tr();
  }

  // E-Waste
  else if (

      lowerName.contains('waste') ||

      lowerName.contains('electronic') ||

      lowerName.contains('ewaste') ||

      lowerName.contains('e-waste')

  ) {

    return 'ewaste'.tr();
  }

  return categoryName;
}
}