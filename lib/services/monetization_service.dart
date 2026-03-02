import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';
import 'supabase_service.dart';

class MonetizationService extends ChangeNotifier {
  final LocalStorageService _localStorage;
  final SupabaseService _supabaseService;

  bool _isPremium = false;
  DateTime? _trialStartDate;
  
  // Rewarded Ad
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  bool _debugMode = false;

  MonetizationService(this._localStorage, this._supabaseService) {
    _init();
  }

  void toggleDebugMode(bool value) {
      _debugMode = value;
      notifyListeners();
  }
  
  bool get isDebugMode => _debugMode;

  Future<void> _init() async {
    await checkStatus();
    _loadRewardedAd();
  }

  Future<void> checkStatus() async {
    final profile = await _supabaseService.getProfile();
    if (profile != null) {
      _isPremium = profile['is_premium'] == true;
      if (profile['created_at'] != null) {
        _trialStartDate = DateTime.parse(profile['created_at']);
      }
    }
    notifyListeners();
  }

  // --- Logic Helpers ---

  // Strategy 3.0: Ads are ALWAYS ON for free users (Day 1+)
  bool get shouldShowBannerAds {
    // If premium, no ads.
    if (_isPremium) return false;
    // Otherwise, always show ads (Trial is "Ad-Supported")
    return true; 
  }

  // Strategy 3.0: Locking happens after 14 days (Day 15+)
  bool get isPostTrial {
      if (_debugMode) return true; // Debug override
      if (_isPremium) return false;
      if (_trialStartDate == null) return false; // Fail safe to open
      final days = DateTime.now().difference(_trialStartDate!).inDays;
      return days > 14; // 14-day free trial
  }

  // Check if a feature is locked
  bool isFeatureLocked(String featureId) {
    if (_isPremium) return false;
    
    // Only lock if we are past the 30-day trial (or in debug mode)
    if (!isPostTrial) return false;

    // Check for "Unlock" (30 min reward from watching ad)
    final unlockTimeStr = _localStorage.getString('unlock_${featureId}_expiry');
    if (unlockTimeStr != null) {
      final expiry = DateTime.parse(unlockTimeStr);
      if (DateTime.now().isBefore(expiry)) {
        return false; // Valid unlock
      }
    }
    return true; // Locked
  }

  // Unlock a feature for N hours
  Future<void> unlockForHours(String featureId, int hours) async {
    final expiry = DateTime.now().add(Duration(hours: hours));
    await _localStorage.saveString('unlock_${featureId}_expiry', expiry.toIso8601String());
    notifyListeners();
  }

  // --- Ad Logic ---

  void _loadRewardedAd() {
      if (kIsWeb) return; 
      RewardedAd.load(
        adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test ID
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isAdLoading = false;
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            print('RewardedAd failed to load: $error');
            _isAdLoading = false;
            _rewardedAd = null;
          },
        ),
      );
  }

  // Show Ad to Unlock Feature
  void showUnlockDialog(BuildContext context, String featureName, String featureId, VoidCallback onSuccess) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('Unlock $featureName'),
         content: const Text(
           'This is a Premium feature.\n\nOption 1: Subscribe for full access.\nOption 2: Watch a short video to unlock for 24 hours.',
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Cancel'),
           ),
           ElevatedButton(
             onPressed: () {
               // Show Ad
               Navigator.pop(context); // Close dialog
               _showRewardedAd(context, featureId, onSuccess);
             },
             child: const Text('Watch Video'),
           ),
         ],
       ),
     );
  }

  void _showRewardedAd(BuildContext context, String featureId, VoidCallback onSuccess) {
     // Mock Simulation
     showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Watching Ad (Simulation)... 15s"),
                  ],
              ),
          ),
      );

      Future.delayed(const Duration(seconds: 15), () async {
          Navigator.pop(context); // Close loading
          
          // Unlock Logic (30 minutes)
          final expiry = DateTime.now().add(const Duration(minutes: 30));
          await _localStorage.saveString('unlock_${featureId}_expiry', expiry.toIso8601String());
          
          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reward Earned! Feature Unlocked.")));
          }

          onSuccess();
      });
  }
}
