// features/match/view/match_detail_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import 'package:nilewing/features/chat/view/call_screen.dart';
import 'package:nilewing/features/chat/viewmodel/chat_view_model.dart';
import 'package:nilewing/features/match/model/match_model.dart';
import 'package:nilewing/features/match/view/user_detail_screen.dart';
import 'package:nilewing/features/match/viewModel/match_view_model.dart';

class MatchDetailScreen extends ConsumerWidget {
  final Match match;
  final VoidCallback onNavigateBack;

  const MatchDetailScreen({
    Key? key,
    required this.match,
    required this.onNavigateBack,
  }) : super(key: key);

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Color _compatColor(int c) {
    if (c >= 80) return const Color(0xFF10B981);
    if (c >= 60) return const Color(0xFF0891B2);
    if (c >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFF94A3B8);
  }

  String _compatLabel(int c) {
    if (c >= 80) return 'Excellent Match';
    if (c >= 60) return 'Good Match';
    if (c >= 40) return 'Fair Match';
    return 'Low Match';
  }

  Color _statusColor(String s) {
    final sl = s.toLowerCase();
    if (sl.contains('matched') || sl.contains('connected')) return const Color(0xFF10B981);
    if (sl.contains('request') || sl.contains('sent') || sl.contains('awaiting')) return const Color(0xFFF59E0B);
    if (sl.contains('rejected')) return const Color(0xFFEF4444);
    return AppColors.primary;
  }

