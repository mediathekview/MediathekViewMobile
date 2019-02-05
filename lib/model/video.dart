class Video {
  String id;
  String channel;
  String topic;
  String description;
  String title;
  int timestamp;
  var duration;
  int size;
  String url_website;
  String url_video_low;
  String url_video_hd;
  String filmlisteTimestamp;
  String url_video;
  String url_subtitle;


  Video(this.id);

  Video.fromMap(Map<String, dynamic> json)
      : id = json['id'],
        channel = json['channel'],
        topic = json['topic'],
        description = json['description'],
        title = json['title'],
        timestamp = json['timestamp'],
        duration = json['duration'],
        size = json['size'],
        url_website = json['url_website'],
        url_video_low = json['url_video_low'],
        url_video_hd = json['url_video_hd'],
        filmlisteTimestamp = json['filmlisteTimestamp'],
        url_video = json['url_video'],
        url_subtitle = json['url_subtitle'];

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'channel': channel,
      'topic': topic,
      'description': description,
      'title': title,
      'timestamp': timestamp,
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
}