class LanguageService {

  static String currentLanguage = 'en';

  static final Map<String, Map<String, String>>
      translations = {

    'en': {

      'home': 'Home',
      'history': 'History',
      'earned': 'Earned',
      'schedulePickup':
          'Schedule Pickup',
    },

    'hi': {

      'home': 'होम',
      'history': 'इतिहास',
      'earned': 'कमाई',
      'schedulePickup':
          'पिकअप बुक करें',
    },

    'te': {

      'home': 'హోమ్',
      'history': 'చరిత్ర',
      'earned': 'ఆదాయం',
      'schedulePickup':
          'పికప్ బుక్ చేయండి',
    },
  };

  static String text(String key) {

    return translations[
      currentLanguage
    ]?[key] ?? key;
  }
}