class ChannelFavoriteEntity {
  static final String TABLE_NAME = "channelfavorite";

  String name;
  String logo; //ARD
  String groupname; //Tatort
  String url; //details:  erst anzeigen wenn man drauf klickt

  //column names
  static final String nameColumn = "name";
  static final String logoColumn = "logo";
  static final String groupnameColumn = "groupname";
  static final String urlColumn = "url";

  ChannelFavoriteEntity(this.name, this.logo, this.groupname, this.url);

//  static ChannelFavoriteEntity fromChannel(Video video){
//    return new ChannelFavoriteEntity(video.id, video.channel,  video.topic, video.description, video.title, video.timestamp, video.duration, video.size, video.url_website, video.url_video_low, video.url_video_hd, video.filmlisteTimestamp, video.url_video, video.url_subtitle);
//  }

  ChannelFavoriteEntity.fromMap(Map<String, dynamic> json)
      : name = json['name'],
        logo = json['logo'],
        groupname = json['groupname'],
        url = json['url'];

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'name': name,
      'logo': logo,
      'groupname': groupname,
      'url': url
    };
    return map;
  }
}
