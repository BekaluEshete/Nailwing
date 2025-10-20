// features/recommendations/views/widgets/place_card.dart
import 'package:flutter/material.dart';
import 'package:nilewing/features/recommendation/model/recommendation_model.dart';

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
                            Text(
                              place.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
        Text(
          '${place.distance} • ${place.walkTime}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
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
