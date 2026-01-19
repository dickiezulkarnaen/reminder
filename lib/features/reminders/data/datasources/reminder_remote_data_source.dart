import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ReminderRemoteDataSource {

  Future<String?> getLocationName({
    required double lat,
    required double lng,
    required String accessToken,
  }) async {
    try {
      log('getLocationName start :::: $lat, $lng, $accessToken');
      final uri = Uri.https(
        'api.mapbox.com',
        '/geocoding/v5/mapbox.places/$lng,$lat.json',
        {
          'access_token': accessToken,
          'limit': '1',
          'language': 'en',
        },
      );

      final res = await http.get(uri);
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final features = (body['features'] as List?) ?? [];
      if (features.isEmpty) return null;

      return (features.first as Map<String, dynamic>)['place_name'] as String?;
    } catch (e) {
      log('Error while reverse geocoding: ${e.runtimeType} => ${e.toString()}');
      return null;
    }
  }
}