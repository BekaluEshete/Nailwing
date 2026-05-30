// features/my_flights/view/add_flight_post_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/features/my_flights/model/flight_post_model.dart';
import '../services/airport_service.dart';

class AddFlightPostScreen extends StatefulWidget {
  final VoidCallback onNavigateBack;
  final Function(dynamic)? onFlightAdded;

  const AddFlightPostScreen({
    Key? key,
    required this.onNavigateBack,
    this.onFlightAdded,
  }) : super(key: key);

  @override
  State<AddFlightPostScreen> createState() => _AddFlightPostScreenState();
}

class _AddFlightPostScreenState extends State<AddFlightPostScreen>
    with TickerProviderStateMixin {
  int _currentStep = 1;
  static const int _maxSteps = 3;
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  bool _isLoadingAirports = false;
  bool _isLoadingAirlines = false;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  final FlightPostData _formData = FlightPostData();
  final Map<String, String> _errors = {};

  List<Airport> _searchResults = [];
  List<Airport> _popularAirports = [];
  List<String> _airlines = [];
  List<String> _filteredAirlines = [];

  final TextEditingController _airportSearchController = TextEditingController();
  final TextEditingController _airlineSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(
      begin: 1 / _maxSteps,
      end: 1 / _maxSteps,
    ).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeInOut));

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );
    _cardController.forward();
    _loadPopularAirports();
    _loadAirlines();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _cardController.dispose();
    _scrollController.dispose();
    _airportSearchController.dispose();
    _airlineSearchController.dispose();
    super.dispose();
  }

  void _animateToStep(int step) {
    _progressAnimation = Tween<double>(
      begin: _currentStep / _maxSteps,
      end: step / _maxSteps,
    ).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeInOut));
    _progressController.forward(from: 0);
    _cardController.forward(from: 0);
    setState(() => _currentStep = step);
  }

  Future<void> _loadPopularAirports() async {
    setState(() => _isLoadingAirports = true);
    try {
      final airports = await AirportService.getPopularAirports();
      setState(() {
        _popularAirports = airports;
        _searchResults = airports;
      });
    } catch (e) {
      await _loadAirportsForSearch();
    } finally {
      setState(() => _isLoadingAirports = false);
    }
  }

  Future<void> _loadAirlines({String query = ''}) async {
    setState(() => _isLoadingAirlines = true);
    try {
      final airlines = await AirportService.getAirlines(query: query);
      setState(() {
        _airlines = airlines;
        _filteredAirlines = airlines;
      });
    } catch (e) {
      setState(() {
        _airlines = popularAirlines;
        _filteredAirlines = popularAirlines;
      });
    } finally {
      setState(() => _isLoadingAirlines = false);
    }
  }

  void _filterAirlines(String query) {
    if (query.isEmpty) {
      setState(() => _filteredAirlines = _airlines);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredAirlines = _airlines.where((a) => a.toLowerCase().contains(q)).toList();
    });
  }

  void _filterAirportsLocally(String query) {
    if (!mounted) return;
    List<Airport> results;
    if (query.isEmpty) {
      results = List<Airport>.from(_popularAirports);
    } else {
      final q = query.toLowerCase();
      results = _popularAirports.where((a) =>
        a.code.toLowerCase().contains(q) ||
        a.city.toLowerCase().contains(q) ||
        a.name.toLowerCase().contains(q) ||
        a.country.toLowerCase().contains(q),
      ).toList();
    }
    setState(() => _searchResults = results);
  }

  Future<void> _loadAirportsForSearch() async {
    if (!mounted) return;
    if (_popularAirports.isEmpty) setState(() => _isLoadingAirports = true);
    try {
      final response = await AirportService.searchAirports('');
      if (!mounted) return;
      setState(() {
        _popularAirports = response.airports;
        _searchResults = response.airports;
      });
    } catch (e) {
      if (_popularAirports.isEmpty) {
        try {
          final cached = await AirportService.getPopularAirports();
          setState(() {
            _popularAirports = cached;
            _searchResults = cached;
          });
        } catch (_) {
          setState(() => _searchResults = []);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingAirports = false);
    }
  }

  void _handleAirportSelect(Airport airport, String airportType) {
    setState(() {
      switch (airportType) {
        case 'departure':
          _formData.departureAirport = airport.code;
          _formData.departureCity = airport.city;
          _errors.remove('departureAirport');
          break;
        case 'arrival':
          _formData.arrivalAirport = airport.code;
          _formData.arrivalCity = airport.city;
          _formData.destinationPlace = airport.city;
          _errors.remove('arrivalAirport');
          break;
        case 'transit':
          _formData.transitAirport = airport.code;
          _formData.transitCity = airport.city;
          _errors.remove('transitAirport');
          break;
      }
      _airportSearchController.clear();
    });
    Navigator.pop(context);
  }

  void _handleAirlineSelect(String airline) {
    setState(() {
      _formData.airlineName = airline;
      _errors.remove('airlineName');
      _airlineSearchController.clear();
      _filteredAirlines = _airlines;
    });
    Navigator.pop(context);
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_formData.interests.contains(interest)) {
        _formData.interests.remove(interest);
      } else {
        _formData.interests.add(interest);
      }
      _errors.remove('interests');
    });
  }

  Future<void> _selectDate(BuildContext context, bool isDeparture) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        final formatted =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
        if (isDeparture) {
          _formData.departureDate = formatted;
          _errors.remove('departureDate');
        } else {
          _formData.arrivalDate = formatted;
          _errors.remove('arrivalDate');
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isDeparture) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        final formatted =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isDeparture) {
          _formData.departureTime = formatted;
          _errors.remove('departureTime');
        } else {
          _formData.arrivalTime = formatted;
          _errors.remove('arrivalTime');
        }
      });
    }
  }

  bool _isValidTimeFormat(String? time) {
    if (time == null || time.trim().isEmpty) return true;
    final cleaned = time.trim().toLowerCase();
    final pattern = RegExp(r'^(\d+h)?\s*(\d+m)?\s*(\d+s)?$');
    if (!pattern.hasMatch(cleaned)) return false;
    return cleaned.contains('h') || cleaned.contains('m') || cleaned.contains('s');
  }

  String? _validateTransitTime(String? time) {
    if (time == null || time.trim().isEmpty) return null;
    if (!_isValidTimeFormat(time)) return 'Use format like "2h 30m" or "45m"';
    return null;
  }

  bool _validateStep(int step) {
    final newErrors = <String, String>{};
    switch (step) {
      case 1:
        if (_formData.airlineName.isEmpty) newErrors['airlineName'] = 'Required';
        if (_formData.flightNumber.isEmpty) newErrors['flightNumber'] = 'Required';
        if (_formData.departureAirport.isEmpty) newErrors['departureAirport'] = 'Required';
        if (_formData.arrivalAirport.isEmpty) newErrors['arrivalAirport'] = 'Required';
        if (_formData.departureDate.isEmpty) newErrors['departureDate'] = 'Required';
        if (_formData.departureTime.isEmpty) newErrors['departureTime'] = 'Required';
        if (_formData.arrivalDate.isEmpty) newErrors['arrivalDate'] = 'Required';
        if (_formData.arrivalTime.isEmpty) newErrors['arrivalTime'] = 'Required';
        break;
      case 2:
        final err = _validateTransitTime(_formData.transitTime);
        if (err != null) newErrors['transitTime'] = err;
        if (_formData.isDelayed && _formData.delayDuration.isEmpty) {
          newErrors['delayDuration'] = 'Required when delayed';
        }
        break;
      case 3:
        if (_formData.interests.isEmpty) {
          newErrors['interests'] = 'Select at least one interest';
        }
        break;
    }
    setState(() {
      _errors.clear();
      _errors.addAll(newErrors);
    });
    return newErrors.isEmpty;
  }

  void _handleNext() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < _maxSteps) {
        _animateToStep(_currentStep + 1);
      } else {
        _handleSubmit();
      }
    } else {
      _showError('Please fill in all required fields');
    }
  }

  void _handlePrevious() {
    if (_currentStep > 1) _animateToStep(_currentStep - 1);
  }

  void _handleSubmit() {
    if (_validateStep(_maxSteps)) {
      setState(() => _isSubmitting = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        final newFlight = _formData.toFlight();
        widget.onFlightAdded?.call(newFlight);
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static const _stepTitles = ['Flight Details', 'Transit & Status', 'Matching Preferences'];
  static const _stepIcons = [Icons.flight_takeoff, Icons.connecting_airports, Icons.people];
  static const _stepSubtitles = [
    'Route, airline & schedule',
    'Layover & delay info',
    'Interests & preferences',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _buildBackground(),
          if (_isSubmitted) _buildSuccessView() else _buildFormView(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFECFEFF), Color(0xFFF0F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -40,
              child: _blob(220, const Color(0xFFCFFAFE).withOpacity(0.5)),
            ),
            Positioned(
              bottom: -60,
              left: -80,
              child: _blob(280, const Color(0xFFE0F2FE).withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildFormView() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 20 * (1 - _cardAnimation.value)),
                  child: Opacity(opacity: _cardAnimation.value, child: child),
                ),
                child: _buildStepContent(),
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentStep == 1
                          ? widget.onNavigateBack
                          : _handlePrevious,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Flight',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            'Step $_currentStep of $_maxSteps — ${_stepTitles[_currentStep - 1]}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Step dots
                    Row(
                      children: List.generate(_maxSteps, (i) {
                        final active = i + 1 == _currentStep;
                        final done = i + 1 < _currentStep;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(left: 6),
                          width: active ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: done || active
                                ? AppColors.primary
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (_, __) {
                    final progress = _currentStep / _maxSteps;
                    return Stack(
                      children: [
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Step tabs
                Row(
                  children: List.generate(_maxSteps, (i) {
                    final active = i + 1 == _currentStep;
                    final done = i + 1 < _currentStep;
                    return Expanded(
                      child: GestureDetector(
                        onTap: done ? () => _animateToStep(i + 1) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.only(right: i < _maxSteps - 1 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary.withOpacity(0.1)
                                : done
                                    ? Colors.green.withOpacity(0.08)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary.withOpacity(0.3)
                                  : done
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                done ? Icons.check_circle_rounded : _stepIcons[i],
                                size: 14,
                                color: active
                                    ? AppColors.primary
                                    : done
                                        ? Colors.green
                                        : Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _stepTitles[i].split(' ').first,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                    color: active
                                        ? AppColors.primary
                                        : done
                                            ? Colors.green
                                            : Colors.grey[400],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildFlightDetailsStep();
      case 2:
        return _buildTransitStatusStep();
      case 3:
        return _buildMatchingPreferencesStep();
      default:
        return const SizedBox();
    }
  }

  // ─── GLASS CARD WRAPPER ───────────────────────────────────────────────────
  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  // ─── SECTION LABEL ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PREMIUM INPUT FIELD ──────────────────────────────────────────────────
  Widget _inputField({
    required String label,
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    String? error,
    bool required = false,
    TextCapitalization capitalization = TextCapitalization.none,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.3,
              ),
            ),
            if (required)
              Text(' *', style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value.isEmpty ? null : value,
          textCapitalization: capitalization,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w400),
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            suffixIcon: suffix,
            errorText: error,
            errorStyle: const TextStyle(fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SELECTOR BUTTON (airport / airline / date / time) ───────────────────
  Widget _selectorButton({
    required String label,
    required String value,
    required String placeholder,
    required VoidCallback onTap,
    String? error,
    bool required = false,
    IconData icon = Icons.keyboard_arrow_down_rounded,
    Color? valueColor,
  }) {
    final hasValue = value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.3,
              ),
            ),
            if (required)
              Text(' *', style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null
                    ? Colors.red
                    : hasValue
                        ? AppColors.primary.withOpacity(0.4)
                        : Colors.grey[200]!,
                width: hasValue ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value : placeholder,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? (valueColor ?? Colors.grey[800])
                          : Colors.grey[400],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 18, color: hasValue ? AppColors.primary : Colors.grey[400]),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 11)),
          ),
      ],
    );
  }

  // ─── STEP 1: FLIGHT DETAILS ───────────────────────────────────────────────
  Widget _buildFlightDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live preview card
        _buildLivePreviewCard(),
        const SizedBox(height: 16),

        // Airline & Flight Number
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Flight Info', Icons.flight),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _selectorButton(
                      label: 'Airline',
                      value: _formData.airlineName,
                      placeholder: 'Select airline',
                      required: true,
                      error: _errors['airlineName'],
                      onTap: _showAirlineSearchModal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _inputField(
                      label: 'Flight No.',
                      hint: 'ET302',
                      value: _formData.flightNumber,
                      required: true,
                      error: _errors['flightNumber'],
                      capitalization: TextCapitalization.characters,
                      onChanged: (v) {
                        _formData.flightNumber = v.toUpperCase();
                        if (_errors.containsKey('flightNumber')) {
                          setState(() => _errors.remove('flightNumber'));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      label: 'Aircraft',
                      hint: 'Boeing 787',
                      value: _formData.aircraft,
                      onChanged: (v) => _formData.aircraft = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField(
                      label: 'Seat',
                      hint: '12A',
                      value: _formData.seat,
                      capitalization: TextCapitalization.characters,
                      onChanged: (v) => _formData.seat = v.toUpperCase(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      label: 'Gate',
                      hint: 'B7',
                      value: _formData.gate,
                      capitalization: TextCapitalization.characters,
                      onChanged: (v) => _formData.gate = v.toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField(
                      label: 'Terminal',
                      hint: '2E',
                      value: _formData.terminal,
                      capitalization: TextCapitalization.characters,
                      onChanged: (v) => _formData.terminal = v.toUpperCase(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Departure
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Departure', Icons.flight_takeoff_rounded),
              _selectorButton(
                label: 'Airport',
                value: _formData.departureAirport.isEmpty
                    ? ''
                    : '${_formData.departureAirport} — ${_formData.departureCity}',
                placeholder: 'Search departure airport',
                required: true,
                error: _errors['departureAirport'],
                icon: Icons.search_rounded,
                valueColor: AppColors.primary,
                onTap: () => _showAirportSearchModal('departure'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _selectorButton(
                      label: 'Date',
                      value: _formData.departureDate,
                      placeholder: 'Select date',
                      required: true,
                      error: _errors['departureDate'],
                      icon: Icons.calendar_today_rounded,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectorButton(
                      label: 'Time',
                      value: _formData.departureTime,
                      placeholder: 'Select time',
                      required: true,
                      error: _errors['departureTime'],
                      icon: Icons.access_time_rounded,
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Arrival
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Arrival', Icons.flight_land_rounded),
              _selectorButton(
                label: 'Airport',
                value: _formData.arrivalAirport.isEmpty
                    ? ''
                    : '${_formData.arrivalAirport} — ${_formData.arrivalCity}',
                placeholder: 'Search arrival airport',
                required: true,
                error: _errors['arrivalAirport'],
                icon: Icons.search_rounded,
                valueColor: AppColors.primary,
                onTap: () => _showAirportSearchModal('arrival'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _selectorButton(
                      label: 'Date',
                      value: _formData.arrivalDate,
                      placeholder: 'Select date',
                      required: true,
                      error: _errors['arrivalDate'],
                      icon: Icons.calendar_today_rounded,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectorButton(
                      label: 'Time',
                      value: _formData.arrivalTime,
                      placeholder: 'Select time',
                      required: true,
                      error: _errors['arrivalTime'],
                      icon: Icons.access_time_rounded,
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── LIVE PREVIEW CARD ────────────────────────────────────────────────────
  Widget _buildLivePreviewCard() {
    final hasDep = _formData.departureAirport.isNotEmpty;
    final hasArr = _formData.arrivalAirport.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDep ? _formData.departureAirport : '---',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  hasDep ? _formData.departureCity : 'Departure',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                ),
                if (_formData.departureTime.isNotEmpty)
                  Text(
                    _formData.departureTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(width: 30, height: 1, color: Colors.white.withOpacity(0.5)),
                  Transform.rotate(
                    angle: 1.5708,
                    child: const Icon(Icons.flight, color: Colors.white, size: 20),
                  ),
                  Container(width: 30, height: 1, color: Colors.white.withOpacity(0.5)),
                ],
              ),
              const SizedBox(height: 4),
              if (_formData.airlineName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formData.flightNumber.isNotEmpty
                        ? _formData.flightNumber
                        : _formData.airlineName.split(' ').first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasArr ? _formData.arrivalAirport : '---',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  hasArr ? _formData.arrivalCity : 'Arrival',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                ),
                if (_formData.arrivalTime.isNotEmpty)
                  Text(
                    _formData.arrivalTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 2: TRANSIT & STATUS ─────────────────────────────────────────────
  Widget _buildTransitStatusStep() {
    return Column(
      children: [
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Layover / Transit', Icons.connecting_airports_rounded),
              _selectorButton(
                label: 'Transit Airport',
                value: _formData.transitAirport.isEmpty
                    ? ''
                    : '${_formData.transitAirport} — ${_formData.transitCity}',
                placeholder: 'Optional — search transit airport',
                icon: Icons.search_rounded,
                valueColor: AppColors.primary,
                onTap: () => _showAirportSearchModal('transit'),
              ),
              const SizedBox(height: 14),
              _inputField(
                label: 'Transit Duration',
                hint: 'e.g. 2h 30m',
                value: _formData.transitTime,
                error: _errors['transitTime'],
                onChanged: (v) {
                  _formData.transitTime = v;
                  final err = _validateTransitTime(v);
                  setState(() {
                    if (err != null) {
                      _errors['transitTime'] = err;
                    } else {
                      _errors.remove('transitTime');
                    }
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Flight Status', Icons.info_outline_rounded),
              // Delay toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _formData.isDelayed
                      ? Colors.orange.withOpacity(0.08)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _formData.isDelayed
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: _formData.isDelayed ? Colors.orange : Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flight Delayed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _formData.isDelayed ? Colors.orange[800] : Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Mark if your flight has a delay',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _formData.isDelayed,
                      activeColor: Colors.orange,
                      onChanged: (v) => setState(() => _formData.isDelayed = v),
                    ),
                  ],
                ),
              ),
              if (_formData.isDelayed) ...[
                const SizedBox(height: 14),
                _inputField(
                  label: 'Delay Duration',
                  hint: 'e.g. 3h 45m',
                  value: _formData.delayDuration,
                  required: true,
                  error: _errors['delayDuration'],
                  onChanged: (v) {
                    setState(() {
                      _formData.delayDuration = v;
                      _errors.remove('delayDuration');
                    });
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Preview
        if (_formData.departureAirport.isNotEmpty) _buildLivePreviewCard(),
      ],
    );
  }

  // ─── STEP 3: MATCHING PREFERENCES ────────────────────────────────────────
  Widget _buildMatchingPreferencesStep() {
    return Column(
      children: [
        // Interests
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Travel Interests', Icons.interests_rounded),
              Text(
                'Select interests to find compatible travel companions',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),
              if (_errors.containsKey('interests'))
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[400], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _errors['interests']!,
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: travelInterests.map((interest) {
                  final selected = _formData.interests.contains(interest);
                  return GestureDetector(
                    onTap: () => _toggleInterest(interest),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.grey[200]!,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_formData.interests.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '${_formData.interests.length} selected',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Companion preferences
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Companion Preferences', Icons.people_alt_rounded),
              _toggleRow(
                icon: Icons.group_add_rounded,
                title: 'Looking for company',
                subtitle: 'Show up in travel companion searches',
                value: _formData.lookingForCompany,
                onChanged: (v) => setState(() => _formData.lookingForCompany = v),
              ),
              const SizedBox(height: 10),
              _toggleRow(
                icon: Icons.handshake_rounded,
                title: 'Open to meeting',
                subtitle: 'Allow other travelers to connect',
                value: _formData.openToMeeting,
                onChanged: (v) => setState(() => _formData.openToMeeting = v),
              ),
              const SizedBox(height: 16),
              _dropdownField(
                label: 'Preferred Companion Gender',
                value: _formData.preferredGender,
                items: const ['Any', 'male', 'female', 'other'],
                onChanged: (v) => setState(() => _formData.preferredGender = v ?? 'Any'),
              ),
              const SizedBox(height: 14),
              _dropdownField(
                label: 'Your Travel Experience',
                value: _formData.travelExperience,
                items: const ['First Time', 'Occasional', 'Frequent', 'Expert'],
                onChanged: (v) => setState(() => _formData.travelExperience = v ?? 'Occasional'),
              ),
              const SizedBox(height: 16),
              _toggleRow(
                icon: Icons.school_rounded,
                title: 'I need guidance',
                subtitle: 'First time at this airport',
                value: _formData.needsGuidance,
                onChanged: (v) => setState(() => _formData.needsGuidance = v),
                activeColor: Colors.blue,
              ),
              const SizedBox(height: 10),
              _toggleRow(
                icon: Icons.tour_rounded,
                title: 'I can guide others',
                subtitle: 'Familiar with this airport',
                value: _formData.offeringGuidance,
                onChanged: (v) => setState(() => _formData.offeringGuidance = v),
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? (activeColor ?? AppColors.primary).withOpacity(0.06)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? (activeColor ?? AppColors.primary).withOpacity(0.2)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: value ? (activeColor ?? AppColors.primary) : Colors.grey[400]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: value ? (activeColor ?? AppColors.primary) : Colors.grey[700],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: activeColor ?? AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e[0].toUpperCase() + e.substring(1)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ─── BOTTOM ACTIONS ───────────────────────────────────────────────────────
  Widget _buildBottomActions() {
    final isLast = _currentStep == _maxSteps;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentStep > 1) ...[
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _handlePrevious,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColors.primary,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLast
                          ? [Colors.green, Colors.green.shade400]
                          : [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isLast ? Colors.green : AppColors.primary).withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: Colors.white.withOpacity(0.8),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLast ? 'Add Flight' : 'Continue',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SUCCESS VIEW ─────────────────────────────────────────────────────────
  Widget _buildSuccessView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated check
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.35),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Flight Added!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your flight has been posted. We\'ll find you the best travel companions.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Flight summary card
            _glassCard(
              child: Column(
                children: [
                  _buildLivePreviewCard(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryChip(Icons.flight_class_rounded, _formData.airlineName.split(' ').first),
                      _summaryChip(Icons.chair_alt_rounded, _formData.seat.isEmpty ? 'No seat' : _formData.seat),
                      _summaryChip(Icons.interests_rounded, '${_formData.interests.length} interests'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSubmitted = false;
                        _currentStep = 1;
                        _formData.airlineName = '';
                        _formData.flightNumber = '';
                        _formData.departureAirport = '';
                        _formData.arrivalAirport = '';
                        _formData.departureDate = '';
                        _formData.departureTime = '';
                        _formData.arrivalDate = '';
                        _formData.arrivalTime = '';
                        _formData.interests.clear();
                      });
                      _cardController.forward(from: 0);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Another'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: widget.onNavigateBack,
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('View Flights'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── AIRPORT SEARCH MODAL ─────────────────────────────────────────────────
  void _showAirportSearchModal(String airportType) {
    _airportSearchController.clear();
    _searchResults = List.from(_popularAirports);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildAirportSheet(airportType),
    );
  }

  Widget _buildAirportSheet(String airportType) {
    final titles = {
      'departure': 'Departure Airport',
      'arrival': 'Arrival Airport',
      'transit': 'Transit Airport',
    };
    return StatefulBuilder(
      builder: (ctx, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titles[airportType] ?? 'Select Airport',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _airportSearchController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search by city, airport or code...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (q) {
                      _filterAirportsLocally(q);
                      setModalState(() {});
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingAirports
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('No airports found', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _searchResults.length,
                          itemBuilder: (_, i) {
                            final airport = _searchResults[i];
                            return GestureDetector(
                              onTap: () => _handleAirportSelect(airport, airportType),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey[100]!),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          airport.code,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            airport.city,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          Text(
                                            '${airport.name} • ${airport.country}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios_rounded,
                                        size: 14, color: Colors.grey[300]),
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

  // ─── AIRLINE SEARCH MODAL ─────────────────────────────────────────────────
  void _showAirlineSearchModal() {
    _airlineSearchController.clear();
    _filteredAirlines = List.from(_airlines);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildAirlineSheet(),
    );
  }

  Widget _buildAirlineSheet() {
    return StatefulBuilder(
      builder: (ctx, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Airline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _airlineSearchController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search airlines...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (q) {
                      _filterAirlines(q);
                      setModalState(() {});
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingAirlines
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : _filteredAirlines.isEmpty
                      ? Center(
                          child: Text('No airlines found',
                              style: TextStyle(color: Colors.grey[500])),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredAirlines.length,
                          itemBuilder: (_, i) {
                            final airline = _filteredAirlines[i];
                            return GestureDetector(
                              onTap: () => _handleAirlineSelect(airline),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey[100]!),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.airlines_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        airline,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios_rounded,
                                        size: 14, color: Colors.grey[300]),
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
