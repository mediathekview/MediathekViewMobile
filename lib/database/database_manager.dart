import 'dart:async';

import 'package:flutter_ws/database/channel_favorite_entity.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

final String columnId = "_id";
final String columnTitle = "title";
final String columnDone = "done";

class DatabaseManager {
  final Logger logger = new Logger('DatabaseManager');
  Database db;

  Future open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      String videoTableSQL = getVideoTableSQL();
      String channelFavoritesSQL = getChannelFavoriteSQL();
      logger.fine("DB MANAGER: Executing " + videoTableSQL);
      await db.execute(videoTableSQL);
      logger.fine("DB MANAGER: Executing " + channelFavoritesSQL);
      await db.execute(channelFavoritesSQL);
    });
  }

  Future close() async => db.close();
  Future deleteDb(String path) async => deleteDatabase(path);

  String getVideoTableSQL() {
    var sql = '''
create table ''' +
        VideoEntity.TABLE_NAME +
        ''' ( 
       ''' +
        VideoEntity.idColumn +
        ''' text primary key, 
         ''' +
        VideoEntity.task_idColumn +
        ''' text not null,
       ''' +
        VideoEntity.channelColumn +
        ''' text not null,
       ''' +
        VideoEntity.topicColumn +
        ''' text not null,
       ''' +
        VideoEntity.descriptionColumn +
        ''' text,
       ''' +
        VideoEntity.titleColumn +
        ''' text not null,
       ''' +
        VideoEntity.timestampColumn +
        ''' integer,
       ''' +
        VideoEntity.durationColumn +
        ''' text,
       ''' +
        VideoEntity.sizeColumn +
        ''' integer,
       ''' +
        VideoEntity.url_websiteColumn +
        ''' text,
       ''' +
        VideoEntity.url_video_lowColumn +
        ''' text,
       ''' +
        VideoEntity.url_video_hdColumn +
        ''' text,
       ''' +
        VideoEntity.filmlisteTimestampColumn +
        ''' text,
       ''' +
        VideoEntity.url_videoColumn +
        ''' text not null,
       ''' +
        VideoEntity.url_subtitleColumn +
        ''' text,
       ''' +
        VideoEntity.filePathColumn +
        ''' text DEFAULT '',
       ''' +
        VideoEntity.fileNameColumn +
        ''' text DEFAULT '',
       ''' +
        VideoEntity.mimeTypeColumn +
        ''' text)
     ''';
    return sql;
  }

  Future insert(VideoEntity video) async {
    await db.insert(VideoEntity.TABLE_NAME, video.toMap());
  }

  Future<int> deleteVideoEntity(String id) async {
    return db.delete(VideoEntity.TABLE_NAME,
        where: VideoEntity.idColumn + " = ?", whereArgs: [id]);
  }

  Future<Set<VideoEntity>> getAllDownloadedVideos() async {
    //Downloaded videos have a filename set when the download finished, otherwise they are current downloads
    List<Map> result = await db.query(VideoEntity.TABLE_NAME,
        columns: getColums(),
        where: VideoEntity.fileNameColumn + " != ?",
        whereArgs: ['']);
    if (result != null && result.length > 0) {
      return result.map((raw) => new VideoEntity.fromMap(raw)).toSet();
    }
    return new Set();
  }

  Future<int> updateVideoEntity(VideoEntity entity) async {
    return await db.update(VideoEntity.TABLE_NAME, entity.toMap(),
        where: VideoEntity.task_idColumn + " = ?", whereArgs: [entity.task_id]);
  }

  Future<VideoEntity> getVideoEntity(String id) async {
    List<Map> maps = await db.query(VideoEntity.TABLE_NAME,
        columns: getColums(),
        where: VideoEntity.idColumn + " = ?",
        whereArgs: [id]);
    if (maps.length > 0) {
      return new VideoEntity.fromMap(maps.first);
    }
    return null;
  }

  Future<VideoEntity> getVideoEntityForTaskId(String taskId) async {
    List<Map> maps = await db.query(VideoEntity.TABLE_NAME,
        columns: getColums(),
        where: VideoEntity.task_idColumn + " = ?",
        whereArgs: [taskId]);
    if (maps.length > 0) {
      return new VideoEntity.fromMap(maps.first);
    }
    return null;
  }

  Future<Set<VideoEntity>> getVideoEntitiesForTaskIds(List<String> list) async {
    String whereClause = _getConcatinatedWhereClause(list);
    logger.fine("Build WHERE CLAUSE: " + whereClause);
    List<Map> resultList = await db.query(VideoEntity.TABLE_NAME,
        columns: getColums(), where: whereClause, whereArgs: list);
    if (list.length != resultList.length) {
      logger
          .severe("Download running that we do not have in the Video database");
    }
    if (resultList.isEmpty) {
      return new Set();
    }

    return resultList.map((result) => VideoEntity.fromMap(result)).toSet();
  }

  String _getConcatinatedWhereClause(List<String> list) {
    String where = "";

    if (list.length == 0) {
      return where;
    } else if (list.length == 1) {
      return VideoEntity.task_idColumn + " = ? ";
    }

    for (int i = 0; i < list.length; i++) {
      if (i == list.length - 1) {
        where = where + VideoEntity.task_idColumn + " = ?";
        break;
      }
      where = where + VideoEntity.task_idColumn + " = ? OR ";
    }

    return where;
  }

  Future<VideoEntity> getDownloadedVideo(id) async {
    List<Map> maps = await db.query(VideoEntity.TABLE_NAME,
        columns: getColums(),
        where: VideoEntity.idColumn +
            " = ? AND " +
            VideoEntity.fileNameColumn +
            " != '' ",
        whereArgs: [id]);
    if (maps.length > 0) {
      return new VideoEntity.fromMap(maps.first);
    }
    return null;
  }

  List<String> getColums() {
    return [
      VideoEntity.idColumn,
      VideoEntity.task_idColumn,
      VideoEntity.channelColumn,
      VideoEntity.topicColumn,
      VideoEntity.descriptionColumn,
      VideoEntity.titleColumn,
      VideoEntity.timestampColumn,
      VideoEntity.durationColumn,
      VideoEntity.sizeColumn,
      VideoEntity.url_websiteColumn,
      VideoEntity.url_video_lowColumn,
      VideoEntity.url_video_hdColumn,
      VideoEntity.filmlisteTimestampColumn,
      VideoEntity.url_videoColumn,
      VideoEntity.filePathColumn,
      VideoEntity.fileNameColumn,
      VideoEntity.mimeTypeColumn
    ];
  }

  //&&&&&&&&&&&&&Favorite Channels &&&&&&&&&&&&&&&&&&&

  Future<Set<ChannelFavoriteEntity>> getAllChannelFavorites() async {
    List<Map> result =
        await db.query(ChannelFavoriteEntity.TABLE_NAME, columns: [
      ChannelFavoriteEntity.nameColumn,
      ChannelFavoriteEntity.groupnameColumn,
      ChannelFavoriteEntity.logoColumn,
      ChannelFavoriteEntity.urlColumn
    ]);
    if (result != null && result.length > 0) {
      return result
          .map((raw) => new ChannelFavoriteEntity.fromMap(raw))
          .toSet();
    }
    return new Set();
  }

  String getChannelFavoriteSQL() {
    var sql = '''
create table ''' +
        ChannelFavoriteEntity.TABLE_NAME +
        ''' ( 
       ''' +
        ChannelFavoriteEntity.nameColumn +
        ''' text primary key, 
       ''' +
        ChannelFavoriteEntity.groupnameColumn +
        ''' text not null,
       ''' +
        ChannelFavoriteEntity.logoColumn +
        ''' text not null,
       ''' +
        ChannelFavoriteEntity.urlColumn +
        ''' text not null)
     ''';
    return sql;
  }

  Future deleteChannelFavorite(String id) async {
    return await db.delete(ChannelFavoriteEntity.TABLE_NAME,
        where: ChannelFavoriteEntity.nameColumn + " = ?", whereArgs: [id]);
  }

  Future insertChannelFavorite(ChannelFavoriteEntity entity) async {
    await db.insert(ChannelFavoriteEntity.TABLE_NAME, entity.toMap());
  }
}
