import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/model/video_rating.dart';
import 'package:flutter_ws/widgets/overviewSection/util.dart';

class CarouselWithIndicator extends StatefulWidget {
  Map<String, VideoRating> videosWithRatingInformation;
  double viewportFraction;
  bool autoPlay;
  bool enlargeCenterPage;
  bool showIndexBar;
  double width;
  Orientation orientation;
  Map<String, VideoProgressEntity> videosWithPlaybackProgress;

  CarouselWithIndicator(
      {this.videosWithRatingInformation,
      this.viewportFraction,
      this.autoPlay,
      this.enlargeCenterPage,
      this.showIndexBar,
      this.videosWithPlaybackProgress,
      this.width,
      this.orientation});

  @override
  _CarouselWithIndicatorState createState() => _CarouselWithIndicatorState();
}

class _CarouselWithIndicatorState extends State<CarouselWithIndicator> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.videosWithRatingInformation == null) {
      return new Container(
        width: widget.width,
        height: widget.width / 16 * 9,
        child: new Center(
          child: new CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(Colors.red),
            strokeWidth: 2.0,
            backgroundColor: Colors.white,
          ),
        ),
      );
    }

    if (widget.videosWithRatingInformation.length == 0) {
      return Container();
    }

    if (widget.orientation == Orientation.landscape) {
      return new Container(
        height: widget.width / 2 / 16 * 9,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: Util.getSliderItems(widget.videosWithRatingInformation,
              widget.videosWithPlaybackProgress, widget.width / 2),
        ),
      );
    }

    final List sliderItems = Util.getSliderItems(
            widget.videosWithRatingInformation,
            widget.videosWithPlaybackProgress,
            widget.width)
        .toList();

    if (sliderItems.length == 1) {
      return sliderItems[0];
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider(
          items: sliderItems,
          viewportFraction: widget.viewportFraction,
          autoPlay: widget.autoPlay,
          enlargeCenterPage: widget.enlargeCenterPage,
          // force image to same aspect ratio to avoid pixel overflow
          aspectRatio: 16 / 9,
          pauseAutoPlayOnTouch: Duration(seconds: 5),
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        widget.showIndexBar
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: getBubbleIndexBar(
                    widget.videosWithRatingInformation.length),
              )
            : new Container(),
      ],
    );
  }

  final Widget placeholder = new Container(color: Colors.grey);

  List<Widget> getBubbleIndexBar(int length) {
    List<Widget> result = new List();
    for (var i = 0; i < length; i++) {
      Widget rect = getSingleBubbleIndicator(i);
      result.add(rect);
    }
    return result;
  }

  Widget getSingleBubbleIndicator(index) {
    return Container(
      width: 8.0,
      height: 8.0,
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentIndex == index ? Colors.white : Colors.grey),
    );
  }
}