  String _avatarUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('http') ? raw : '${AppConstants.baseUrl}$raw';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(matchViewModelProvider.notifier);
    final matchState = ref.watch(matchViewModelProvider);
    final currentMatch = matchState.matches.firstWhere(
      (m) => m.id == match.id,
      orElse: () => match,
    );
    final pct = currentMatch.compatibility;
    final color = _compatColor(pct);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _buildBg(),
          CustomScrollView(
            slivers: [
              _buildSliverHeader(context, ref, currentMatch, color),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    _buildCompatCard(currentMatch, color, pct),
                    const SizedBox(height: 14),
                    _buildRouteCard(currentMatch),
                    const SizedBox(height: 14),
                    _buildDescriptionCard(currentMatch),
                    if (currentMatch.commonInterests.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildInterestsCard(currentMatch),
                    ],
                    if (currentMatch.suggestedActivities.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildActivitiesCard(currentMatch),
                    ],
                    if (currentMatch.tripPurpose != null) ...[
                      const SizedBox(height: 14),
                      _buildTripPurposeCard(currentMatch),
                    ],
                  ]),
                ),
              ),
            ],
          ),
          // Floating action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildActionBar(context, ref, viewModel, currentMatch),
          ),
        ],
      ),
    );
  }

  // ─── BACKGROUND ───────────────────────────────────────────────────────────
  Widget _buildBg() {
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
              top: -60,
              right: -40,
              child: _blob(200, AppColors.primary.withOpacity(0.1)),
            ),
            Positioned(
              bottom: 100,
              left: -60,
              child: _blob(240, const Color(0xFFE0F2FE).withOpacity(0.5)),
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

  // ─── SLIVER HEADER ────────────────────────────────────────────────────────
  Widget _buildSliverHeader(
    BuildContext context,
    WidgetRef ref,
    Match m,
    Color color,
  ) {
    final avatarUrl = _avatarUrl(m.user.avatar);
    final hasAvatar = avatarUrl.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        onPressed: onNavigateBack,
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
      ),
      actions: [
        if (m.status.toLowerCase().contains('matched') ||
            m.status.toLowerCase().contains('connected')) ...[
          _headerIconBtn(Icons.call_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  channelName: m.user.id,
                  contactName: m.user.name,
                  contactId: m.user.id,
                  isVideoCall: false,
                ),
              ),
            ).then((_) =>
                ref.read(chatViewModelProvider.notifier).dismissIncomingCall());
          }),
          _headerIconBtn(Icons.videocam_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  channelName: m.user.id,
                  contactName: m.user.name,
                  contactId: m.user.id,
                  isVideoCall: true,
                ),
              ),
            ).then((_) =>
                ref.read(chatViewModelProvider.notifier).dismissIncomingCall());
          }),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserDetailScreen(
                user: m.user,
                onNavigateBack: () => Navigator.pop(context),
              ),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent, AppColors.primary.withBlue(220)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: hasAvatar
                                  ? Image.network(avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _avatarFallback(m))
                                  : _avatarFallback(m),
                            ),
                          ),
                          if (m.user.isOnline)
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              m.user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (m.user.verified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded,
                                color: Colors.white, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Meta chips
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        children: [
                          if (m.user.nationality.isNotEmpty)
                            _headerChip(m.user.nationality),
                          if (m.user.age > 0)
                            _headerChip('${m.user.age} yrs'),
                          _headerChip(m.matchType.displayName),
                          _headerChip(m.timeAgo),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to view full profile',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _avatarFallback(Match m) {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Text(
          m.user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
      ),
    );
  }

  // ─── GLASS CARD ───────────────────────────────────────────────────────────
  Widget _glassCard({required Widget child, Color? accentColor}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (accentColor ?? AppColors.primary).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: color ?? AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ─── COMPATIBILITY CARD ───────────────────────────────────────────────────
  Widget _buildCompatCard(Match m, Color color, int pct) {
    return _glassCard(
      accentColor: color,
      child: Column(
        children: [
          Row(
            children: [
              // Big circular indicator
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: pct / 100,
                      strokeWidth: 6,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _compatLabel(pct),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.matchType.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 6,
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip(Icons.access_time_rounded, m.overlapTime, color),
                _vDivider(),
                _statChip(Icons.share_location_rounded,
                    m.sharedSegments.isNotEmpty ? m.sharedSegments.first : '—', color),
                _vDivider(),
                _statChip(Icons.schedule_rounded, m.timeAgo, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 28, color: Colors.grey[200]);

  // ─── ROUTE CARD ───────────────────────────────────────────────────────────
  Widget _buildRouteCard(Match m) {
    final fi = m.flightInfo;
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Flight Route', Icons.flight_rounded),
          Row(
            children: [
              // Departure
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fi.departure,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      fi.departureCity,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fmtTime(fi.departureTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Middle
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        _dot(false),
                        Expanded(child: _gradLine()),
                        Transform.rotate(
                          angle: 1.5708,
                          child: Icon(Icons.flight, color: AppColors.primary, size: 20),
                        ),
                        Expanded(child: _gradLine()),
                        _dot(true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        fi.duration,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fi.airline.split(' ').first,
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrival
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fi.arrival,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      fi.arrivalCity,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fmtTime(fi.arrivalTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (fi.layover != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.connecting_airports_rounded,
                      size: 14, color: Colors.amber[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Layover: ${fi.layover} — ${fi.layoverCity ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dot(bool filled) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
      );

  Widget _gradLine() => Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.2),
              AppColors.primary,
              AppColors.primary.withOpacity(0.2),
            ],
          ),
        ),
      );

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ─── DESCRIPTION CARD ─────────────────────────────────────────────────────
  Widget _buildDescriptionCard(Match m) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('About This Match', Icons.info_outline_rounded),
          Text(
            m.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── INTERESTS CARD ───────────────────────────────────────────────────────
  Widget _buildInterestsCard(Match m) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Common Interests', Icons.interests_rounded),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: m.commonInterests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  interest,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── ACTIVITIES CARD ──────────────────────────────────────────────────────
  Widget _buildActivitiesCard(Match m) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Suggested Activities', Icons.lightbulb_outline_rounded,
              color: Colors.amber[700]),
          ...m.suggestedActivities.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── TRIP PURPOSE CARD ────────────────────────────────────────────────────
  Widget _buildTripPurposeCard(Match m) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Trip Purpose', Icons.luggage_rounded,
              color: Colors.purple[600]),
          Text(
            m.tripPurpose!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── FLOATING ACTION BAR ──────────────────────────────────────────────────
  Widget _buildActionBar(
    BuildContext context,
    WidgetRef ref,
    MatchViewModel viewModel,
    Match m,
  ) {
    final isMatched = m.status.toLowerCase().contains('matched') ||
        m.status.toLowerCase().contains('connected');
    final isPending = m.status.toLowerCase().contains('request') ||
        m.status.toLowerCase().contains('sent') ||
        m.status.toLowerCase().contains('awaiting');
    final isIncoming = m.status.toLowerCase() == 'connection request' &&
        !m.isRequestSentByCurrentUser;
    final isRejected = m.status.toLowerCase().contains('rejected');
    final isNew = !isMatched && !isPending && !isIncoming && !isRejected;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMatched) _matchedActions(context, ref, m),
              if (isIncoming) _incomingActions(context, ref, viewModel, m),
              if (isPending && !isIncoming) _pendingState(),
              if (isNew) _connectAction(context, ref, viewModel, m),
              if (isRejected) _rejectedState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchedActions(BuildContext context, WidgetRef ref, Match m) {
    return Row(
      children: [
        Expanded(
          child: _gradBtn(
            label: 'Open Chat',
            icon: Icons.chat_bubble_rounded,
            colors: [const Color(0xFF10B981), const Color(0xFF059669)],
            onTap: () => _createChatAfterConnection(context, ref, m),
          ),
        ),
      ],
    );
  }

  Widget _incomingActions(
    BuildContext context,
    WidgetRef ref,
    MatchViewModel viewModel,
    Match m,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.person_add_rounded, size: 14, color: Colors.amber[700]),
              const SizedBox(width: 6),
              Text(
                '${m.user.name} wants to connect with you',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _outlineBtn(
                label: 'Decline',
                icon: Icons.close_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => _handleRejectConnection(context, ref, viewModel, m),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _gradBtn(
                label: 'Accept',
                icon: Icons.check_rounded,
                colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                onTap: () => _handleAcceptConnection(context, ref, viewModel, m),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pendingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time_rounded, size: 16, color: Colors.amber[700]),
          const SizedBox(width: 8),
          Text(
            'Connection request sent — waiting for response',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.amber[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectAction(
    BuildContext context,
    WidgetRef ref,
    MatchViewModel viewModel,
    Match m,
  ) {
    return Row(
      children: [
        Expanded(
          child: _gradBtn(
            label: 'Send Connection Request',
            icon: Icons.person_add_rounded,
            colors: [AppColors.primary, AppColors.accent],
            onTap: () => _handleConnect(context, ref, viewModel, m),
          ),
        ),
      ],
    );
  }

  Widget _rejectedState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_rounded, size: 16, color: Colors.red[500]),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Connection declined — chat is unavailable',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradBtn({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACTION HANDLERS (unchanged logic) ────────────────────────────────────
  Future<void> _handleConnect(BuildContext context, WidgetRef ref,
      MatchViewModel viewModel, Match m) async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await viewModel.likeMatch(m.id);
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connection request sent!'),
          backgroundColor: Color(0xFF10B981),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _handleAcceptConnection(BuildContext context, WidgetRef ref,
      MatchViewModel viewModel, Match m) async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final updated = await viewModel.acceptConnection(m.id);
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connection accepted! Creating chat...'),
          backgroundColor: Color(0xFF10B981),
        ));
      }
      await Future.delayed(const Duration(milliseconds: 100));
      await _createChatAfterConnection(context, ref, updated);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _handleRejectConnection(BuildContext context, WidgetRef ref,
      MatchViewModel viewModel, Match m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Decline Connection?'),
        content: const Text('Are you sure you want to decline this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await viewModel.rejectMatch(m.id);
      await viewModel.loadMatches();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connection declined.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _createChatAfterConnection(
      BuildContext context, WidgetRef ref, Match m) async {
    try {
      final statusLower = m.status.toLowerCase();
      if (statusLower != 'matched') {
        print('⚠️ [MatchDetail] Status: $statusLower — attempting chat anyway');
      }
      final tokenStorage = TokenStorage();
      final currentUserData = await tokenStorage.getUserData();
      final currentUserId = currentUserData?['id']?.toString();
      final matchedUserId = m.user.id;
      if (currentUserId != null && matchedUserId == currentUserId) return;
      if (matchedUserId.isEmpty || matchedUserId == '0') return;
      if (!context.mounted) return;
      final chatViewModel = ref.read(chatViewModelProvider.notifier);
      final contact = await chatViewModel.createPersonalChat(matchedUserId);
      if (!context.mounted) return;
      if (contact == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to create chat. Please try again.'),
          backgroundColor: Colors.orange,
        ));
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      if (context.mounted) {
        Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 100));
        if (context.mounted) context.push('/chat/${contact.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}
