import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_redirect/store_redirect.dart';

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
      title: const Text('Enjoying Clock OS 26?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tap a star to rate us on\nGoogle Play.'),
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
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: _selectedRating > 0 ? _rateOnPlayStore : null,
          child: const Text('Submit'),
        ),
        
      ],
    );
  }

  void _rateOnPlayStore() async {
    // Mark that user has rated, so dialog never shows again
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_rated_app', true);

    // Redirect to Google Play
    StoreRedirect.redirect(androidAppId: 'com.oaptech.clock');

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