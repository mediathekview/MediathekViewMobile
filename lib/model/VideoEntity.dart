import 'package:flutter_ws/model/Video.dart';

class VideoEntity {
  static final String TABLE_NAME = "videos";

  String id;
  String channel; //ARD
  String topic; //Tatort
  String description; //details:  erst anzeigen wenn man drauf klickt
  String title; // Der Frühling kommt bald
  int timestamp; //unten rechts
  var duration; //unten links
  int size; //details
  String url_website;
  String url_video_low;
  String url_video_hd;
  String filmlisteTimestamp; // weglassen?
  String url_video;
  String url_subtitle;

  //for the db entity
  String filePath;
  String fileName;
  String mimeType;

  //column names
  static final  String idColumn = "id";
  static final  String channelColumn = "channel";
  static final  String topicColumn = "topic";
  static final  String descriptionColumn = "description";
  static final  String titleColumn = "title";
  static final  String timestampColumn = "timestamp";
  static final  String durationColumn = "duration";
  static final  String sizeColumn = "size";
  static final  String url_websiteColumn = "url_website";
  static final  String url_video_lowColumn = "url_video_low";
  static final  String url_video_hdColumn = "url_video_hd";
  static final  String filmlisteTimestampColumn = "filmlisteTimestamp";
  static final  String url_videoColumn = "url_video";
  static final  String url_subtitleColumn = "url_subtitle";
  static final  String filePathColumn = "filePath";
  static final  String fileNameColumn = "fileName";
  static final  String mimeTypeColumn = "mimeType";


  VideoEntity(this.id, this.channel, this.topic, this.description,
      this.title, this.timestamp, this.duration, this.size, this.url_website,
      this.url_video_low, this.url_video_hd, this.filmlisteTimestamp,
      this.url_video, this.url_subtitle, {this.filePath, this.fileName, this.mimeType});

  static VideoEntity fromVideo(Video video){
    return new VideoEntity(video.id, video.channel,  video.topic, video.description, video.title, video.timestamp, video.duration, video.size, video.url_website, video.url_video_low, video.url_video_hd, video.filmlisteTimestamp, video.url_video, video.url_subtitle);
  }

  VideoEntity.fromMap(Map<String, dynamic> json)
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
        url_subtitle = json['url_subtitle'],
        filePath = json['filePath'],
        fileName = json['fileName'],
        mimeType = json['mimeType'];

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
      'filePath': filePath,
      'fileName': fileName,
      'mimeType': mimeType,
    };
    return map;
  }
}