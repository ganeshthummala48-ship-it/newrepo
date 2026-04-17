import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('or'),
    Locale('pa'),
    Locale('ta'),
    Locale('te')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AgriNova'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AgriNova! 🌾'**
  String get welcome;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself so we can personalize your experience.'**
  String get welcomeSubtitle;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update your farming details'**
  String get updateProfile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @nameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameError;

  /// No description provided for @yourState.
  ///
  /// In en, this message translates to:
  /// **'Your State'**
  String get yourState;

  /// No description provided for @primaryCrop.
  ///
  /// In en, this message translates to:
  /// **'Primary Crop'**
  String get primaryCrop;

  /// No description provided for @landSize.
  ///
  /// In en, this message translates to:
  /// **'Land Size (Hectares)'**
  String get landSize;

  /// No description provided for @letsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Get Started'**
  String get letsGetStarted;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved! ✅'**
  String get profileSaved;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}! 👋'**
  String hello(String name);

  /// No description provided for @helloFarmer.
  ///
  /// In en, this message translates to:
  /// **'Hello, Farmer! 👋'**
  String get helloFarmer;

  /// No description provided for @whatsToday.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do today?'**
  String get whatsToday;

  /// No description provided for @machinerySupport.
  ///
  /// In en, this message translates to:
  /// **'Machinery Support'**
  String get machinerySupport;

  /// No description provided for @machinerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tractors, Harvesters & More'**
  String get machinerySubtitle;

  /// No description provided for @labourCoordination.
  ///
  /// In en, this message translates to:
  /// **'Labour Coordination'**
  String get labourCoordination;

  /// No description provided for @labourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find & Manage Workers'**
  String get labourSubtitle;

  /// No description provided for @negotiate.
  ///
  /// In en, this message translates to:
  /// **'Negotiate'**
  String get negotiate;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @cropRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Crop Recommendation'**
  String get cropRecommendation;

  /// No description provided for @marketPrices.
  ///
  /// In en, this message translates to:
  /// **'Market Prices'**
  String get marketPrices;

  /// No description provided for @diseaseDetection.
  ///
  /// In en, this message translates to:
  /// **'Disease Detection'**
  String get diseaseDetection;

  /// No description provided for @predictionHistory.
  ///
  /// In en, this message translates to:
  /// **'Prediction History'**
  String get predictionHistory;

  /// No description provided for @askFarmerAI.
  ///
  /// In en, this message translates to:
  /// **'Ask AgriNova'**
  String get askFarmerAI;

  /// No description provided for @yieldAndProfit.
  ///
  /// In en, this message translates to:
  /// **'Yield & Profit'**
  String get yieldAndProfit;

  /// No description provided for @govtSchemes.
  ///
  /// In en, this message translates to:
  /// **'Govt Schemes'**
  String get govtSchemes;

  /// No description provided for @riskAlerts.
  ///
  /// In en, this message translates to:
  /// **'Risk Alerts'**
  String get riskAlerts;

  /// No description provided for @bookSupplies.
  ///
  /// In en, this message translates to:
  /// **'Book Supplies'**
  String get bookSupplies;

  /// No description provided for @farmersCommunity.
  ///
  /// In en, this message translates to:
  /// **'Farmers Community'**
  String get farmersCommunity;

  /// No description provided for @farmMap.
  ///
  /// In en, this message translates to:
  /// **'Farm Map'**
  String get farmMap;

  /// No description provided for @cropCalendar.
  ///
  /// In en, this message translates to:
  /// **'Crop Calendar'**
  String get cropCalendar;

  /// No description provided for @fertilizers.
  ///
  /// In en, this message translates to:
  /// **'Fertilizers'**
  String get fertilizers;

  /// No description provided for @irrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get irrigation;

  /// No description provided for @logistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get logistics;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @browseServices.
  ///
  /// In en, this message translates to:
  /// **'Browse Services'**
  String get browseServices;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @locateFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Locate Fertilizer Points'**
  String get locateFertilizer;

  /// No description provided for @machinery.
  ///
  /// In en, this message translates to:
  /// **'Machinery'**
  String get machinery;

  /// No description provided for @labour.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get labour;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @registerService.
  ///
  /// In en, this message translates to:
  /// **'Register Service'**
  String get registerService;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @composition.
  ///
  /// In en, this message translates to:
  /// **'Composition'**
  String get composition;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @hp.
  ///
  /// In en, this message translates to:
  /// **'Horsepower'**
  String get hp;

  /// No description provided for @offer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get offer;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @acceptOffer.
  ///
  /// In en, this message translates to:
  /// **'Accept Offer'**
  String get acceptOffer;

  /// No description provided for @contractsAndServices.
  ///
  /// In en, this message translates to:
  /// **'Contracts &\nServices'**
  String get contractsAndServices;

  /// No description provided for @contractsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Machinery, Labour, & more'**
  String get contractsSubtitle;

  /// No description provided for @diseaseGuide.
  ///
  /// In en, this message translates to:
  /// **'Disease\nGuide'**
  String get diseaseGuide;

  /// No description provided for @contractorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Contractor Dashboard'**
  String get contractorDashboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role:'**
  String get selectRole;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @contractor.
  ///
  /// In en, this message translates to:
  /// **'Contractor'**
  String get contractor;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please login.'**
  String get registrationSuccess;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccount;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @errorConnecting.
  ///
  /// In en, this message translates to:
  /// **'Error connecting to backend'**
  String get errorConnecting;

  /// No description provided for @governmentSchemes.
  ///
  /// In en, this message translates to:
  /// **'Government Schemes'**
  String get governmentSchemes;

  /// No description provided for @detectingState.
  ///
  /// In en, this message translates to:
  /// **'Detecting your state...'**
  String get detectingState;

  /// No description provided for @autoDetected.
  ///
  /// In en, this message translates to:
  /// **'Auto-detected: {state}'**
  String autoDetected(String state);

  /// No description provided for @subsidiesForFarmers.
  ///
  /// In en, this message translates to:
  /// **'Subsidies, loans & support for Indian farmers'**
  String get subsidiesForFarmers;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @cropType.
  ///
  /// In en, this message translates to:
  /// **'Crop Type'**
  String get cropType;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @findSchemes.
  ///
  /// In en, this message translates to:
  /// **'Find Schemes'**
  String get findSchemes;

  /// No description provided for @quickSelectState.
  ///
  /// In en, this message translates to:
  /// **'Quick Select State:'**
  String get quickSelectState;

  /// No description provided for @schemesFor.
  ///
  /// In en, this message translates to:
  /// **'Schemes for {state} - {crop}'**
  String schemesFor(String state, String crop);

  /// No description provided for @kvkInfo.
  ///
  /// In en, this message translates to:
  /// **'For official details, contact your local Krishi Vigyan Kendra (KVK) or visit PM-KISAN portal.'**
  String get kvkInfo;

  /// No description provided for @locationMode.
  ///
  /// In en, this message translates to:
  /// **'Location Mode'**
  String get locationMode;

  /// No description provided for @detectingLocation.
  ///
  /// In en, this message translates to:
  /// **'Detecting location...'**
  String get detectingLocation;

  /// No description provided for @analyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyze;

  /// No description provided for @fetchingData.
  ///
  /// In en, this message translates to:
  /// **'Fetching real-time data...'**
  String get fetchingData;

  /// No description provided for @analyzingRisks.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your risks...'**
  String get analyzingRisks;

  /// No description provided for @riskAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AgriNova Risk Analysis'**
  String get riskAnalysis;

  /// No description provided for @liveWeather.
  ///
  /// In en, this message translates to:
  /// **'Live Weather'**
  String get liveWeather;

  /// No description provided for @noActiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active severe weather alerts in your area.'**
  String get noActiveAlerts;

  /// No description provided for @pollenPestRisk.
  ///
  /// In en, this message translates to:
  /// **'Pollen & Pest Risk'**
  String get pollenPestRisk;

  /// No description provided for @uploadLeafHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear picture of the affected crop leaf to detect diseases instantly.'**
  String get uploadLeafHint;

  /// No description provided for @selectImageHint.
  ///
  /// In en, this message translates to:
  /// **'Tap buttons below to select image'**
  String get selectImageHint;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @analyzeLeaf.
  ///
  /// In en, this message translates to:
  /// **'Analyze Leaf'**
  String get analyzeLeaf;

  /// No description provided for @browseGuide.
  ///
  /// In en, this message translates to:
  /// **'Browse Disease Guide'**
  String get browseGuide;

  /// No description provided for @farmConditions.
  ///
  /// In en, this message translates to:
  /// **'Farm Conditions'**
  String get farmConditions;

  /// No description provided for @soilType.
  ///
  /// In en, this message translates to:
  /// **'Soil Type'**
  String get soilType;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @rainfallLevel.
  ///
  /// In en, this message translates to:
  /// **'Rainfall Level'**
  String get rainfallLevel;

  /// No description provided for @getRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Get Recommendation'**
  String get getRecommendation;

  /// No description provided for @farmDetails.
  ///
  /// In en, this message translates to:
  /// **'Provide your farm details to get AI-powered crop recommendations tailored to your conditions.'**
  String get farmDetails;

  /// No description provided for @realTimeMarket.
  ///
  /// In en, this message translates to:
  /// **'Real-time Market & Weather'**
  String get realTimeMarket;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @bestPrice.
  ///
  /// In en, this message translates to:
  /// **'Best Price Recommendation'**
  String get bestPrice;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @tapToCall.
  ///
  /// In en, this message translates to:
  /// **'Tap to Call'**
  String get tapToCall;

  /// No description provided for @noMachinery.
  ///
  /// In en, this message translates to:
  /// **'No machinery available.'**
  String get noMachinery;

  /// No description provided for @submitOffer.
  ///
  /// In en, this message translates to:
  /// **'Submit Offer'**
  String get submitOffer;

  /// No description provided for @yourOffer.
  ///
  /// In en, this message translates to:
  /// **'Your Offer'**
  String get yourOffer;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @offerSent.
  ///
  /// In en, this message translates to:
  /// **'Offer sent!'**
  String get offerSent;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Please select an image first'**
  String get selectImage;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server Error'**
  String get serverError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to the server. Please check your connection.'**
  String get connectionError;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 9876543210'**
  String get phoneHint;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @analysisResult.
  ///
  /// In en, this message translates to:
  /// **'Analysis Result'**
  String get analysisResult;

  /// No description provided for @cropDiseasePrediction.
  ///
  /// In en, this message translates to:
  /// **'🌿 Crop Disease Prediction'**
  String get cropDiseasePrediction;

  /// No description provided for @detectedDisease.
  ///
  /// In en, this message translates to:
  /// **'Detected Disease'**
  String get detectedDisease;

  /// No description provided for @predictionConfidence.
  ///
  /// In en, this message translates to:
  /// **'Prediction Confidence'**
  String get predictionConfidence;

  /// No description provided for @recommendedAction.
  ///
  /// In en, this message translates to:
  /// **'Recommended Action'**
  String get recommendedAction;

  /// No description provided for @treatmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Treatment Plan'**
  String get treatmentPlan;

  /// No description provided for @aiAdvice.
  ///
  /// In en, this message translates to:
  /// **'AI Expert Advice'**
  String get aiAdvice;

  /// No description provided for @aiNotes.
  ///
  /// In en, this message translates to:
  /// **'ℹ️ Note:\\nThis prediction is generated using an AI model. Pesticide usage should follow government-approved guidelines. For severe cases, consult an agricultural expert.'**
  String get aiNotes;

  /// No description provided for @analyzeAnother.
  ///
  /// In en, this message translates to:
  /// **'Analyze Another Image'**
  String get analyzeAnother;

  /// No description provided for @yieldPredictor.
  ///
  /// In en, this message translates to:
  /// **'Yield & Profit Predictor'**
  String get yieldPredictor;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @noLabour.
  ///
  /// In en, this message translates to:
  /// **'No labour groups found.'**
  String get noLabour;

  /// No description provided for @negotiateOffer.
  ///
  /// In en, this message translates to:
  /// **'Send Offer & Negotiate'**
  String get negotiateOffer;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent!'**
  String get requestSent;

  /// No description provided for @dialerError.
  ///
  /// In en, this message translates to:
  /// **'Could not launch dialer'**
  String get dialerError;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// No description provided for @fertilizerPoints.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Points'**
  String get fertilizerPoints;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @fertilizerSupport.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Support'**
  String get fertilizerSupport;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @processingBooking.
  ///
  /// In en, this message translates to:
  /// **'Processing your booking...'**
  String get processingBooking;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmed;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @diseaseGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Disease Guide'**
  String get diseaseGuideTitle;

  /// No description provided for @noDiseases.
  ///
  /// In en, this message translates to:
  /// **'No diseases found.'**
  String get noDiseases;

  /// No description provided for @detailedAdvice.
  ///
  /// In en, this message translates to:
  /// **'Get Detailed AI Advice'**
  String get detailedAdvice;

  /// No description provided for @topCrops.
  ///
  /// In en, this message translates to:
  /// **'Top Recommended Crops'**
  String get topCrops;

  /// No description provided for @cropCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Calendar'**
  String get cropCalendarTitle;

  /// No description provided for @generateCalendar.
  ///
  /// In en, this message translates to:
  /// **'Generate Calendar'**
  String get generateCalendar;

  /// No description provided for @namasteAI.
  ///
  /// In en, this message translates to:
  /// **'Namaste! I am your AgriNova.'**
  String get namasteAI;

  /// No description provided for @askAnything.
  ///
  /// In en, this message translates to:
  /// **'Select your language and ask me anything about farming.'**
  String get askAnything;

  /// No description provided for @askIn.
  ///
  /// In en, this message translates to:
  /// **'Ask in {lang}...'**
  String askIn(String lang);

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added item to cart!'**
  String get addedToCart;

  /// No description provided for @cropHealth.
  ///
  /// In en, this message translates to:
  /// **'Crop Health'**
  String get cropHealth;

  /// No description provided for @cropInsights.
  ///
  /// In en, this message translates to:
  /// **'Crop Insights'**
  String get cropInsights;

  /// No description provided for @realTimeRates.
  ///
  /// In en, this message translates to:
  /// **'Real-time rates'**
  String get realTimeRates;

  /// No description provided for @revenueEstimates.
  ///
  /// In en, this message translates to:
  /// **'Revenue estimates'**
  String get revenueEstimates;

  /// No description provided for @satelliteMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Satellite monitoring'**
  String get satelliteMonitoring;

  /// No description provided for @financialSupport.
  ///
  /// In en, this message translates to:
  /// **'Financial support'**
  String get financialSupport;

  /// No description provided for @expertChat.
  ///
  /// In en, this message translates to:
  /// **'24/7 Expert Chat'**
  String get expertChat;

  /// No description provided for @weatherWarnings.
  ///
  /// In en, this message translates to:
  /// **'Weather warnings'**
  String get weatherWarnings;

  /// No description provided for @localDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Local discussions'**
  String get localDiscussions;

  /// No description provided for @recommendationCalendar.
  ///
  /// In en, this message translates to:
  /// **'Recommendation & Calendar'**
  String get recommendationCalendar;

  /// No description provided for @searchMachinery.
  ///
  /// In en, this message translates to:
  /// **'Search machinery...'**
  String get searchMachinery;

  /// No description provided for @machinesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} machines available'**
  String machinesAvailable(int count);

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @listedPrice.
  ///
  /// In en, this message translates to:
  /// **'Listed Price'**
  String get listedPrice;

  /// No description provided for @specifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specifications;

  /// No description provided for @callText.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callText;

  /// No description provided for @sendOfferNegotiate.
  ///
  /// In en, this message translates to:
  /// **'Send Offer & Negotiate'**
  String get sendOfferNegotiate;

  /// No description provided for @noContractorsFound.
  ///
  /// In en, this message translates to:
  /// **'No contractors found for this category.'**
  String get noContractorsFound;

  /// No description provided for @getAiFertilizerAdvice.
  ///
  /// In en, this message translates to:
  /// **'Get AI Fertilizer Advice'**
  String get getAiFertilizerAdvice;

  /// No description provided for @allDistricts.
  ///
  /// In en, this message translates to:
  /// **'All Districts'**
  String get allDistricts;

  /// No description provided for @selectDistrict.
  ///
  /// In en, this message translates to:
  /// **'Select District'**
  String get selectDistrict;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Data Available'**
  String get noDataAvailable;

  /// No description provided for @refreshAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Refresh Analysis'**
  String get refreshAnalysis;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get openNow;

  /// No description provided for @closedNow.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedNow;

  /// No description provided for @fertilizerShops.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Shops'**
  String get fertilizerShops;

  /// No description provided for @searchShops.
  ///
  /// In en, this message translates to:
  /// **'Search Shops'**
  String get searchShops;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapView;

  /// No description provided for @stopVoice.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopVoice;

  /// No description provided for @commandVoice.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get commandVoice;

  /// No description provided for @listenVoice.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listenVoice;

  /// No description provided for @homeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Home Dashboard'**
  String get homeDashboard;

  /// No description provided for @tryDifferentFilter.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or search term'**
  String get tryDifferentFilter;

  /// No description provided for @noRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'You have not sent any requests yet.'**
  String get noRequestsYet;

  /// No description provided for @messageContractor.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String messageContractor(String name);

  /// No description provided for @discussing.
  ///
  /// In en, this message translates to:
  /// **'Discussing: {title}'**
  String discussing(String title);

  /// No description provided for @yourPriceOffer.
  ///
  /// In en, this message translates to:
  /// **'Your Price Offer (₹)'**
  String get yourPriceOffer;

  /// No description provided for @messageSpecialReq.
  ///
  /// In en, this message translates to:
  /// **'Message / Special Requirements'**
  String get messageSpecialReq;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send Offer'**
  String get sendOffer;

  /// No description provided for @offerSentToContractor.
  ///
  /// In en, this message translates to:
  /// **'Offer sent to contractor!'**
  String get offerSentToContractor;

  /// No description provided for @enterCropForAdvice.
  ///
  /// In en, this message translates to:
  /// **'Enter the crop you want recommendations for:'**
  String get enterCropForAdvice;

  /// No description provided for @aiFertilizerExpert.
  ///
  /// In en, this message translates to:
  /// **'AI Fertilizer Expert'**
  String get aiFertilizerExpert;

  /// No description provided for @getAdvice.
  ///
  /// In en, this message translates to:
  /// **'Get Advice'**
  String get getAdvice;

  /// No description provided for @cropHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Paddy, Maize, Tomato'**
  String get cropHintExample;

  /// No description provided for @contactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get contactNumber;

  /// No description provided for @priceRate.
  ///
  /// In en, this message translates to:
  /// **'Price / Rate'**
  String get priceRate;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @teamSize.
  ///
  /// In en, this message translates to:
  /// **'Team Size'**
  String get teamSize;

  /// No description provided for @specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialty;

  /// No description provided for @expectedYield.
  ///
  /// In en, this message translates to:
  /// **'Expected Yield'**
  String get expectedYield;

  /// No description provided for @expectedMarketPrice.
  ///
  /// In en, this message translates to:
  /// **'Expected Market Price per Ton'**
  String get expectedMarketPrice;

  /// No description provided for @totalCultivationCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cultivation Cost'**
  String get totalCultivationCost;

  /// No description provided for @contactForPrice.
  ///
  /// In en, this message translates to:
  /// **'Contact for price'**
  String get contactForPrice;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescription;

  /// No description provided for @noContactInfo.
  ///
  /// In en, this message translates to:
  /// **'No contact info'**
  String get noContactInfo;

  /// No description provided for @tapToCallAction.
  ///
  /// In en, this message translates to:
  /// **'Tap to call'**
  String get tapToCallAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'bn',
        'en',
        'gu',
        'hi',
        'kn',
        'ml',
        'mr',
        'or',
        'pa',
        'ta',
        'te'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
