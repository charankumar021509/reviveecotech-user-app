import 'package:flutter/material.dart';

// ==== Constants ====
const kPrimaryColor = Color(0xFF013D5A);
const kCreamColor = Color(0xFFFCF3E3);
const kAccentColor = Color(0xFFA6CB4E);

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  // ✅ CEVUS: Data separated from UI.
  // These are sensible questions for a user who is ALREADY logged in.
  final List<Map<String, String>> _faqs = [
    {
      "question": "How are scrap prices decided?",
      "answer": "Our prices are updated daily based on the current market rates for recyclable materials. You can check the 'Price List' section on the Home page for the latest rates per kilogram."
    },
    {
      "question": "When do I get paid?",
      "answer": "Payments are processed instantly after the pickup is completed and the final weight is verified by our agent. You can choose to receive payment via UPI, Bank Transfer, or Cash."
    },
    {
      "question": "Can I reschedule or cancel a pickup?",
      "answer": "Yes. Use the 'Pickup Tracker' or History page to 'Edit' or 'Cancel' your request. Note: Cancellations are restricted once an agent is 'Out for Pickup' to avoid logistics waste. If you cancel early, there are zero penalties."
    },
    {
      "question": "Is there a minimum weight requirement?",
      "answer": "To make the pickup efficient, we recommend a minimum of 10kg of mixed scrap. However, for smaller quantities, you can combine multiple categories (Paper, Plastic, Metal) to reach a viable amount."
    },
    {
      "question": "What happens to my recycled items?",
      "answer": "We collect, sort, and send materials directly to certified recycling plants. Your paper becomes new cardboard, plastic bottles become polyester fiber, and metals are melted down for reuse. Zero waste to landfill is our goal!"
    },
    {
      "question": "My pickup agent hasn't arrived yet.",
      "answer": "Agents may be delayed due to traffic or heavy loads from previous stops. Please check the 'Pickup Tracker' status. If it's significantly delayed, you can contact Support directly via the 'Help & Support' page."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      // Premium Curved AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          centerTitle: true,
          toolbarHeight: 70,
          title: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'FAQs',
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
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return _buildFaqTile(faq['question']!, faq['answer']!);
        },
      ),
    );
  }

  // Refined Tile Styling
  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Remove the default divider lines from ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: kAccentColor,
          collapsedIconColor: Colors.grey.shade400,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
              height: 1.3,
            ),
          ),
          children: [
            // Divider inside for clean separation
            Divider(height: 20, color: Colors.grey.shade100),
            Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}