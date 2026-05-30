import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:nilewing/core/theme/app_colors.dart';
import '../service/safety_action_service.dart';
import 'package:nilewing/features/home/viewmodel/home_view_model.dart';

class CountrySafetyGuideWidget extends ConsumerStatefulWidget {
  const CountrySafetyGuideWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<CountrySafetyGuideWidget> createState() => _CountrySafetyGuideWidgetState();
}

class _CountrySafetyGuideWidgetState extends ConsumerState<CountrySafetyGuideWidget> {
  final SafetyActionService _actionService = SafetyActionService();
  Map<String, dynamic>? _allData;
  Map<String, dynamic>? _guideData;
  String _displayLocation = 'Destination';

  @override
  void initState() {
    super.initState();
    _loadSafetyData();
  }

  Future<void> _loadSafetyData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/country_safety.json');
      _allData = json.decode(jsonString);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading safety guide: $e');
    }
  }

  String _getCountryCode(String airportCode) {
    if (['ADD', 'DIR', 'MQX', 'BJR', 'JIM'].contains(airportCode)) return 'ET';
    if (['NRT', 'HND', 'KIX'].contains(airportCode)) return 'JP';
    if (['LHR', 'LGW', 'STN'].contains(airportCode)) return 'GB';
    if (['JFK', 'LAX', 'ORD', 'SFO', 'MIA', 'ATL'].contains(airportCode)) return 'US';
    if (['AAH', 'FRA', 'MUC', 'BER', 'DUS'].contains(airportCode)) return 'DE';
    return 'default';
  }

  Color _ratingColor(int rating) {
    if (rating >= 5) return const Color(0xFF059669);
    if (rating >= 4) return const Color(0xFF0891B2);
    if (rating >= 3) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  String _ratingLabel(int rating) {
    if (rating >= 5) return 'Very Safe';
    if (rating >= 4) return 'Safe';
    if (rating >= 3) return 'Moderate';
    return 'Caution';
  }

  @override
  Widget build(BuildContext context) {
    if (_allData == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final viewModel = ref.watch(homeViewModelProvider);
    final flight = viewModel.userFlight;

    if (flight != null) {
      _displayLocation = flight.arrival.airport;
      _guideData = _allData![_getCountryCode(flight.arrival.airport)] ?? _allData!['default'];
    } else {
      _displayLocation = '---';
      _guideData = _allData!['default'];
    }

    final int rating = _guideData!['rating'] ?? 3;
    final Color ratingColor = _ratingColor(rating);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.08), AppColors.accent.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.public_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destination Safety',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Arriving at $_displayLocation',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                // Safety rating badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ratingColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ratingColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _ratingLabel(rating),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ratingColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) => Icon(
                          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: ratingColor,
                          size: 10,
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emergency numbers section
                Row(
                  children: [
                    Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    const Text(
                      'Emergency Numbers',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildEmergencyTile('Police', _guideData!['police'], Icons.local_police_rounded, const Color(0xFF1D4ED8))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildEmergencyTile('Ambulance', _guideData!['ambulance'], Icons.medical_services_rounded, const Color(0xFFDC2626))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildEmergencyTile('Fire', _guideData!['fire'], Icons.local_fire_department_rounded, const Color(0xFFEA580C))),
                  ],
                ),
                const SizedBox(height: 20),

                // Women's helpline – highlighted
                GestureDetector(
                  onTap: () => _actionService.callEmergencyNumber(_guideData!['womens_helpline']),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.08), AppColors.accent.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Women's Helpline", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                              Text(_guideData!['womens_helpline'], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                        const Icon(Icons.phone_rounded, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Info rows
                Row(
                  children: [
                    Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    const Text('Travel Tips', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInfoTile(Icons.lightbulb_outline_rounded, 'Cultural Tips', _guideData!['cultural_tips'], const Color(0xFFF59E0B)),
                _buildInfoTile(Icons.check_circle_outline_rounded, 'Safe Areas', _guideData!['safe_areas'], const Color(0xFF059669)),
                _buildInfoTile(Icons.warning_amber_rounded, 'Areas to Avoid', _guideData!['areas_to_avoid'], const Color(0xFFDC2626)),
                _buildInfoTile(Icons.visibility_off_rounded, 'Common Scams', _guideData!['common_scams'], AppColors.mutedForeground, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTile(String label, String number, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _actionService.callEmergencyNumber(number),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color.withOpacity(0.8))),
            const SizedBox(height: 2),
            Text(
              number,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Tap to call', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String content, Color iconColor, {bool isLast = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: iconColor.withOpacity(0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                    const SizedBox(height: 3),
                    Text(content, style: TextStyle(color: AppColors.mutedForeground, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const SizedBox(height: 10),
      ],
    );
  }
}
