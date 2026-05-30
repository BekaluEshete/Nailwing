// features/match/view/user_detail_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/features/match/model/match_model.dart';
import 'package:nilewing/features/match/service/match_service.dart';
import 'package:nilewing/core/utils/app_constants.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;
  final VoidCallback onNavigateBack;

  const UserDetailScreen({
    Key? key,
    required this.user,
    required this.onNavigateBack,
  }) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with TickerProviderStateMixin {
  User? _fetchedUser;
  bool _isLoading = true;
  String? _error;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fetched = await MatchService().getUserProfileById(widget.user.id);
      setState(() {
        _fetchedUser = fetched;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _fetchedUser = widget.user; // fallback
      });
      _fadeController.forward();
    }
  }

  User get _user => _fetchedUser ?? widget.user;

  String _avatarUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('http') ? raw : '${AppConstants.baseUrl}$raw';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading ? _buildLoading() : _buildContent(),
    );
  }

  // ─── LOADING ──────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Stack(
      children: [
        _buildBg(),
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(transparent: true),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── MAIN CONTENT ─────────────────────────────────────────────────────────
  Widget _buildContent() {
    return Stack(
      children: [
        _buildBg(),
        FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverHeader(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    _buildStatusRow(),
                    const SizedBox(height: 16),
                    if (_user.bio != null && _user.bio!.isNotEmpty) ...[
                      _buildSection('About', Icons.person_outline_rounded,
                          _buildBio()),
                      const SizedBox(height: 14),
                    ],
                    if (_user.interests.isNotEmpty) ...[
                      _buildSection('Interests', Icons.interests_rounded,
                          _buildInterests()),
                      const SizedBox(height: 14),
                    ],
                    _buildSection('Travel Stats', Icons.flight_rounded,
                        _buildTravelStats()),
                    const SizedBox(height: 14),
                    if (_user.languages.isNotEmpty) ...[
                      _buildSection('Languages', Icons.language_rounded,
                          _buildLanguages()),
                      const SizedBox(height: 14),
                    ],
                    if (_user.favoriteDestination != null) ...[
                      _buildSection('Favourite Destination',
                          Icons.favorite_rounded, _buildFavDest()),
                      const SizedBox(height: 14),
                    ],
                    if (_user.mutualConnections > 0) ...[
                      _buildMutualConnections(),
                      const SizedBox(height: 14),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
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
              child: _blob(200, const Color(0xFFCFFAFE).withOpacity(0.5)),
            ),
            Positioned(
              bottom: -40,
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

  // ─── TOP BAR (for loading state) ──────────────────────────────────────────
  Widget _buildTopBar({bool transparent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onNavigateBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: transparent ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SLIVER HEADER ────────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    final avatarUrl = _avatarUrl(_user.avatar);
    final hasAvatar = avatarUrl.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        onPressed: widget.onNavigateBack,
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
      ),
      actions: [
        if (_error != null)
          IconButton(
            onPressed: _loadUserProfile,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Retry',
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.accent,
                    AppColors.primary.withBlue(220),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Subtle pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.06,
                child: Image.network(
                  'https://www.transparenttextures.com/patterns/cubes.png',
                  repeat: ImageRepeat.repeat,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: hasAvatar
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(large: true),
                              )
                            : _avatarFallback(large: true),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Name + verified
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _user.name,
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
                        if (_user.verified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Nationality · Age · Gender
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: [
                        if (_user.nationality.isNotEmpty)
                          _headerChip(_user.nationality),
                        if (_user.age > 0)
                          _headerChip('${_user.age} yrs'),
                        if (_user.gender.isNotEmpty &&
                            _user.gender != 'other')
                          _headerChip(_user.gender[0].toUpperCase() +
                              _user.gender.substring(1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _avatarFallback({bool large = false}) {
    return Container(
      color: AppColors.primary.withOpacity(0.15),
      child: Center(
        child: Text(
          _user.initials,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: large ? 32 : 16,
          ),
        ),
      ),
    );
  }

  // ─── STATUS ROW ───────────────────────────────────────────────────────────
  Widget _buildStatusRow() {
    return _glassCard(
      child: Row(
        children: [
          // Online status
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _user.isOnline ? Colors.green : Colors.grey[400],
                    shape: BoxShape.circle,
                    boxShadow: _user.isOnline
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _user.isOnline ? 'Active now' : _user.lastSeenText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _user.isOnline ? Colors.green[700] : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.grey[200],
          ),
          // Location
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _user.currentLocation?.isNotEmpty == true
                          ? _user.currentLocation!
                          : 'Location unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION WRAPPER ──────────────────────────────────────────────────────
  Widget _buildSection(String title, IconData icon, Widget content) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  // ─── BIO ──────────────────────────────────────────────────────────────────
  Widget _buildBio() {
    return Text(
      _user.bio!,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
        height: 1.6,
      ),
    );
  }

  // ─── INTERESTS ────────────────────────────────────────────────────────────
  Widget _buildInterests() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _user.interests.map((interest) {
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
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── TRAVEL STATS ─────────────────────────────────────────────────────────
  Widget _buildTravelStats() {
    final stats = _user.travelStats;
    return Row(
      children: [
        _statTile('${stats.countriesVisited}', 'Countries', Icons.public_rounded),
        _statDivider(),
        _statTile('${stats.totalFlights}', 'Flights', Icons.flight_rounded),
        _statDivider(),
        _statTile('${stats.flightsThisYear}', 'This Year', Icons.calendar_today_rounded),
        _statDivider(),
        _statTile(stats.frequentFlyerTier, 'FF Tier', Icons.star_rounded),
      ],
    );
  }

  Widget _statTile(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 40, color: Colors.grey[200]);
  }

  // ─── LANGUAGES ────────────────────────────────────────────────────────────
  Widget _buildLanguages() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _user.languages.map((lang) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                lang,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── FAVOURITE DESTINATION ────────────────────────────────────────────────
  Widget _buildFavDest() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade300],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _user.favoriteDestination!,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  // ─── MUTUAL CONNECTIONS ───────────────────────────────────────────────────
  Widget _buildMutualConnections() {
    return _glassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.people_rounded, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Text(
            '${_user.mutualConnections} mutual connection${_user.mutualConnections == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── GLASS CARD ───────────────────────────────────────────────────────────
  Widget _glassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
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
}
