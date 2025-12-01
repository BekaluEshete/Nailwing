// features/my_flights/screens/add_flight_post_screen.dart
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

class _AddFlightPostScreenState extends State<AddFlightPostScreen> {
  int _currentStep = 1;
  bool _isSubmitted = false;
  bool _isEditing = false;
  bool _isLoadingAirports = false;
  bool _isLoadingAirlines = false;

  final FlightPostData _formData = FlightPostData();
  final Map<String, String> _errors = {};

  List<Airport> _searchResults = [];
  List<Airport> _popularAirports = [];
  List<String> _airlines = [];
  List<String> _filteredAirlines = [];

  final TextEditingController _airportSearchController =
      TextEditingController();
  final TextEditingController _airlineSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPopularAirports();
    _loadAirlines();
  }

  Future<void> _loadPopularAirports() async {
    setState(() {
      _isLoadingAirports = true;
    });

    try {
      // Load comprehensive airport list from CSV
      final airports = await AirportService.getPopularAirports();
      setState(() {
        _popularAirports = airports;
        _searchResults = airports;
      });
    } catch (e) {
      print('Error loading airports: $e');
      // Fallback: load airports for search
      await _loadAirportsForSearch();
    } finally {
      setState(() {
        _isLoadingAirports = false;
      });
    }
  }

  Future<void> _loadAirlines({String query = ''}) async {
    setState(() {
      _isLoadingAirlines = true;
    });

    try {
      final airlines = await AirportService.getAirlines(query: query);
      setState(() {
        _airlines = airlines;
        _filteredAirlines = airlines;
      });
    } catch (e) {
      print('Error loading airlines: $e');
      // Fallback to popular airlines
      setState(() {
        _airlines = popularAirlines;
        _filteredAirlines = popularAirlines;
      });
    } finally {
      setState(() {
        _isLoadingAirlines = false;
      });
    }
  }

  void _filterAirlines(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredAirlines = _airlines;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredAirlines = _airlines
          .where((airline) => airline.toLowerCase().contains(lowercaseQuery))
          .toList();
    });
  }

  // Live/dynamic airport search - filters instantly as user types
  void _filterAirportsLocally(String query) {
    if (!mounted) return;
    
    // Filter immediately without waiting for setState
    List<Airport> filteredResults;
    if (query.isEmpty) {
      // Show all airports when search is empty
      filteredResults = List<Airport>.from(_popularAirports);
    } else {
      // Instant local filtering - no API calls needed
      final lowercaseQuery = query.toLowerCase();
      filteredResults = _popularAirports.where((airport) {
        return airport.code.toLowerCase().contains(lowercaseQuery) ||
            airport.city.toLowerCase().contains(lowercaseQuery) ||
            airport.name.toLowerCase().contains(lowercaseQuery) ||
            airport.country.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
    
    // Update state immediately
    setState(() {
      _searchResults = filteredResults;
    });
  }
  
  // Load airports initially (async) - called when modal opens
  Future<void> _loadAirportsForSearch() async {
    if (!mounted) return;
    
    // Only show loading if we don't have airports cached yet
    if (_popularAirports.isEmpty) {
      setState(() {
        _isLoadingAirports = true;
      });
    }

    try {
      print('🔍 Loading airports for search...');
      // Load all airports from service (uses cache if available)
      final response = await AirportService.searchAirports('');
      
      if (!mounted) return;
      
      setState(() {
        _popularAirports = response.airports;
        _searchResults = response.airports; // Show all initially
        print('✅ Loaded ${_popularAirports.length} airports for live search');
      });
    } catch (e) {
      print('❌ Error loading airports: $e');
      if (!mounted) return;
      
      // Fallback - try to use cached popular airports
      if (_popularAirports.isEmpty) {
        try {
          final cached = await AirportService.getPopularAirports();
          setState(() {
            _popularAirports = cached;
            _searchResults = cached;
          });
        } catch (e2) {
          print('❌ Error loading cached airports: $e2');
          setState(() {
            _searchResults = [];
          });
        }
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingAirports = false;
      });
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

  // FIXED: Travel interest selection method
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

  // Date/Time picker helpers
  String _getDate(bool isDeparture) {
    return isDeparture
        ? _formData.departureDate
        : _formData.arrivalDate;
  }

  String _getTime(bool isDeparture) {
    return isDeparture
        ? _formData.departureTime
        : _formData.arrivalTime;
  }

  String _getDateDisplay(bool isDeparture) {
    final date = _getDate(isDeparture);
    if (date.isEmpty) return 'Select date';
    return date;
  }

  String _getTimeDisplay(bool isDeparture) {
    final time = _getTime(isDeparture);
    if (time.isEmpty) return 'Select time';
    return time;
  }

  Future<void> _selectDate(BuildContext context, bool isDeparture) async {
    final initialDate = DateTime.now();
    final firstDate = DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 365 * 2));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: isDeparture ? 'Select Departure Date' : 'Select Arrival Date',
    );

    if (pickedDate != null) {
      setState(() {
        final formattedDate =
            '${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.year}';
        if (isDeparture) {
          _formData.departureDate = formattedDate;
          _errors.remove('departureDate');
        } else {
          _formData.arrivalDate = formattedDate;
          _errors.remove('arrivalDate');
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isDeparture) async {
    final initialTime = TimeOfDay.now();

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isDeparture ? 'Select Departure Time' : 'Select Arrival Time',
    );

    if (pickedTime != null) {
      setState(() {
        final formattedTime =
            '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
        if (isDeparture) {
          _formData.departureTime = formattedTime;
          _errors.remove('departureTime');
        } else {
          _formData.arrivalTime = formattedTime;
          _errors.remove('arrivalTime');
        }
      });
    }
  }

  bool _validateStep(int step) {
    final newErrors = <String, String>{};

    switch (step) {
      case 1:
        if (_formData.airlineName.isEmpty)
          newErrors['airlineName'] = 'Airline name is required';
        if (_formData.flightNumber.isEmpty)
          newErrors['flightNumber'] = 'Flight number is required';
        if (_formData.departureAirport.isEmpty)
          newErrors['departureAirport'] = 'Departure airport is required';
        if (_formData.arrivalAirport.isEmpty)
          newErrors['arrivalAirport'] = 'Arrival airport is required';
        if (_formData.departureDate.isEmpty)
          newErrors['departureDate'] = 'Departure date is required';
        if (_formData.departureTime.isEmpty)
          newErrors['departureTime'] = 'Departure time is required';
        if (_formData.arrivalDate.isEmpty)
          newErrors['arrivalDate'] = 'Arrival date is required';
        if (_formData.arrivalTime.isEmpty)
          newErrors['arrivalTime'] = 'Arrival time is required';
        break;

      case 2:
        if (_formData.isDelayed && _formData.delayDuration.isEmpty) {
          newErrors['delayDuration'] =
              'Delay duration is required when flight is delayed';
        }
        break;

      case 3:
        if (_formData.postTitle.isEmpty)
          newErrors['postTitle'] = 'Post title is required';
        if (_formData.postContent.isEmpty)
          newErrors['postContent'] = 'Post content is required';
        if (_formData.interests.isEmpty)
          newErrors['interests'] = 'Please select at least one interest';
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
      if (_currentStep < 3) {
        setState(() {
          _currentStep++;
        });
        _showSnackBar('Step ${_currentStep - 1} completed!');
      }
    } else {
      _showSnackBar('Please fill in all required fields');
    }
  }

  void _handlePrevious() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _handleSubmit() {
    if (_validateStep(3)) {
      final newFlight = _formData.toFlight();
      widget.onFlightAdded?.call(newFlight);

      setState(() {
        _isSubmitted = true;
      });
      _showSnackBar('Flight post created successfully!');
    } else {
      _showSnackBar('Please complete all required fields');
    }
  }

  void _handleEdit() {
    setState(() {
      _isEditing = true;
      _isSubmitted = false;
      _currentStep = 1;
    });
    _showSnackBar('Editing mode enabled');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Flight Details';
      case 2:
        return 'Transit & Status';
      case 3:
        return 'Post Content';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isSubmitted && !_isEditing
          ? _buildSuccessView()
          : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildStepContent(),
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _currentStep == 1
                      ? widget.onNavigateBack
                      : _handlePrevious,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Edit Flight Post' : 'Add Flight Post',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Step $_currentStep of 3: ${_getStepTitle()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _currentStep / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
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
        return _buildPostContentStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFlightDetailsStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.flight, 'Flight Information'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildAirlineDropdown()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flight Number *',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'e.g. ET302',
                          border: const OutlineInputBorder(),
                          errorText: _errors['flightNumber'],
                        ),
                        onChanged: (value) {
                          setState(() {
                            _formData.flightNumber = value.toUpperCase();
                            _errors.remove('flightNumber');
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLocationSection('Departure *', true),
            const SizedBox(height: 16),
            _buildLocationSection('Arrival *', false),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aircraft',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'e.g. Boeing 787-9',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _formData.aircraft = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seat',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'e.g. 12A',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _formData.seat = value.toUpperCase();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gate',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'e.g. B7',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _formData.gate = value.toUpperCase();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Terminal',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'e.g. 2E',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _formData.terminal = value.toUpperCase();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirlineDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Airline Name *',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showAirlineSearchModal(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _errors.containsKey('airlineName')
                    ? Colors.red
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formData.airlineName.isEmpty
                        ? 'Select airline'
                        : _formData.airlineName,
                    style: TextStyle(
                      color: _formData.airlineName.isEmpty
                          ? Colors.grey.shade500
                          : Colors.black,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (_errors.containsKey('airlineName'))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _errors['airlineName']!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _showAirlineSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildAirlineSearchSheet(),
    );
  }

  Widget _buildAirlineSearchSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Select Airline',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _airlineSearchController,
            decoration: const InputDecoration(
              hintText: 'Search airlines...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filterAirlines,
          ),
          const SizedBox(height: 16),
          if (_isLoadingAirlines)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            Expanded(child: _buildAirlineList()),
        ],
      ),
    );
  }

  Widget _buildAirlineList() {
    if (_filteredAirlines.isEmpty) {
      return const Center(child: Text('No airlines found'));
    }

    return ListView.builder(
      itemCount: _filteredAirlines.length,
      itemBuilder: (context, index) {
        final airline = _filteredAirlines[index];
        return ListTile(
          leading: const Icon(Icons.airline_seat_recline_extra),
          title: Text(airline),
          onTap: () => _handleAirlineSelect(airline),
        );
      },
    );
  }

  Widget _buildLocationSection(String title, bool isDeparture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildAirportDropdown('Airport', isDeparture, true),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date *',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _selectDate(context, isDeparture),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getDateDisplay(isDeparture),
                              style: TextStyle(
                                color: _getDate(isDeparture).isEmpty
                                    ? Colors.grey.shade500
                                    : Colors.black,
                              ),
                            ),
                          ),
                          Icon(Icons.calendar_today,
                              size: 20, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time *',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _selectTime(context, isDeparture),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _errors.containsKey(
                                  isDeparture
                                      ? 'departureTime'
                                      : 'arrivalTime')
                              ? Colors.red
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getTimeDisplay(isDeparture),
                              style: TextStyle(
                                color: _getTime(isDeparture).isEmpty
                                    ? Colors.grey.shade500
                                    : Colors.black,
                              ),
                            ),
                          ),
                          Icon(Icons.access_time,
                              size: 20, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                  if (_errors.containsKey(
                      isDeparture ? 'departureTime' : 'arrivalTime'))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _errors[isDeparture
                                ? 'departureTime'
                                : 'arrivalTime'] ??
                            '',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAirportDropdown(
    String label,
    bool isDeparture,
    bool isRequired,
  ) {
    final currentAirport = isDeparture
        ? _formData.departureAirport
        : _formData.arrivalAirport;
    final currentCity = isDeparture
        ? _formData.departureCity
        : _formData.arrivalCity;
    final errorKey = isDeparture ? 'departureAirport' : 'arrivalAirport';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${isRequired ? '*' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showAirportSearchModal(isDeparture ? 'departure' : 'arrival'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _errors.containsKey(errorKey)
                    ? Colors.red
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    currentAirport.isEmpty
                        ? 'Select airport'
                        : '$currentAirport - $currentCity',
                    style: TextStyle(
                      color: currentAirport.isEmpty
                          ? Colors.grey.shade500
                          : Colors.black,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (_errors.containsKey(errorKey))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _errors[errorKey]!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _showAirportSearchModal(String airportType) {
    // Clear search field
    _airportSearchController.clear();
    
    // Initialize search results with empty list
    _searchResults = [];
    
    // Start loading airports in background
    _loadAirportsForSearch();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return _buildAirportSearchSheet(airportType, setModalState);
        },
      ),
    );
  }

  Widget _buildAirportSearchSheet(String airportType, StateSetter setModalState) {
    String title;
    switch (airportType) {
      case 'departure':
        title = 'Select Departure Airport';
        break;
      case 'arrival':
        title = 'Select Arrival Airport';
        break;
      case 'transit':
        title = 'Select Transit Airport';
        break;
      default:
        title = 'Select Airport';
    }

    // Get current search query
    final searchQuery = _airportSearchController.text;
    
    // Use _searchResults if it's up to date, otherwise filter on the fly
    // This ensures instant updates as user types
    final filteredAirports = _searchResults.isNotEmpty || searchQuery.isEmpty
        ? _searchResults
        : _popularAirports.where((airport) {
            final query = searchQuery.toLowerCase();
            return airport.code.toLowerCase().contains(query) ||
                airport.city.toLowerCase().contains(query) ||
                airport.name.toLowerCase().contains(query) ||
                airport.country.toLowerCase().contains(query);
          }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _airportSearchController,
            decoration: const InputDecoration(
              hintText: 'Type to search by airport name, city, or code...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // Update main state
              _filterAirportsLocally(value);
              // Trigger modal rebuild for instant UI update
              setModalState(() {});
            },
            autofocus: true,
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: 8),
          // Show search result count when typing
          if (searchQuery.isNotEmpty && !_isLoadingAirports)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                '${filteredAirports.length} airport${filteredAirports.length == 1 ? '' : 's'} found',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildAirportListReactive(filteredAirports, airportType),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAirportListReactive(List<Airport> airports, String airportType) {
    // Show loading only on initial load
    if (_isLoadingAirports && _popularAirports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading airports...'),
            ],
          ),
        ),
      );
    }
    
    // Show no results message
    if (airports.isEmpty && !_isLoadingAirports) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _airportSearchController.text.isEmpty
                    ? 'No airports available'
                    : 'No airports found for "${_airportSearchController.text}"',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: airports.length,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemBuilder: (context, index) {
        final airport = airports[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          elevation: 1,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                airport.code,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              airport.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${airport.city}, ${airport.country}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _handleAirportSelect(airport, airportType);
            },
          ),
        );
      },
    );
  }


  Widget _buildTransitStatusStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.access_time, 'Transit & Flight Status'),
            const SizedBox(height: 16),
            const Text(
              'Transit Information (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transit Airport',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _showAirportSearchModal('transit'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formData.transitAirport.isEmpty
                                      ? 'Select transit airport'
                                      : '${_formData.transitAirport} - ${_formData.transitCity}',
                                  style: TextStyle(
                                    color: _formData.transitAirport.isEmpty
                                        ? Colors.grey.shade500
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transit Duration',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'e.g. 2h 30m',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _formData.transitTime = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Flight Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: _formData.isDelayed,
                  onChanged: (value) {
                    setState(() {
                      _formData.isDelayed = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'Flight was delayed',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (_formData.isDelayed) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Delay Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delay Duration *',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'e.g. 3h 45m',
                            border: const OutlineInputBorder(),
                            errorText: _errors['delayDuration'],
                          ),
                          onChanged: (value) {
                            setState(() {
                              _formData.delayDuration = value;
                              _errors.remove('delayDuration');
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Flight Preview',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _formData.departureAirport.isEmpty
                                  ? 'DEP'
                                  : _formData.departureAirport,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formData.departureCity.isEmpty
                                  ? 'Departure'
                                  : _formData.departureCity,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formData.departureTime.isEmpty
                                  ? '--:--'
                                  : _formData.departureTime,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: AppColors.primary),
                                ),
                                Icon(
                                  Icons.flight_takeoff,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                Expanded(
                                  child: Divider(color: AppColors.primary),
                                ),
                              ],
                            ),
                            Text(
                              _formData.airlineName.isEmpty
                                  ? 'Airline'
                                  : _formData.airlineName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formData.flightNumber.isEmpty
                                  ? 'Flight'
                                  : _formData.flightNumber,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            if (_formData.transitAirport.isNotEmpty)
                              Text(
                                'via ${_formData.transitAirport}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _formData.arrivalAirport.isEmpty
                                  ? 'ARR'
                                  : _formData.arrivalAirport,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formData.arrivalCity.isEmpty
                                  ? 'Arrival'
                                  : _formData.arrivalCity,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formData.arrivalTime.isEmpty
                                  ? '--:--'
                                  : _formData.arrivalTime,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_formData.isDelayed &&
                      _formData.delayDuration.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        border: Border.all(color: Colors.orange[200]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'Delayed by ${_formData.delayDuration}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostContentStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.edit, 'Share Your Experience'),
            const SizedBox(height: 16),
            const Text(
              'Flight Rating *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _formData.rating = index + 1;
                      });
                    },
                    icon: Icon(
                      Icons.star,
                      color: index < _formData.rating
                          ? Colors.amber
                          : Colors.grey[300],
                      size: 32,
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '(${_formData.rating}/5)',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Post Title *',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            TextFormField(
              decoration: InputDecoration(
                hintText:
                    'e.g. Amazing flight experience with Ethiopian Airlines',
                border: const OutlineInputBorder(),
                errorText: _errors['postTitle'],
              ),
              maxLength: 100,
              onChanged: (value) {
                setState(() {
                  _formData.postTitle = value;
                  _errors.remove('postTitle');
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Share Your Experience *',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Tell us about your flight experience...',
                border: const OutlineInputBorder(),
                errorText: _errors['postContent'],
              ),
              maxLines: 5,
              maxLength: 500,
              onChanged: (value) {
                setState(() {
                  _formData.postContent = value;
                  _errors.remove('postContent');
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Travel Interests *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select topics that relate to your travel experience',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            // FIXED: Travel Interests with proper selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: travelInterests.map((interest) {
                final isSelected = _formData.interests.contains(interest);
                return GestureDetector(
                  onTap: () => _toggleInterest(interest),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tag,
                          size: 14,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          interest,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_errors.containsKey('interests'))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errors['interests']!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 8),
            Text(
              'Selected: ${_formData.interests.length} interests',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),

            if (_formData.interests.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Interests:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _formData.interests.map((interest) {
                        return Chip(
                          label: Text(
                            '#$interest',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _handlePrevious,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == 3 ? _handleSubmit : _handleNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _currentStep == 3
                    ? const Color(0xFF10B981)
                    : AppColors.primary,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentStep == 3) const Icon(Icons.save, size: 16),
                  if (_currentStep == 3) const SizedBox(width: 4),
                  Text(
                    _currentStep == 3
                        ? (_isEditing ? 'Update Post' : 'Publish Post')
                        : 'Next Step',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF10B981), const Color(0xFF059669)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onNavigateBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flight Post Created',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Successfully published',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Post Created Successfully!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your flight experience has been shared with the Nile Wing community',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _handleEdit,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: BorderSide(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Color(0xFF059669),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Edit Post',
                                      style: TextStyle(
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: widget.onNavigateBack,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.visibility, size: 16),
                                    SizedBox(width: 4),
                                    Text('View in Feed'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Flight Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _formData.departureAirport,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formData.departureCity,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _formData.departureTime,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.flight_takeoff,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _formData.airlineName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _formData.flightNumber,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _formData.arrivalAirport,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formData.arrivalCity,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _formData.arrivalTime,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Rating: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            ...List.generate(5, (index) {
                              return Icon(
                                Icons.star,
                                size: 16,
                                color: index < _formData.rating
                                    ? Colors.amber
                                    : Colors.grey[300],
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          _formData.postTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formData.postContent,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: _formData.interests.take(3).map((interest) {
                            return Chip(
                              label: Text(
                                '#$interest',
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            );
                          }).toList(),
                        ),
                        if (_formData.interests.length > 3) ...[
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(
                              '+${_formData.interests.length - 3} more',
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.grey[100],
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
