import 'dart:async';
import 'package:flutter_ws/model/VideoEntity.dart';
import 'package:sqflite/sqflite.dart';

final String columnId = "_id";
final String columnTitle = "title";
final String columnDone = "done";

class DatabaseManager {
  Database db;

   Future open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
    /*  var sql = '''
create table $TABLE_NAME (
  $columnId integer primary key autoincrement,
  $columnTitle text not null,
  $columnDone integer not null)
''';*/

      var sql = '''
create table ''' + VideoEntity.TABLE_NAME + ''' ( 
  ''' + VideoEntity.idColumn + ''' text primary key, 
  ''' + VideoEntity.channelColumn + ''' text not null,
  ''' + VideoEntity.topicColumn + ''' text not null,
  ''' + VideoEntity.descriptionColumn + ''' text,
  ''' + VideoEntity.titleColumn + ''' text not null,
  ''' + VideoEntity.timestampColumn + ''' integer,
  ''' + VideoEntity.durationColumn + ''' text,
  ''' + VideoEntity.sizeColumn + ''' integer,
  ''' + VideoEntity.url_websiteColumn + ''' text,
  ''' + VideoEntity.url_video_lowColumn + ''' text,
  ''' + VideoEntity.url_video_hdColumn + ''' text,
  ''' + VideoEntity.filmlisteTimestampColumn + ''' text,
  ''' + VideoEntity.url_videoColumn + ''' text not null,
  ''' + VideoEntity.url_subtitleColumn + ''' text,
  ''' + VideoEntity.filePathColumn + ''' text not null,
  ''' + VideoEntity.fileNameColumn + ''' text not null,
  ''' + VideoEntity.mimeTypeColumn + ''' text)
''';
      print("DB MANAGER: Executing " + sql);

      await db.execute(sql);
    });

  }

  Future insert(VideoEntity video) async {
    await db.insert(VideoEntity.TABLE_NAME, video.toMap());
  }

  Future<VideoEntity> getVideoEntity(String id) async {
    List<Map> maps = await db.query(VideoEntity.TABLE_NAME,
        columns: [VideoEntity.idColumn, VideoEntity.titleColumn, VideoEntity.filePathColumn, VideoEntity.fileNameColumn, VideoEntity.mimeTypeColumn],
        where: VideoEntity.idColumn + " = ?",
        whereArgs: [id]);
    if (maps.length > 0) {
      return new VideoEntity.fromMap(maps.first);
    }
    return null;
  }

  Future delete(String id) async {
    return await db.delete(VideoEntity.TABLE_NAME, where: VideoEntity.idColumn + " = ?", whereArgs: [id]);
  }

  /*Future<int> update(Todo todo) async {
    return await db.update(TABLE_NAME, todo.toMap(),
        where: "$columnId = ?", whereArgs: [todo.id]);
  }*/

  Future close() async => db.close();
  Future deleteDb(String path) async => deleteDatabase(path);

  Future<Set<VideoEntity>> getAllDownloadedVideos() async {

    List<Map> result = await db.query(VideoEntity.TABLE_NAME,
        columns: [VideoEntity.idColumn, VideoEntity.channelColumn, VideoEntity.topicColumn, VideoEntity.durationColumn, VideoEntity.sizeColumn, VideoEntity.titleColumn, VideoEntity.filePathColumn, VideoEntity.fileNameColumn, VideoEntity.mimeTypeColumn]);
    if (result != null && result.length > 0) {
       return result.map((raw) => new VideoEntity.fromMap(raw)).toSet();
    }
    return new Set();
  }
}
