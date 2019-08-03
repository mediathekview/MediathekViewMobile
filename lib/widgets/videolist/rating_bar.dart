import 'package:flutter/material.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/model/video_rating.dart';
import 'package:flutter_ws/widgets/videolist/star_rating.dart';

class RatingBar extends StatelessWidget {
  final VideoRating rating;
  final Video video;
  onRatingChanged ratingChanged;
  bool isExtendet;
  double size;
  TextStyle textStyle;
  bool showOnlyRatingCount;
  bool ratingAllowed;

  RatingBar(this.isExtendet, this.rating, this.video, this.textStyle,
      this.showOnlyRatingCount, this.ratingAllowed,
      {this.ratingChanged, this.size});

  @override
  Widget build(BuildContext context) {
    String bewertung = "";

    if (!isExtendet) {
      return new Container();
    }

    if (rating != null && rating.rating_count != 0 && !showOnlyRatingCount) {
      bewertung = rating.rating_count == 1 ? " Bewertung" : " Bewertungen";
    }
    return new Padding(
      padding: EdgeInsets.only(left: 30.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new StarRating(
            rating,
            video,
            ratingAllowed,
            onRatingChanged: ratingChanged,
            size: size,
          ),
          new Container(width: 10.0),
          rating == null
              ? new Container()
              : new Text(
                  "( " + rating.rating_count.toString() + bewertung + " )",
                  style: textStyle,
                ),
        ],
      ),
    );
  }
}
