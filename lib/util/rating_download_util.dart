import 'dart:convert';

import 'package:flutter_ws/model/video_rating.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class RatingUtil {
  static const allRatingsQueryUrl =
      "https://us-central1-kubernetes-hard-way-227412.cloudfunctions.net/MySQLSelect";
  static const bestRatedVideosQueryUrl =
      "https://us-central1-kubernetes-hard-way-227412.cloudfunctions.net/MySQLSelectBestRated";
  static const hotVideosTodayQueryUrl =
      "https://us-central1-kubernetes-hard-way-227412.cloudfunctions.net/MySQLSelectHotVideosToday";
  static Logger logger = new Logger('VideoWidget');

  static Future<Map<String, VideoRating>> loadAllRatings() async {
    return _getRatings(allRatingsQueryUrl);
  }

  static Future<Map<String, VideoRating>> loadBestRatedAllTime() async {
    return _getRatings(bestRatedVideosQueryUrl);
  }

  static Future<Map<String, VideoRating>> loadHotRatingsToday() async {
    return _getRatings(hotVideosTodayQueryUrl);
  }

  static Future<Map<String, VideoRating>> _getRatings(
      String queryString) async {
    final response = await http.get(queryString);
    if (response.statusCode == 200) {
      Map<String, VideoRating> ratingCache = new Map();
      (json.decode(response.body) as List)
          .map((data) => new VideoRating.fromJson(data))
          .forEach((rating) {
        ratingCache.putIfAbsent(rating.video_id, () => rating);
      });
      return ratingCache;
    } else {
      logger.warning("Failed to load video ratings from " +
          queryString +
          ". Status Code: " +
          response.statusCode.toString());
      return new Map();
    }
  }
}
