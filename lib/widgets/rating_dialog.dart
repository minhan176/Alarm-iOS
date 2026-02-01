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
      title: const Text('Enjoying our app?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Rate us on Google Play'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
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
                  color: index < _selectedRating ? CupertinoColors.systemYellow : CupertinoColors.systemGrey,
                  size: 32,
                ),
              );
            }),
          ),
        ],
      ),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          onPressed: _dismissForever,
          child: const Text('Later'),
        ),
        CupertinoDialogAction(
          onPressed: _selectedRating > 0 ? _rateOnPlayStore : null,
          child: Container(
            width: 200,
            alignment: Alignment.center,
            child: Text(_selectedRating > 0 ? 'Rate us on Google Play' : 'Rate', style: TextStyle(fontSize: 16)),
          ),
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