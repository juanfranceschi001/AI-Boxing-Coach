import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Monetization (banner ad); non-fatal if it ever fails to init.
  try {
    await MobileAds.instance.initialize();
  } catch (_) {}

  runApp(const AiBoxingCoachApp());
}
