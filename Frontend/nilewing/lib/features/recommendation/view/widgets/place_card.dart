// features/recommendations/views/widgets/place_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nilewing/features/recommendation/model/recommendation_model.dart';
import 'package:nilewing/core/utils/app_constants.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const PlaceCard({
    Key? key,
    required this.place,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getTypeIcon(place.type),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                place.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRatingRow(place),
                        const SizedBox(height: 8),
                        _buildLocationRow(place),
                        const SizedBox(height: 8),
                        Text(
                          place.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (place.roomPrice != null ||
                            place.specialties != null) ...[
                          const SizedBox(height: 8),
                          _buildPriceOrSpecialties(place),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onFavoriteTap,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFooter(place),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTypeIcon(PlaceType type) {
    switch (type) {
      case PlaceType.hotel:
        return Icon(Icons.hotel, size: 16, color: Colors.blue);
      case PlaceType.cafe:
        return Icon(Icons.coffee, size: 16, color: Colors.blue);
      case PlaceType.restaurant:
        return Icon(Icons.restaurant, size: 16, color: Colors.blue);
    }
  }

  Widget _buildRatingRow(Place place) {
    return Row(
      children: [
        _buildStars(place.rating),
        const SizedBox(width: 4),
        Text(
          place.rating.toString(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        Text(
          '(${place.reviewCount})',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Text(
          _getPriceLevelSymbol(place.priceLevel),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 12,
          color: index < rating.floor() ? Colors.amber : Colors.grey[300],
        );
      }),
    );
  }

  String _getPriceLevelSymbol(int level) {
    final euros = '€' * level;
    final dots = '·' * (4 - level);
    return euros + dots;
  }

  Widget _buildLocationRow(Place place) {
    return Row(
      children: [
        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            place.distance.isNotEmpty 
                ? '${place.distance} • ${place.walkTime}'
                : place.walkTime,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        InkWell(
          onTap: () => _openGoogleMaps(place),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text(
                  'Directions',
                  style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openGoogleMaps(Place place) async {
    final lat = place.coordinates.lat;
    final lng = place.coordinates.lng;
    
    // Create Google Maps URL for directions using the provided API key
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking&key=${AppConstants.googleMapsApiKey}';
    
    final uri = Uri.parse(url);
    
    try {
      // Bypass canLaunchUrl check because it will return false on Android 11+ without AndroidManifest.xml queries
      final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      
      if (!launched) {
        // Fallback: Geo Intent
        final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(place.name)})');
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication); // Geo intents must be external
      }
    } catch (e) {
      print('Error opening Google Maps: $e');
    }
  }

  Widget _buildPriceOrSpecialties(Place place) {
    if (place.roomPrice != null) {
      return Text(
        place.roomPrice!,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.blue,
        ),
      );
    } else if (place.specialties != null && place.specialties!.isNotEmpty) {
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: place.specialties!.take(3).map((specialty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Text(
              specialty,
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      );
    }
    return const SizedBox();
  }

  Widget _buildFooter(Place place) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: place.openNow ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              place.openNow ? 'Open now' : 'Closed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: place.openNow ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (place.wifi) Icon(Icons.wifi, size: 16, color: Colors.grey[600]),
            if (place.wifi) const SizedBox(width: 4),
            if (place.parking)
              Icon(Icons.local_parking, size: 16, color: Colors.grey[600]),
            if (place.type == PlaceType.cafe)
              Icon(Icons.coffee, size: 16, color: Colors.blue),
            if (place.type == PlaceType.restaurant)
              Icon(Icons.restaurant, size: 16, color: Colors.blue),
          ],
        ),
      ],
    );
  }
}
