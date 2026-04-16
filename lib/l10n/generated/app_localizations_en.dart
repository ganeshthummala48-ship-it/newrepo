// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FarmerAI';

  @override
  String get welcome => 'Welcome to FarmerAI! 🌾';

  @override
  String get welcomeSubtitle =>
      'Tell us about yourself so we can personalize your experience.';

  @override
  String get updateProfile => 'Update your farming details';

  @override
  String get myProfile => 'My Profile';

  @override
  String get yourName => 'Your Name';

  @override
  String get enterName => 'Enter your name';

  @override
  String get nameError => 'Please enter your name';

  @override
  String get yourState => 'Your State';

  @override
  String get primaryCrop => 'Primary Crop';

  @override
  String get landSize => 'Land Size (Hectares)';

  @override
  String get letsGetStarted => 'Let\'s Get Started';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get cancel => 'Cancel';

  @override
  String get profileSaved => 'Profile saved! ✅';

  @override
  String hello(String name) {
    return 'Hello, $name! 👋';
  }

  @override
  String get helloFarmer => 'Hello, Farmer! 👋';

  @override
  String get whatsToday => 'What would you like to do today?';

  @override
  String get machinerySupport => 'Machinery Support';

  @override
  String get machinerySubtitle => 'Tractors, Harvesters & More';

  @override
  String get labourCoordination => 'Labour Coordination';

  @override
  String get labourSubtitle => 'Find & Manage Workers';

  @override
  String get negotiate => 'Negotiate';

  @override
  String get language => 'Language';

  @override
  String get cropRecommendation => 'Crop Recommendation';

  @override
  String get marketPrices => 'Market Prices';

  @override
  String get diseaseDetection => 'Disease Detection';

  @override
  String get predictionHistory => 'Prediction History';

  @override
  String get askFarmerAI => 'Ask FarmerAI';

  @override
  String get yieldAndProfit => 'Yield & Profit';

  @override
  String get govtSchemes => 'Govt Schemes';

  @override
  String get riskAlerts => 'Risk Alerts';

  @override
  String get bookSupplies => 'Book Supplies';

  @override
  String get farmersCommunity => 'Farmers Community';

  @override
  String get farmMap => 'Farm Map';

  @override
  String get cropCalendar => 'Crop Calendar';

  @override
  String get fertilizers => 'Fertilizers';

  @override
  String get irrigation => 'Irrigation';

  @override
  String get logistics => 'Logistics';

  @override
  String get all => 'All';

  @override
  String get browseServices => 'Browse Services';

  @override
  String get myRequests => 'My Requests';

  @override
  String get locateFertilizer => 'Locate Fertilizer Points';

  @override
  String get machinery => 'Machinery';

  @override
  String get labour => 'Labour';

  @override
  String get requests => 'Requests';

  @override
  String get addService => 'Add Service';

  @override
  String get registerService => 'Register Service';

  @override
  String get stock => 'Stock';

  @override
  String get composition => 'Composition';

  @override
  String get model => 'Model';

  @override
  String get hp => 'Horsepower';

  @override
  String get offer => 'Offer';

  @override
  String get from => 'From';

  @override
  String get statusLabel => 'Status';

  @override
  String get reject => 'Reject';

  @override
  String get acceptOffer => 'Accept Offer';

  @override
  String get contractsAndServices => 'Contracts &\nServices';

  @override
  String get contractsSubtitle => 'Machinery, Labour, & more';

  @override
  String get diseaseGuide => 'Disease\nGuide';

  @override
  String get contractorDashboard => 'Contractor Dashboard';

  @override
  String get settings => 'Settings';

  @override
  String get register => 'Register';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get preferredLanguage => 'Preferred Language';

  @override
  String get selectRole => 'Select your role:';

  @override
  String get farmer => 'Farmer';

  @override
  String get contractor => 'Contractor';

  @override
  String get registrationSuccess => 'Registration successful! Please login.';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get login => 'Login';

  @override
  String get noAccount => 'Don\'t have an account? Register';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get errorConnecting => 'Error connecting to backend';

  @override
  String get governmentSchemes => 'Government Schemes';

  @override
  String get detectingState => 'Detecting your state...';

  @override
  String autoDetected(String state) {
    return 'Auto-detected: $state';
  }

  @override
  String get subsidiesForFarmers =>
      'Subsidies, loans & support for Indian farmers';

  @override
  String get state => 'State';

  @override
  String get cropType => 'Crop Type';

  @override
  String get searching => 'Searching...';

  @override
  String get findSchemes => 'Find Schemes';

  @override
  String get quickSelectState => 'Quick Select State:';

  @override
  String schemesFor(String state, String crop) {
    return 'Schemes for $state - $crop';
  }

  @override
  String get kvkInfo =>
      'For official details, contact your local Krishi Vigyan Kendra (KVK) or visit PM-KISAN portal.';

  @override
  String get locationMode => 'Location Mode';

  @override
  String get detectingLocation => 'Detecting location...';

  @override
  String get analyze => 'Analyze';

  @override
  String get fetchingData => 'Fetching real-time data...';

  @override
  String get analyzingRisks => 'Analyzing your risks...';

  @override
  String get riskAnalysis => 'FarmerAI Risk Analysis';

  @override
  String get liveWeather => 'Live Weather';

  @override
  String get noActiveAlerts => 'No active severe weather alerts in your area.';

  @override
  String get pollenPestRisk => 'Pollen & Pest Risk';

  @override
  String get uploadLeafHint =>
      'Upload a clear picture of the affected crop leaf to detect diseases instantly.';

  @override
  String get selectImageHint => 'Tap buttons below to select image';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get analyzeLeaf => 'Analyze Leaf';

  @override
  String get browseGuide => 'Browse Disease Guide';

  @override
  String get farmConditions => 'Farm Conditions';

  @override
  String get soilType => 'Soil Type';

  @override
  String get season => 'Season';

  @override
  String get rainfallLevel => 'Rainfall Level';

  @override
  String get getRecommendation => 'Get Recommendation';

  @override
  String get farmDetails =>
      'Provide your farm details to get AI-powered crop recommendations tailored to your conditions.';

  @override
  String get realTimeMarket => 'Real-time Market & Weather';

  @override
  String get search => 'Search';

  @override
  String get bestPrice => 'Best Price Recommendation';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get tapToCall => 'Tap to Call';

  @override
  String get noMachinery => 'No machinery available.';

  @override
  String get submitOffer => 'Submit Offer';

  @override
  String get yourOffer => 'Your Offer';

  @override
  String get notes => 'Notes';

  @override
  String get price => 'Price';

  @override
  String get offerSent => 'Offer sent!';

  @override
  String get selectImage => 'Please select an image first';

  @override
  String get serverError => 'Server Error';

  @override
  String get connectionError =>
      'Failed to connect to the server. Please check your connection.';

  @override
  String get refresh => 'Refresh';

  @override
  String get phoneHint => 'e.g. 9876543210';

  @override
  String get loading => 'Loading...';

  @override
  String get analysisResult => 'Analysis Result';

  @override
  String get cropDiseasePrediction => '🌿 Crop Disease Prediction';

  @override
  String get detectedDisease => 'Detected Disease';

  @override
  String get predictionConfidence => 'Prediction Confidence';

  @override
  String get recommendedAction => 'Recommended Action';

  @override
  String get treatmentPlan => 'Treatment Plan';

  @override
  String get aiAdvice => 'AI Expert Advice';

  @override
  String get aiNotes =>
      'ℹ️ Note:\\nThis prediction is generated using an AI model. Pesticide usage should follow government-approved guidelines. For severe cases, consult an agricultural expert.';

  @override
  String get analyzeAnother => 'Analyze Another Image';

  @override
  String get yieldPredictor => 'Yield & Profit Predictor';

  @override
  String get calculate => 'Calculate';

  @override
  String get noLabour => 'No labour groups found.';

  @override
  String get negotiateOffer => 'Send Offer & Negotiate';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get requestSent => 'Request sent!';

  @override
  String get dialerError => 'Could not launch dialer';

  @override
  String get directions => 'Directions';

  @override
  String get callNow => 'Call Now';

  @override
  String get fertilizerPoints => 'Fertilizer Points';

  @override
  String get retry => 'Retry';

  @override
  String get fertilizerSupport => 'Fertilizer Support';

  @override
  String get bookNow => 'Book Now';

  @override
  String get processingBooking => 'Processing your booking...';

  @override
  String get bookingConfirmed => 'Booking Confirmed';

  @override
  String get ok => 'OK';

  @override
  String get diseaseGuideTitle => 'Disease Guide';

  @override
  String get noDiseases => 'No diseases found.';

  @override
  String get detailedAdvice => 'Get Detailed AI Advice';

  @override
  String get topCrops => 'Top Recommended Crops';

  @override
  String get cropCalendarTitle => 'Crop Calendar';

  @override
  String get generateCalendar => 'Generate Calendar';

  @override
  String get namasteAI => 'Namaste! I am your FarmerAI.';

  @override
  String get askAnything =>
      'Select your language and ask me anything about farming.';

  @override
  String askIn(String lang) {
    return 'Ask in $lang...';
  }

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get addedToCart => 'Added item to cart!';

  @override
  String get cropHealth => 'Crop Health';

  @override
  String get cropInsights => 'Crop Insights';

  @override
  String get realTimeRates => 'Real-time rates';

  @override
  String get revenueEstimates => 'Revenue estimates';

  @override
  String get satelliteMonitoring => 'Satellite monitoring';

  @override
  String get financialSupport => 'Financial support';

  @override
  String get expertChat => '24/7 Expert Chat';

  @override
  String get weatherWarnings => 'Weather warnings';

  @override
  String get localDiscussions => 'Local discussions';

  @override
  String get recommendationCalendar => 'Recommendation & Calendar';

  @override
  String get searchMachinery => 'Search machinery...';

  @override
  String machinesAvailable(int count) {
    return '$count machines available';
  }

  @override
  String get clearFilter => 'Clear Filter';

  @override
  String get listedPrice => 'Listed Price';

  @override
  String get specifications => 'Specifications';

  @override
  String get callText => 'Call';

  @override
  String get sendOfferNegotiate => 'Send Offer & Negotiate';

  @override
  String get noContractorsFound => 'No contractors found for this category.';

  @override
  String get getAiFertilizerAdvice => 'Get AI Fertilizer Advice';

  @override
  String get allDistricts => 'All Districts';

  @override
  String get selectDistrict => 'Select District';

  @override
  String get noDataAvailable => 'No Data Available';

  @override
  String get refreshAnalysis => 'Refresh Analysis';

  @override
  String get openNow => 'Open Now';

  @override
  String get closedNow => 'Closed';

  @override
  String get fertilizerShops => 'Fertilizer Shops';

  @override
  String get searchShops => 'Search Shops';

  @override
  String get listView => 'List View';

  @override
  String get mapView => 'Map View';

  @override
  String get stopVoice => 'Stop';

  @override
  String get commandVoice => 'Command';

  @override
  String get listenVoice => 'Listen';

  @override
  String get homeDashboard => 'Home Dashboard';

  @override
  String get tryDifferentFilter => 'Try a different filter or search term';

  @override
  String get noRequestsYet => 'You have not sent any requests yet.';

  @override
  String messageContractor(String name) {
    return 'Message $name';
  }

  @override
  String discussing(String title) {
    return 'Discussing: $title';
  }

  @override
  String get yourPriceOffer => 'Your Price Offer (₹)';

  @override
  String get messageSpecialReq => 'Message / Special Requirements';

  @override
  String get sendOffer => 'Send Offer';

  @override
  String get offerSentToContractor => 'Offer sent to contractor!';

  @override
  String get enterCropForAdvice =>
      'Enter the crop you want recommendations for:';

  @override
  String get aiFertilizerExpert => 'AI Fertilizer Expert';

  @override
  String get getAdvice => 'Get Advice';

  @override
  String get cropHintExample => 'e.g. Paddy, Maize, Tomato';

  @override
  String get contactNumber => 'Contact Number';

  @override
  String get priceRate => 'Price / Rate';

  @override
  String get description => 'Description';

  @override
  String get teamSize => 'Team Size';

  @override
  String get specialty => 'Specialty';

  @override
  String get expectedYield => 'Expected Yield';

  @override
  String get expectedMarketPrice => 'Expected Market Price per Ton';

  @override
  String get totalCultivationCost => 'Total Cultivation Cost';

  @override
  String get contactForPrice => 'Contact for price';

  @override
  String get noDescription => 'No description provided.';

  @override
  String get noContactInfo => 'No contact info';

  @override
  String get tapToCallAction => 'Tap to call';
}
