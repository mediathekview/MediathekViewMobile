import 'package:flutter/material.dart';
import 'package:flutter_ws/database/database_manager.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/model/video_rating.dart';
import 'package:logging/logging.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

class StarRating extends StatelessWidget {
  var onRatingChanged;
  VideoRating rating;
  Video video;
  DatabaseManager databaseManager;
  double size;
  bool ratingAllowed;

  final Logger logger = new Logger('VideoWidget');
  AppSharedState stateContainer;

  StarRating(this.rating, this.video, this.ratingAllowed,
      {this.onRatingChanged, this.size});

  @override
  Widget build(BuildContext context) {
    stateContainer = AppSharedStateContainer.of(context);
    databaseManager = stateContainer.appState.databaseManager;
    checkIfAlreadyRated();

    double roundedRating;
    double previousLocalUserRating;
    if (rating != null) {
      if (rating.rating_sum < 0) {
        logger.warning("Invalid rating of " +
            rating.rating_sum.toString() +
            "for video " +
            video.title);
        return new Container();
      }

      num s = (rating.rating_sum / rating.rating_count) * 2;
      if (s.isNaN || s.isInfinite) {
        logger.warning(
            "Rating sum divided by rating count is either NaN or Infinitive. Sum: " +
                rating.rating_sum.toString() +
                " Count: " +
                rating.rating_count.toString());
        return new Container();
      }

      roundedRating = s.round() / 2;
      previousLocalUserRating = rating.local_user_rating;
    } else {
      roundedRating = 0;
    }

    return new Container(
      margin: new EdgeInsets.only(left: 2.0, top: 5.0),
      alignment: FractionalOffset.topRight,
      child: SmoothStarRating(
        allowHalfRating: false,
        size: size != null ? size : 40.0,
        onRatingChanged: (newLocalRating) {
          if (!ratingAllowed) {
            return;
          }

          VideoRating cachedRating =
              stateContainer.appState.ratingCache[video.id];
          if (cachedRating == null) {
            logger.info("First rating for video: " + newLocalRating.toString());
            stateContainer.appState.ratingCache.putIfAbsent(
                video.id,
                () => new VideoRating(
                    video_id: video.id,
                    rating_sum: newLocalRating,
                    rating_count: 1,
                    local_user_rating: newLocalRating,
                    channel: video.channel,
                    topic: video.topic,
                    title: video.title,
                    timestamp: video.timestamp,
                    duration: video.duration,
                    size: video.size,
                    url_video: video.url_video));

            updateDatabaseWithRating(newLocalRating);
            onRatingChanged();
            return;
          }

          stateContainer.appState.ratingCache.update(video.id, (old) {
            if (cachedRating.local_user_rating == null) {
              //first local rating on already existing rating
              logger.info("First local rating on already existing rating : " +
                  newLocalRating.toString());

              old.rating_sum = old.rating_sum + newLocalRating;
              old.rating_count = old.rating_count + 1;
              old.local_user_rating = newLocalRating;
              return old;
            }
            //there has been a previous local rating already. Update rating accordingly
            logger.info("Local rating on already existing rating. New : " +
                newLocalRating.toString() +
                ". Previous" +
                previousLocalUserRating.toString());

            old.rating_sum =
                old.rating_sum - previousLocalUserRating + newLocalRating;
            old.local_user_rating = newLocalRating;
            return old;
          });

          updateDatabaseWithRating(newLocalRating);
          onRatingChanged();
        },
        starCount: 5,
        rating: roundedRating,
        color: getColor(previousLocalUserRating != null, roundedRating),
        borderColor: getColor(previousLocalUserRating != null, roundedRating),
      ),
    );
  }

  Color getColor(bool ratedByMeAlready, double rating) {
    if (ratedByMeAlready) {
      return Color(0xffffbf00);
    } else if (rating == 0) {
      return Colors.grey;
    } else {
      return Colors.green;
    }
  }

  void updateDatabaseWithRating(double rating) {
    databaseManager.getVideoEntity(video.id).then((VideoEntity entity) {
      if (entity == null) {
        logger.info("Inserting new VideoEntity because of new local rating");
        //Insert into db with taskId. Once finished downloading, the filepath and filename will be updated
        VideoEntity entity = VideoEntity.fromVideo(video);
        entity.rating = rating;
        databaseManager.insert(entity).then((data) {
          logger.info("Added rating to Database");
        });
      } else {
        logger.info("Updating VideoEntity because of new local rating");
        entity.rating = rating;
        databaseManager.updateVideoEntity(entity).then((rowsUpdated) {
          logger.info("Updated " + rowsUpdated.toString() + " rows for rating");
        });
      }
      return entity;
    });
  }

  // Query Database to check if user already rated the video. Only queries if ratingsCache does not have an local_user_rating.
  // Does update cache
  void checkIfAlreadyRated() {
    databaseManager.getVideoEntity(video.id).then((VideoEntity entity) {
      if (entity != null && entity.rating != null) {
        VideoRating cachedRating =
            stateContainer.appState.ratingCache[video.id];

        if (cachedRating == null) {
          logger.warning(
              "Recognized rating from db that is not on the server for video " +
                  video.id);
          stateContainer.appState.ratingCache.putIfAbsent(
              video.id,
              () => new VideoRating(
                  video_id: video.id,
                  rating_sum: entity.rating,
                  rating_count: 1,
                  local_user_rating: entity.rating));

          return entity;
        }

        if (cachedRating.local_user_rating != entity.rating) {
          logger.info("Video is already rated. Updating state " + entity.id);
          stateContainer.appState.ratingCache.update(video.id, (old) {
            old.setLocalUserRating(entity.rating);
            old.setLocalUserRatingSavedFromDb(entity.rating);
            return old;
          });
          //trigger state reload
          if (onRatingChanged != null) {
            onRatingChanged();
          }
        }
      }
      return entity;
    });
  }
}
