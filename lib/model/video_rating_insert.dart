class VideoRatingInsert {
  final String video_id;
  final double rating;
  final String channel;
  final String topic;
  final String description;
  final String title;
  final int timestamp;
  var duration;
  final int size;
  final String url_video;

  VideoRatingInsert(
      this.video_id,
      this.rating,
      this.channel,
      this.topic,
      this.description,
      this.title,
      this.timestamp,
      this.duration,
      this.size,
      this.url_video);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'video_id': video_id,
      'rating': rating,
      'channel': channel,
      'topic': topic,
      'description': description,
      'title': title,
      'timestamp': timestamp,
      'duration': duration,
      'size': size,
      'url_video': url_video,
    };
  }
}
