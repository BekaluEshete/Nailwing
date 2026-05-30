// features/match/view/match_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nilewing/features/match/model/match_model.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/core/utils/app_constants.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  final VoidCallback onUserTap;
  final VoidCallback? onCallTap;
  final VoidCallback? onVideoCallTap;

  const MatchCard({
    Key? key,
    required this.match,
    required this.onTap,
    required this.onUserTap,
    this.onCallTap,
    this.onVideoCallTap,
  }) : super(key: key);

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Color get _compatColor {
    final c = match.compatibility;
    if (c >= 80) return const Color(0xFF10B981); // green
    if (c >= 60) return const Color(0xFF0891B2); // primary
    if (c >= 40) return const Color(0xFFF59E0B); // amber
    return const Color(0xFF94A3B8); // grey
  }

  String get _compatLabel {
    final c = match.compatibility;
    if (c >= 80) return 'Excellent';
    if (c >= 60) return 'Good';
    if (c >= 40) return 'Fair';
    return 'Low';
  }

  Color get _statusColor {
    final s = match.status.toLowerCase();
    if (s.contains('matched') || s.contains('connected')) return const Color(0xFF10B981);
    if (s.contains('request') || s.contains('sent') || s.contains('awaiting')) return const Color(0xFFF59E0B);
    if (s.contains('rejected')) return const Color(0xFFEF4444);
    return AppColors.primary;
  }

  IconData get _statusIcon {
    final s = match.status.toLowerCase();
    if (s.contains('matched') || s.contains('connected')) return Icons.check_circle_rounded;
    if (s.contains('request') || s.contains('sent')) return Icons.access_time_rounded;
    if (s.contains('rejected')) return Icons.cancel_rounded;
    return Icons.person_add_rounded;
  }

  String _avatarUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('http') ? raw : '${AppConstants.baseUrl}$raw';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, 16 * (1 - v)),
        child: Opacity(opacity: v, child: child),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _compatColor.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: [
                  // ── Top accent bar ──────────────────────────────────────
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_compatColor.withOpacity(0.6), _compatColor],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserRow(),
                        const SizedBox(height: 14),
                        _buildCompatibilityBar(),
                        const SizedBox(height: 14),
                        _buildRouteCard(),
                        if (match.commonInterests.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInterests(),
                        ],
                        const SizedBox(height: 14),
                        _buildActionRow(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── USER ROW ─────────────────────────────────────────────────────────────
  Widget _buildUserRow() {
    final avatarUrl = _avatarUrl(match.user.avatar);
    final hasAvatar = avatarUrl.isNotEmpty;

    return GestureDetector(
      onTap: onUserTap,
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _compatColor.withOpacity(0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _compatColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasAvatar
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(),
                        )
                      : _avatarFallback(),
                ),
              ),
              // Online dot
              if (match.user.isOnline)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        match.user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (match.user.verified) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified_rounded,
                          size: 14, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (match.user.nationality.isNotEmpty) ...[
                      Text(
                        match.user.nationality,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(' · ',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ],
                    if (match.user.age > 0)
                      Text(
                        '${match.user.age} yrs',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    const Spacer(),
                    Text(
                      match.timeAgo,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Match type chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    match.matchType.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Call icons if matched
          if ((match.status.toLowerCase().contains('matched') ||
                  match.status.toLowerCase().contains('connected')) &&
              onCallTap != null) ...[
            const SizedBox(width: 8),
            Column(
              children: [
                _iconBtn(Icons.call_rounded, Colors.green, onCallTap!),
                const SizedBox(height: 4),
                _iconBtn(Icons.videocam_rounded, AppColors.primary, onVideoCallTap ?? () {}),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: AppColors.primary.withOpacity(0.12),
      child: Center(
        child: Text(
          match.user.initials,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  // ─── COMPATIBILITY BAR ────────────────────────────────────────────────────
  Widget _buildCompatibilityBar() {
    final pct = match.compatibility;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _compatColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _compatColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Circular score
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 4,
                  backgroundColor: _compatColor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(_compatColor),
                ),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _compatColor,
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
                Row(
                  children: [
                    Text(
                      '$_compatLabel Match',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _compatColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      match.overlapTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 5,
                    backgroundColor: _compatColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(_compatColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  match.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ROUTE CARD ───────────────────────────────────────────────────────────
  Widget _buildRouteCard() {
    final fi = match.flightInfo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Departure
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fi.departure,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  fi.departureCity,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Flight line
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.3),
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: 1.5708,
                      child: Icon(Icons.flight, color: AppColors.primary, size: 16),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.3),
                              AppColors.primary.withOpacity(0.5),
                              AppColors.primary.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    fi.airline.split(' ').first,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  fi.arrivalCity,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── INTERESTS ────────────────────────────────────────────────────────────
  Widget _buildInterests() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: match.commonInterests.take(5).map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            interest,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList()
        ..addAll(
          match.commonInterests.length > 5
              ? [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${match.commonInterests.length - 5} more',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ]
              : [],
        ),
    );
  }

  // ─── ACTION ROW ───────────────────────────────────────────────────────────
  Widget _buildActionRow(BuildContext context) {
    final isMatched = match.status.toLowerCase().contains('matched') ||
        match.status.toLowerCase().contains('connected');
    final isPending = match.status.toLowerCase().contains('request') ||
        match.status.toLowerCase().contains('sent') ||
        match.status.toLowerCase().contains('awaiting');
    final isRejected = match.status.toLowerCase().contains('rejected');

    return Row(
      children: [
        // Status pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statusColor.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_statusIcon, size: 12, color: _statusColor),
              const SizedBox(width: 5),
              Text(
                _statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: _statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Action button
        if (isMatched)
          _actionButton(
            label: 'Open Chat',
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF10B981),
            onTap: onTap,
          )
        else if (isPending)
          _actionButton(
            label: 'Pending',
            icon: Icons.access_time_rounded,
            color: const Color(0xFFF59E0B),
            onTap: onTap,
            outlined: true,
          )
        else if (!isRejected)
          _actionButton(
            label: 'Connect',
            icon: Icons.person_add_rounded,
            color: AppColors.primary,
            onTap: onTap,
          ),
      ],
    );
  }

  String get _statusLabel {
    final s = match.status.toLowerCase();
    if (s.contains('matched') || s.contains('connected')) return 'Connected';
    if (s.contains('sent') || s.contains('awaiting')) return 'Request Sent';
    if (s.contains('request')) return 'Incoming Request';
    if (s.contains('rejected')) return 'Rejected';
    return 'New Match';
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: outlined
              ? null
              : LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: outlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(20),
          border: outlined ? Border.all(color: color, width: 1.5) : null,
          boxShadow: outlined
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: outlined ? color : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: outlined ? color : Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
