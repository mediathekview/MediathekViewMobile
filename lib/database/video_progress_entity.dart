class VideoProgressEntity {
  static final String TABLE_NAME = "video_progress";

  String id;
  int progress;
  String channel;
  String topic;
  String description;
  String title;
  int timestamp;
  int timestampLastViewed;
  var duration;
  int size;
  String url_website;
  String url_video_low;
  String url_video_hd;
  String filmlisteTimestamp;
  String url_video;
  String url_subtitle;

  //column names
  static final String idColumn = "id";
  static final String progressColumn = "progress";
  static final String channelColumn = "channel";
  static final String topicColumn = "topic";
  static final String descriptionColumn = "description";
  static final String titleColumn = "title";
  static final String timestampColumn = "timestamp";
  static final String timestampLastViewedColumn = "timestampLastViewed";
  static final String durationColumn = "duration";
  static final String sizeColumn = "size";
  static final String url_websiteColumn = "url_website";
  static final String url_video_lowColumn = "url_video_low";
  static final String url_video_hdColumn = "url_video_hd";
  static final String filmlisteTimestampColumn = "filmlisteTimestamp";
  static final String url_videoColumn = "url_video";
  static final String url_subtitleColumn = "url_subtitle";

  VideoProgressEntity(this.id, this.progress,
      {this.channel,
      this.topic,
      this.description,
      this.title,
      this.timestamp,
      this.timestampLastViewed,
      this.duration,
      this.size,
      this.url_website,
      this.url_video_low,
      this.url_video_hd,
      this.filmlisteTimestamp,
      this.url_video,
      this.url_subtitle});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'progress': progress,
      'channel': channel,
      'topic': topic,
      'description': description,
      'title': title,
      'timestamp': timestamp,
      'timestampLastViewed': timestampLastViewed,
      'duration': duration,
      'size': size,
      'url_website': url_website,
      'url_video_low': url_video_low,
      'url_video_hd': url_video_hd,
      'filmlisteTimestamp': filmlisteTimestamp,
      'url_video': url_video,
      'url_subtitle': url_subtitle,
    };
    return map;
  }

  VideoProgressEntity.fromMap(Map<String, dynamic> json)
      : id = json['id'],
        progress = json['progress'],
        channel = json['channel'],
        topic = json['topic'],
        description = json['description'],
        title = json['title'],
        timestamp = json['timestamp'],
        timestampLastViewed = json['timestampLastViewed'],
        duration = json['duration'],
        size = json['size'],
        url_website = json['url_website'],
        url_video_low = json['url_video_low'],
        url_video_hd = json['url_video_hd'],
        filmlisteTimestamp = json['filmlisteTimestamp'],
        url_video = json['url_video'],
        url_subtitle = json['url_subtitle'];
}
