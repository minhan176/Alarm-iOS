import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(AppLocalizations.of(context).ratingTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context).ratingContent),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int index = 0; index < 5; index++) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedRating == index + 1) {
                        _selectedRating = 0; // Deselect if tapping the same star
                      } else {
                        _selectedRating = index + 1;
                      }
                    });
                  },
                  child: Icon(
                    index < _selectedRating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                    color: CupertinoColors.systemYellow,
                    size: 36,
                  ),
                ),
                if (index < 4) const SizedBox(width: 8),
              ]
            ],
          ),
        ],
      ),
      actions: [           
        CupertinoDialogAction(
          onPressed: _dismissForever,
          child: Text(AppLocalizations.of(context).cancel),
        ),
        CupertinoDialogAction(
          onPressed: _selectedRating > 0 ? _rateOnPlayStore : null,
          child: Text(AppLocalizations.of(context).submit),
        ),
        
      ],
    );
  }

  void _rateOnPlayStore() async {
    // Mark that user has rated, so dialog never shows again
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_rated_app', true);

    // Open Google Play link directly
    final Uri playStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=com.oaptech.clock');
    if (await canLaunchUrl(playStoreUri)) {
      await launchUrl(playStoreUri);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _dismissForever() async {
    // Mark that user dismissed rating dialog, so it never shows again
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rating_dialog_dismissed', true);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}