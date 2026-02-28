import 'package:flutter/cupertino.dart';
import '../models/world_clock_model.dart';
import '../widgets/custom_buttons.dart';
import '../l10n/app_localizations.dart';

class AddCityScreen extends StatefulWidget {
  const AddCityScreen({super.key});

  @override
  State<AddCityScreen> createState() => _AddCityScreenState();
}

class _AddCityScreenState extends State<AddCityScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_CityData> _filteredCities = [];

  final List<_CityData> _allCities = [
    _CityData(city: 'Hanoi', country: 'Vietnam', timezone: 'Asia/Ho_Chi_Minh'),
    _CityData(city: 'Ho Chi Minh', country: 'Vietnam', timezone: 'Asia/Ho_Chi_Minh'),
    _CityData(city: 'New York', country: 'United States', timezone: 'America/New_York'),
    _CityData(city: 'Los Angeles', country: 'United States', timezone: 'America/Los_Angeles'),
    _CityData(city: 'London', country: 'United Kingdom', timezone: 'Europe/London'),
    _CityData(city: 'Paris', country: 'France', timezone: 'Europe/Paris'),
    _CityData(city: 'Tokyo', country: 'Japan', timezone: 'Asia/Tokyo'),
    _CityData(city: 'Shanghai', country: 'China', timezone: 'Asia/Shanghai'),
    _CityData(city: 'Beijing', country: 'China', timezone: 'Asia/Shanghai'),
    _CityData(city: 'Dubai', country: 'United Arab Emirates', timezone: 'Asia/Dubai'),
    _CityData(city: 'Sydney', country: 'Australia', timezone: 'Australia/Sydney'),
    _CityData(city: 'Auckland', country: 'New Zealand', timezone: 'Pacific/Auckland'),
    _CityData(city: 'Singapore', country: 'Singapore', timezone: 'Asia/Singapore'),
    _CityData(city: 'Hong Kong', country: 'Hong Kong', timezone: 'Asia/Hong_Kong'),
    _CityData(city: 'Seoul', country: 'South Korea', timezone: 'Asia/Seoul'),
    _CityData(city: 'Bangkok', country: 'Thailand', timezone: 'Asia/Bangkok'),
    _CityData(city: 'Mumbai', country: 'India', timezone: 'Asia/Kolkata'),
    _CityData(city: 'Moscow', country: 'Russia', timezone: 'Europe/Moscow'),
    _CityData(city: 'Berlin', country: 'Germany', timezone: 'Europe/Berlin'),
    _CityData(city: 'Rome', country: 'Italy', timezone: 'Europe/Rome'),
    _CityData(city: 'Madrid', country: 'Spain', timezone: 'Europe/Madrid'),
    _CityData(city: 'Toronto', country: 'Canada', timezone: 'America/Toronto'),
    _CityData(city: 'Chicago', country: 'United States', timezone: 'America/Chicago'),
    _CityData(city: 'San Francisco', country: 'United States', timezone: 'America/Los_Angeles'),
  ];

  @override
  void initState() {
    super.initState();
    _filteredCities = List.from(_allCities);
    _searchController.addListener(_filterCities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCities = List.from(_allCities);
      } else {
        _filteredCities = _allCities.where((city) {
          return city.city.toLowerCase().contains(query) ||
                 city.country.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _selectCity(_CityData cityData) {
    final clock = WorldClockModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      city: cityData.city,
      timezone: cityData.timezone,
      country: cityData.country,
    );
    Navigator.of(context).pop(clock);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Custom Navigation Bar
            CustomNavBar(
              backgroundColor: CupertinoColors.black,
              leading: NavTextButton(
                text: AppLocalizations.of(context).cancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
              middle: Text(
                AppLocalizations.of(context).chooseACity,
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: AppLocalizations.of(context).search,
                backgroundColor: const Color(0xFF2C2C2E),
                style: const TextStyle(color: CupertinoColors.white),
                placeholderStyle: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
              ),
            ),
            // Cities list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCities.length,
                itemBuilder: (context, index) {
                  final cityData = _filteredCities[index];
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _selectCity(cityData),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.darkBackgroundGray,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cityData.city,
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cityData.country,
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityData {
  final String city;
  final String country;
  final String timezone;

  _CityData({
    required this.city,
    required this.country,
    required this.timezone,
  });
}
