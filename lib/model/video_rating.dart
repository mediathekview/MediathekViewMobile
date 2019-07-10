class VideoRating {
  final String video_id;
  double rating_sum;
  int rating_count;
  double local_user_rating;
  double local_user_rating_saved_from_db;
  bool setAlreadyFromDB = false;

  //video information
  String channel;
  String topic;
  String description;
  String title;
  int timestamp;
  var duration;
  int size;
  String url_video;

  VideoRating(
      {this.video_id,
      this.rating_sum,
      this.rating_count,
      this.local_user_rating,
      this.local_user_rating_saved_from_db,
      this.channel,
      this.topic,
      this.title,
      this.timestamp,
      this.duration,
      this.size,
      this.url_video});

  factory VideoRating.fromJson(Map<String, dynamic> json) {
    var rating_sum = json['rating_sum'];
    double rating_sum_parsed;

    if (rating_sum is int) {
      rating_sum_parsed = rating_sum.toDouble();
    } else if (rating_sum is double) {
      rating_sum_parsed = rating_sum;
    }

    return new VideoRating(
        video_id: json['video_id'],
        rating_sum: rating_sum_parsed,
        rating_count: json['rating_count'],
        channel: json['channel'],
        topic: json['topic'],
        title: json['title'],
        timestamp: json['timestamp'],
        duration: json['duration'],
        size: json['size'],
        url_video: json['url_video']);
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': video_id,
      'rating_sum': rating_sum,
      'rating_count': rating_count,
      'channel': channel,
      'topic': topic,
      'description': description,
      'title': title,
      'timestamp': timestamp,
      'duration': duration,
      'size': size,
      'url_video': url_video,
    };
    return map;
  }

  void setLocalUserRating(double rating) {
    local_user_rating = rating;
  }

  /*
  Only set once to be able to know if the user made another change - only update diff to server
   */
  void setLocalUserRatingSavedFromDb(double rating) {
    if (setAlreadyFromDB == false) {
      setAlreadyFromDB = true;
      local_user_rating_saved_from_db = rating;
    }
  }
}
