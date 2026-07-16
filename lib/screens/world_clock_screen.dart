import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../providers/world_clock_provider.dart';
import '../models/world_clock_model.dart';
import '../widgets/custom_buttons.dart';
import 'settings_screen.dart';
import 'upgrade_pro_screen.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_banner_ad.dart';
import '../l10n/app_localizations.dart';

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  bool _isEditMode = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update UI every second to show live time
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _addCity() async {
    final result = await showCupertinoSheet<WorldClockModel>(
      context: context,
      builder: (BuildContext context) => CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGrey6,
        child: SafeArea(
          child: Column(
            children: [
              // Custom Navigation Bar
              SizedBox(height: 5,),
              CustomNavBar(
                backgroundColor: Color(0xFF1C1C1E),
                leading: NavIconButton(
                  icon: CupertinoIcons.xmark,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                middle: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppLocalizations.of(context).chooseACity,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Search bar and cities list content
              Expanded(
                child: _AddCityContent(
                  onCitySelected: (WorldClockModel clock) {
                    Navigator.of(context).pop(clock);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (result != null) {
      if (mounted) {
        Provider.of<WorldClockProvider>(context, listen: false).addClock(result);
        AdService.showInterstitialAdIfAvailable();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Navigation Bar
            CustomNavBar(
              backgroundColor: CupertinoColors.black,
              leading: NavTextButton(
                text: _isEditMode ? AppLocalizations.of(context).done : AppLocalizations.of(context).edit,
                onPressed: _toggleEditMode,
              ),
              trailing: NavIconButton(
                icon: CupertinoIcons.add,
                onPressed: _addCity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context).worldClock,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isEditMode) ...[
                        const SizedBox(width: 10),
                        if (!Provider.of<SettingsProvider>(context).isProUnlocked)
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minSize: 0,
                            color: CupertinoColors.systemOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                            onPressed: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) => const UpgradeProScreen(),
                                  fullscreenDialog: true,
                                ),
                              );
                            },
                            child: Text(
                              AppLocalizations.of(context).UPGRADE_PRO,
                              style: const TextStyle(
                                color: CupertinoColors.systemOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                  if (_isEditMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: const Icon(
                          CupertinoIcons.settings,
                          color: CupertinoColors.systemOrange,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<WorldClockProvider>(
                builder: (context, provider, child) {
                  if (provider.clocks.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context).noWorldClocks,
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 24,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.clocks.length + 1,
                    itemBuilder: (context, index) {
                      if (index == provider.clocks.length) {
                        // Add extra space at the bottom to avoid tab bar overlap
                        return const SizedBox(height: 100);
                      }
                      final clock = provider.clocks[index];
                      return _WorldClockItem(
                        clock: clock,
                        isEditMode: _isEditMode,
                        onTap: () {
                          // No action in edit mode for world clocks
                        },
                        onDelete: () {
                          provider.removeClock(clock.id);
                        },
                      );
                    },
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

class _WorldClockItem extends StatelessWidget {
  final WorldClockModel clock;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorldClockItem({
    required this.clock,
    required this.isEditMode,
    required this.onTap,
    required this.onDelete,
  });

  String _getTimeDifference(BuildContext context) {
    try {
      final now = DateTime.now();
      final location = tz.getLocation(clock.timezone);
      final tzTime = tz.TZDateTime.now(location);
      
      final diffDuration = tzTime.timeZoneOffset - now.timeZoneOffset;
      
      int diffHours = diffDuration.inHours;
      int diffMinutes = diffDuration.inMinutes.abs() % 60;
      
      if (diffHours == 0 && diffMinutes == 0) {
        return AppLocalizations.of(context).today;
      } else {
        String sign = diffDuration.inMinutes > 0 ? '+' : (diffDuration.inMinutes < 0 ? '-' : '');
        if (diffMinutes == 0) {
          return '$sign${diffHours.abs()}HRS';
        } else {
          return '$sign${diffHours.abs()}:${diffMinutes.toString().padLeft(2, '0')}HRS';
        }
      }
    } catch (e) {
      // Fallback if timezone not found or initialized
      return AppLocalizations.of(context).today;
    }
  }

  DateTime _getCurrentTimeInTimezone() {
    try {
      final location = tz.getLocation(clock.timezone);
      return tz.TZDateTime.now(location);
    } catch (e) {
      // Fallback
      return DateTime.now().toUtc();
    }
  }

  @override
  Widget build(BuildContext context) {
    // final use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    final currentTime = _getCurrentTimeInTimezone();
    
    final String hourText;
    final String? periodText;
    
    if (Provider.of<SettingsProvider>(context).is24HourFormat) {
      hourText = '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
      periodText = null;
    } else {
      final hour = currentTime.hour % 12 == 0 ? 12 : currentTime.hour % 12;
      hourText = '$hour:${currentTime.minute.toString().padLeft(2, '0')}';
      periodText = currentTime.hour >= 12 ? 'PM' : 'AM';
    }
    
    final timeDiff = _getTimeDifference(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      pressedOpacity: 1.0,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF3C3C3E),
              width: 0.5,
            ),
          ),
        ),
      child: Row(
        children: [
          if (isEditMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: CupertinoColors.systemRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.minus,
                    color: CupertinoColors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeDiff,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  clock.city,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              text: hourText,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 48,
                fontWeight: FontWeight.w200,
                height: 1,
              ),
              children: periodText != null ? [
                TextSpan(
                  text: periodText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ] : [],
            ),
          ),
        ],
      ),
    ),
    );
  }
}




class _AddCityContent extends StatefulWidget {
  final Function(WorldClockModel) onCitySelected;

  const _AddCityContent({required this.onCitySelected});

  @override
  State<_AddCityContent> createState() => _AddCityContentState();
}

class _AddCityContentState extends State<_AddCityContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  String? _hoveredLetter;
  String? _activeLetter;
  List<_CityData> _filteredCities = [];

  final List<_CityData> _allCities = [
    _CityData(city: 'Amsterdam', country: 'Netherlands', timezone: 'Europe/Amsterdam'),
    _CityData(city: 'Athens', country: 'Greece', timezone: 'Europe/Athens'),
    _CityData(city: 'Auckland', country: 'New Zealand', timezone: 'Pacific/Auckland'),
    _CityData(city: 'Bangkok', country: 'Thailand', timezone: 'Asia/Bangkok'),
    _CityData(city: 'Barcelona', country: 'Spain', timezone: 'Europe/Madrid'),
    _CityData(city: 'Beijing', country: 'China', timezone: 'Asia/Shanghai'),
    _CityData(city: 'Berlin', country: 'Germany', timezone: 'Europe/Berlin'),
    _CityData(city: 'Bogotá', country: 'Colombia', timezone: 'America/Bogota'),
    _CityData(city: 'Boston', country: 'United States', timezone: 'America/New_York'),
    _CityData(city: 'Brussels', country: 'Belgium', timezone: 'Europe/Brussels'),
    _CityData(city: 'Buenos Aires', country: 'Argentina', timezone: 'America/Argentina/Buenos_Aires'),
    _CityData(city: 'Cairo', country: 'Egypt', timezone: 'Africa/Cairo'),
    _CityData(city: 'Cape Town', country: 'South Africa', timezone: 'Africa/Johannesburg'),
    _CityData(city: 'Chicago', country: 'United States', timezone: 'America/Chicago'),
    _CityData(city: 'Copenhagen', country: 'Denmark', timezone: 'Europe/Copenhagen'),
    _CityData(city: 'Delhi', country: 'India', timezone: 'Asia/Kolkata'),
    _CityData(city: 'Denver', country: 'United States', timezone: 'America/Denver'),
    _CityData(city: 'Dubai', country: 'United Arab Emirates', timezone: 'Asia/Dubai'),
    _CityData(city: 'Dublin', country: 'Ireland', timezone: 'Europe/Dublin'),
    _CityData(city: 'Frankfurt', country: 'Germany', timezone: 'Europe/Berlin'),
    _CityData(city: 'Hanoi', country: 'Vietnam', timezone: 'Asia/Ho_Chi_Minh'),
    _CityData(city: 'Ho Chi Minh', country: 'Vietnam', timezone: 'Asia/Ho_Chi_Minh'),
    _CityData(city: 'Hong Kong', country: 'Hong Kong', timezone: 'Asia/Hong_Kong'),
    _CityData(city: 'Istanbul', country: 'Turkey', timezone: 'Europe/Istanbul'),
    _CityData(city: 'Jakarta', country: 'Indonesia', timezone: 'Asia/Jakarta'),
    _CityData(city: 'Johannesburg', country: 'South Africa', timezone: 'Africa/Johannesburg'),
    _CityData(city: 'Kuala Lumpur', country: 'Malaysia', timezone: 'Asia/Kuala_Lumpur'),
    _CityData(city: 'Lagos', country: 'Nigeria', timezone: 'Africa/Lagos'),
    _CityData(city: 'Lisbon', country: 'Portugal', timezone: 'Europe/Lisbon'),
    _CityData(city: 'London', country: 'United Kingdom', timezone: 'Europe/London'),
    _CityData(city: 'Los Angeles', country: 'United States', timezone: 'America/Los_Angeles'),
    _CityData(city: 'Madrid', country: 'Spain', timezone: 'Europe/Madrid'),
    _CityData(city: 'Manila', country: 'Philippines', timezone: 'Asia/Manila'),
    _CityData(city: 'Melbourne', country: 'Australia', timezone: 'Australia/Melbourne'),
    _CityData(city: 'Mexico City', country: 'Mexico', timezone: 'America/Mexico_City'),
    _CityData(city: 'Miami', country: 'United States', timezone: 'America/New_York'),
    _CityData(city: 'Milan', country: 'Italy', timezone: 'Europe/Rome'),
    _CityData(city: 'Moscow', country: 'Russia', timezone: 'Europe/Moscow'),
    _CityData(city: 'Mumbai', country: 'India', timezone: 'Asia/Kolkata'),
    _CityData(city: 'Munich', country: 'Germany', timezone: 'Europe/Berlin'),
    _CityData(city: 'New York', country: 'United States', timezone: 'America/New_York'),
    _CityData(city: 'Oslo', country: 'Norway', timezone: 'Europe/Oslo'),
    _CityData(city: 'Paris', country: 'France', timezone: 'Europe/Paris'),
    _CityData(city: 'Perth', country: 'Australia', timezone: 'Australia/Perth'),
    _CityData(city: 'Prague', country: 'Czech Republic', timezone: 'Europe/Prague'),
    _CityData(city: 'Rio de Janeiro', country: 'Brazil', timezone: 'America/Sao_Paulo'),
    _CityData(city: 'Rome', country: 'Italy', timezone: 'Europe/Rome'),
    _CityData(city: 'San Francisco', country: 'United States', timezone: 'America/Los_Angeles'),
    _CityData(city: 'Santiago', country: 'Chile', timezone: 'America/Santiago'),
    _CityData(city: 'São Paulo', country: 'Brazil', timezone: 'America/Sao_Paulo'),
    _CityData(city: 'Seoul', country: 'South Korea', timezone: 'Asia/Seoul'),
    _CityData(city: 'Shanghai', country: 'China', timezone: 'Asia/Shanghai'),
    _CityData(city: 'Singapore', country: 'Singapore', timezone: 'Asia/Singapore'),
    _CityData(city: 'Stockholm', country: 'Sweden', timezone: 'Europe/Stockholm'),
    _CityData(city: 'Sydney', country: 'Australia', timezone: 'Australia/Sydney'),
    _CityData(city: 'Taipei', country: 'Taiwan', timezone: 'Asia/Taipei'),
    _CityData(city: 'Tokyo', country: 'Japan', timezone: 'Asia/Tokyo'),
    _CityData(city: 'Toronto', country: 'Canada', timezone: 'America/Toronto'),
    _CityData(city: 'Vancouver', country: 'Canada', timezone: 'America/Vancouver'),
    _CityData(city: 'Vienna', country: 'Austria', timezone: 'Europe/Vienna'),
    _CityData(city: 'Warsaw', country: 'Poland', timezone: 'Europe/Warsaw'),
    _CityData(city: 'Zurich', country: 'Switzerland', timezone: 'Europe/Zurich'),
  ];

  @override
  void initState() {
    super.initState();
    _filteredCities = List.from(_allCities)..sort((a, b) => a.city.compareTo(b.city));
    _searchController.addListener(_filterCities);
    _scrollController.addListener(_updateActiveLetter);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateActiveLetter());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_updateActiveLetter);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateActiveLetter() {
    // Group cities by first letter
    final Map<String, List<_CityData>> groupedCities = {};
    for (final city in _filteredCities) {
      final firstLetter = city.city[0].toUpperCase();
      if (!groupedCities.containsKey(firstLetter)) {
        groupedCities[firstLetter] = [];
      }
      groupedCities[firstLetter]!.add(city);
    }
    // Sort the groups by letter
    final sortedKeys = groupedCities.keys.toList()..sort();

    final offset = _scrollController.offset;
    double currentPos = 0.0;
    for (final letter in sortedKeys) {
      final cities = groupedCities[letter]!;
      final sectionHeight = 38.0 + (cities.length * 64.0);
      if (offset >= currentPos && offset < currentPos + sectionHeight) {
        if (_activeLetter != letter) {
          setState(() => _activeLetter = letter);
        }
        return;
      }
      currentPos += sectionHeight;
    }
    if (_activeLetter != null) {
      setState(() => _activeLetter = null);
    }
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCities = List.from(_allCities)..sort((a, b) => a.city.compareTo(b.city));
      } else {
        _filteredCities = _allCities.where((city) {
          return city.city.toLowerCase().contains(query) ||
                 city.country.toLowerCase().contains(query);
        }).toList()..sort((a, b) => a.city.compareTo(b.city));
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
    widget.onCitySelected(clock);
  }

  @override
  Widget build(BuildContext context) {
    // Group cities by first letter
    final Map<String, List<_CityData>> groupedCities = {};
    for (final city in _filteredCities) {
      final firstLetter = city.city[0].toUpperCase();
      if (!groupedCities.containsKey(firstLetter)) {
        groupedCities[firstLetter] = [];
      }
      groupedCities[firstLetter]!.add(city);
    }

    // Sort the groups by letter
    final sortedKeys = groupedCities.keys.toList()..sort();

    // Create keys for each section
    for (final key in sortedKeys) {
      if (!_sectionKeys.containsKey(key)) {
        _sectionKeys[key] = GlobalKey();
      }
    }

    return Column(
      children: [
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
              fontSize: 16,
            ),
          ),
        ),
        // Cities list with index
        Expanded(
          child: Row(
            children: [
              // Cities list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, _sectionIndex) {
                    final letter = sortedKeys[_sectionIndex];
                    final cities = groupedCities[letter]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header
                        Container(
                          key: _sectionKeys[letter],
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          //color: CupertinoColors.systemGrey6.withOpacity(0.5),
                          child: Text(
                            letter,
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Cities in this section
                        ...cities.map((cityData) => CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _selectCity(cityData),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              children: [
                                Row(
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
                                              fontSize: 16,
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
                                // Divider aligned with text content
                                Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  height: 0.5,
                                  color: CupertinoColors.darkBackgroundGray,
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    );
                  },
                ),
              ),
              // Index bar
              Container(
                width: 30,
                padding: const EdgeInsets.only(top: 16, bottom: 16, right: 4),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedKeys.map((letter) => MouseRegion(
                    onEnter: (_) => setState(() => _hoveredLetter = letter),
                    onExit: (_) => setState(() => _hoveredLetter = null),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final key = _sectionKeys[letter];
                        if (key?.currentContext != null) {
                          Scrollable.ensureVisible(
                            key!.currentContext!,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: 0.0,
                          );
                        } else {
                          // Fallback: calculate precise position based on previous sections
                          final sectionIndex = sortedKeys.indexOf(letter);
                          double scrollPosition = 0.0;
                          for (int i = 0; i < sectionIndex; i++) {
                            final prevLetter = sortedKeys[i];
                            final prevCities = groupedCities[prevLetter]!;
                            scrollPosition += 38.0 + (prevCities.length * 64.0); // header + cities
                          }
                          _scrollController.animateTo(
                            scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      onVerticalDragStart: (_) {}, // Prevent sheet drag
                      onHorizontalDragStart: (_) {}, // Prevent sheet drag
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: _activeLetter == letter 
                              ? CupertinoColors.systemYellow
                              : CupertinoColors.systemOrange,
                            fontSize: _activeLetter == letter ? 16 : 14,
                            fontWeight: _activeLetter == letter 
                              ? FontWeight.w900 
                              : (_hoveredLetter == letter ? FontWeight.w700 : FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SettingsBannerAd(),
       
      ],
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
