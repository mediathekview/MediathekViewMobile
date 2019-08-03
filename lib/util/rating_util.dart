import 'dart:convert';

import 'package:flutter_ws/model/video_rating.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class RatingUtil {
  static Logger logger = new Logger('VideoWidget');

  static const githubInsertUrl =
      "https://raw.githubusercontent.com/mediathekview/MediathekViewMobile/master/assets/cloudfunctions/insertRating";
  static const githubUpdateUrl =
      "https://raw.githubusercontent.com/mediathekview/MediathekViewMobile/master/assets/cloudfunctions/updateRating";
  static const githubInsertDifUrl =
      "https://raw.githubusercontent.com/mediathekview/MediathekViewMobile/master/assets/cloudfunctions/insertRatingDif";
  static const githubAllRatingsUrl =
      "https://raw.githubusercontent.com/mediathekview/MediathekViewMobile/master/assets/cloudfunctions/getAllRatings";
  static const githubBestRatedOverallUrl =
      "https://raw.githubusercontent.com/mediathekview/MediathekViewMobile/master/assets/cloudfunctions/getBestRatedOverall";
  static const githubBestRatedToday =
      "https://raw.githubusercontent.com/mediathekview/MediathekViewMobile/master/assets/cloudfunctions/getBestRatedToday";

  static Future<Map<String, VideoRating>> loadAllRatings() async {
    return getAllRatingUrl().then((url) => _getRatings(url));
  }

  static Future<Map<String, VideoRating>> loadBestRatingsOverall() async {
    return getBestRatedOverallUrl().then((url) => _getRatings(url));
  }

  static Future<Map<String, VideoRating>> loadBestRatingsToday() async {
    return getBestRatedTodayUrl().then((url) => _getRatings(url));
  }

  static Future<Map<String, VideoRating>> _getRatings(
      String queryString) async {
    final response = await http.get(queryString);
    String body = utf8.decode(response.bodyBytes);
    if (response.statusCode == 200) {
      Map<String, VideoRating> ratingCache = new Map();
      (json.decode(body) as List)
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

  static Future<String> getInsertRatingUrl() {
    return getResponseBodyAsString(githubInsertUrl);
  }

  static Future<String> getUpdateRatingUrl() {
    return getResponseBodyAsString(githubUpdateUrl);
  }

  static Future<String> getInsertDifRatingUrl() {
    return getResponseBodyAsString(githubInsertDifUrl);
  }

  static Future<String> getAllRatingUrl() {
    return getResponseBodyAsString(githubAllRatingsUrl);
  }

  static Future<String> getBestRatedOverallUrl() {
    return getResponseBodyAsString(githubBestRatedOverallUrl);
  }

  static Future<String> getBestRatedTodayUrl() {
    return getResponseBodyAsString(githubBestRatedToday);
  }

  static Future<String> getResponseBodyAsString(String url) async {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw new Exception("Failed to get response from " +
          url +
          ". Status Code: " +
          response.statusCode.toString());
    }
  }
}
