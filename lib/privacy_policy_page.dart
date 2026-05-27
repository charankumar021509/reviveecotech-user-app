import 'package:flutter/material.dart';

// ==== Constants ====
const kPrimaryColor = Color(0xFF013D5A);
const kCreamColor = Color(0xFFFCF3E3);
const kAccentColor = Color(0xFFA6CB4E);

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  // ✅ Helper: Styled Card for each section
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Helper: Sub-heading
  Widget _buildSubHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: kPrimaryColor.withOpacity(0.8),
        ),
      ),
    );
  }

  // ✅ Helper: Standard Paragraph
  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.grey.shade800,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  // ✅ Helper: Bullet Point (with nesting support)
  Widget _buildBulletPoint(String text, {bool isSubBullet = false, String? boldPrefix}) {
    return Padding(
      padding: EdgeInsets.only(left: isSubBullet ? 16.0 : 0.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Icon(
              isSubBullet ? Icons.remove : Icons.circle,
              size: isSubBullet ? 6 : 8,
              color: kAccentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
                children: [
                  if (boldPrefix != null)
                    TextSpan(
                      text: "$boldPrefix ",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamColor,
      // ✅ CEVUS: Premium Curved AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          centerTitle: true,
          toolbarHeight: 70,
          title: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Privacy Policy',
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
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Intro ---
              const Center(
                child: Text(
                  "Last updated: August 18, 2025",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: "Introduction",
                children: [
                  _buildParagraph(
                    "This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use the Service and tells You about Your privacy rights and how the law protects You.",
                  ),
                  _buildParagraph(
                    "We use Your Personal data to provide and improve the Service. By using the Service, You agree to the collection and use of information in accordance with this Privacy Policy.",
                  ),
                ],
              ),

              // --- Definitions ---
              _buildSectionCard(
                title: "Interpretation and Definitions",
                children: [
                  _buildSubHeading("Definitions"),
                  _buildParagraph("For the purposes of this Privacy Policy:"),
                  _buildBulletPoint("means a unique account created for You to access our Service.", boldPrefix: "Account"),
                  _buildBulletPoint("means an entity that controls, is controlled by or is under common control with a party.", boldPrefix: "Affiliate"),
                  _buildBulletPoint("(referred to as either \"the Company\", \"We\", \"Us\" or \"Our\" in this Agreement) refers to Revive eco tech pvt ltd, 7-62, Saraswathiguda, Kandukur, Rangareddy.", boldPrefix: "Company"),
                  _buildBulletPoint("are small files that are placed on Your computer, mobile device or any other device by a website.", boldPrefix: "Cookies"),
                  _buildBulletPoint("refers to: Telangana, India.", boldPrefix: "Country"),
                  _buildBulletPoint("means any device that can access the Service such as a computer, a cellphone or a digital tablet.", boldPrefix: "Device"),
                  _buildBulletPoint("is any information that relates to an identified or identifiable individual.", boldPrefix: "Personal Data"),
                  _buildBulletPoint("refers to the Website/App.", boldPrefix: "Service"),
                  _buildBulletPoint("means any natural or legal person who processes the data on behalf of the Company.", boldPrefix: "Service Provider"),
                  _buildBulletPoint("refers to data collected automatically (e.g., duration of page visit).", boldPrefix: "Usage Data"),
                  _buildBulletPoint("means the individual accessing or using the Service.", boldPrefix: "You"),
                ],
              ),

              // --- Data Collection ---
              _buildSectionCard(
                title: "Collecting Your Personal Data",
                children: [
                  _buildSubHeading("Types of Data Collected"),
                  _buildParagraph("While using Our Service, We may ask You to provide Us with certain personally identifiable information that can be used to contact or identify You. This may include:"),
                  _buildBulletPoint("Email address", isSubBullet: true),
                  _buildBulletPoint("First name and last name", isSubBullet: true),
                  _buildBulletPoint("Phone number", isSubBullet: true),
                  _buildBulletPoint("Address, State, Province, ZIP/Postal code, City", isSubBullet: true),
                  _buildBulletPoint("Usage Data", isSubBullet: true),

                  _buildSubHeading("Usage Data"),
                  _buildParagraph("Usage Data is collected automatically when using the Service. It may include Your Device's IP address, browser type, pages visited, time spent, and unique device identifiers."),
                  _buildParagraph("When You access the Service by or through a mobile device, We may collect information including, but not limited to, the type of mobile device You use, Your mobile device unique ID, the IP address of Your mobile device, Your mobile operating system, and other diagnostic data."),
                ],
              ),

              // --- Cookies ---
              _buildSectionCard(
                title: "Tracking Technologies and Cookies",
                children: [
                  _buildParagraph("We use Cookies and similar tracking technologies to track the activity on Our Service and store certain information."),
                  _buildSubHeading("Types of Cookies We Use:"),
                  _buildBulletPoint("Necessary / Essential Cookies (Session)"),
                  _buildParagraph("These are essential to provide You with services available through the Website and to authenticate users."),
                  _buildBulletPoint("Functionality Cookies (Persistent)"),
                  _buildParagraph("These allow us to remember choices You make, such as login details or language preference."),
                ],
              ),

              // --- Use of Data ---
              _buildSectionCard(
                title: "Use of Your Personal Data",
                children: [
                  _buildParagraph("The Company may use Personal Data for the following purposes:"),
                  _buildBulletPoint("To provide and maintain our Service."),
                  _buildBulletPoint("To manage Your Account."),
                  _buildBulletPoint("For the performance of a contract (purchases/services)."),
                  _buildBulletPoint("To contact You regarding updates or informative communications."),
                  _buildBulletPoint("To provide You with news and special offers."),
                  _buildBulletPoint("To manage Your requests."),
                ],
              ),

              // --- Sharing Data ---
              _buildSectionCard(
                title: "Sharing Your Personal Data",
                children: [
                  _buildParagraph("We may share Your personal information in the following situations:"),
                  _buildBulletPoint("With Service Providers (to monitor/analyze service)."),
                  _buildBulletPoint("For business transfers (mergers/acquisitions)."),
                  _buildBulletPoint("With Affiliates and Business Partners."),
                  _buildBulletPoint("With Your consent."),
                ],
              ),

              // --- Retention & Transfer ---
              _buildSectionCard(
                title: "Retention & Transfer",
                children: [
                  _buildParagraph("The Company will retain Your Personal Data only for as long as is necessary for the purposes set out in this Privacy Policy."),
                  _buildParagraph("Your information, including Personal Data, is processed at the Company's operating offices and may be transferred to computers located outside of Your state or country. Your submission of such information represents Your agreement to that transfer."),
                ],
              ),

              // --- Disclosure ---
              _buildSectionCard(
                title: "Disclosure of Data",
                children: [
                  _buildSubHeading("Business Transactions"),
                  _buildParagraph("If the Company is involved in a merger, acquisition or asset sale, Your Personal Data may be transferred."),
                  _buildSubHeading("Law Enforcement"),
                  _buildParagraph("The Company may be required to disclose Your Personal Data if required to do so by law or in response to valid requests by public authorities."),
                ],
              ),

              // --- Security ---
              _buildSectionCard(
                title: "Security",
                children: [
                  _buildParagraph("The security of Your Personal Data is important to Us, but remember that no method of transmission over the Internet is 100% secure. While We strive to use commercially acceptable means to protect Your Personal Data, We cannot guarantee its absolute security."),
                ],
              ),

              // --- Children ---
              _buildSectionCard(
                title: "Children's Privacy",
                children: [
                  _buildParagraph(
                      "Our Service does not address anyone under the age of 18. We do not knowingly collect personally identifiable information from anyone under the age of 18. If You are a parent or guardian and You are aware that Your child has provided Us with Personal Data, please contact Us."
                  ),
                  _buildParagraph(
                      "If We become aware that We have collected Personal Data from anyone under the age of 18 without verification of parental consent, We take steps to remove that information from Our servers."
                  ),
                ],
              ),

              // --- Contact ---
              _buildSectionCard(
                title: "Contact Us",
                children: [
                  _buildParagraph("If you have any questions about this Privacy Policy, You can contact us:"),
                  _buildBulletPoint("reviveecotech@gmail.com", boldPrefix: "Email:"),
                  _buildBulletPoint("6304218355", boldPrefix: "Phone:"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}