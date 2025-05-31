import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/mapbox_search_models.dart';
import 'package:sport_log/helpers/result.dart';

class MapboxSearchBoxApi {
  MapboxSearchBoxApi({required this.accessToken});

  static const String _baseApiUrl =
      'https://api.mapbox.com/search/searchbox/v1/forward';

  final String accessToken;

  Future<Result<List<Feature>, String>> search({
    required String searchText,
    int limit = 10, // number of results (max 10)
    LatLng? proximity, // bias results around this location
    List<String>? types, // e.g., ['poi', 'address']
    bool autocomplete = true,
  }) async {
    final queryParameters = <String, String>{
      'q': searchText,
      'access_token': accessToken,
    };

    queryParameters['limit'] = limit.toString();
    if (proximity != null) {
      queryParameters['proximity'] = '${proximity.lng},${proximity.lat}';
    }
    if (types != null && types.isNotEmpty) {
      queryParameters['types'] = types.join(',');
    }
    queryParameters['auto_complete'] = autocomplete.toString();

    final uri = Uri.parse(
      _baseApiUrl,
    ).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedJson = json.decode(response.body) as Map<String, dynamic>;
        return Ok(MapboxForwardResponse.fromJson(decodedJson).features);
      } else {
        return Err(
          'Failed to load search results: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      return Err('Error during forward search: $e');
    }
  }
}
