import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:intro_slider/slide_object.dart';

class IntroScreen extends StatefulWidget {
  var onDonePressed;
  IntroScreen({Key key, this.onDonePressed}) : super(key: key);

  @override
  IntroScreenState createState() => new IntroScreenState();
}

class IntroScreenState extends State<IntroScreen> {
  List<Slide> slides = new List();

  @override
  void initState() {
    super.initState();

    slides.add(
      new Slide(
        title: "Suchen und Downloaden",
        maxLineTitle: 2,
        marginTitle: new EdgeInsets.only(top: 20.0, bottom: 20.0),
        description: "Durchsuchen von öffentlich-rechtlichen Mediatheken.",
        //pathImage: "assets/intro/intro_slider_1.png",
        centerWidget: new Container(
            padding: EdgeInsets.only(left: 20.0, right: 20.0),
            child: new Image(
                image: new AssetImage("assets/intro/intro_slider_1.png"))),
        backgroundColor: Color(0xfff5a623),
      ),
    );
    slides.add(
      new Slide(
        title: "Filtern",
        description: "Filtern nach Thema, Titel, Länge und Fernsehsender",
        //pathImage: "assets/intro/intro_slider_2.png",
        centerWidget: new Container(
            padding: EdgeInsets.only(left: 20.0, right: 20.0),
            child: new Image(
                image: new AssetImage("assets/intro/intro_slider_2.png"))),

        backgroundColor: Color(0xff203152),
      ),
    );
    slides.add(
      new Slide(
        title: "Bewerten",
        description: "Bewerte deine Lieblingssendungen",
        //pathImage: "assets/intro/intro_slider_3.png",
        centerWidget: new Container(
            padding: EdgeInsets.only(left: 20.0, right: 20.0),
            child: new Image(
                image: new AssetImage("assets/intro/intro_slider_3.png"))),
        backgroundColor: Color(0xff9932CC),
      ),
    );
  }

  void onDonePress() {
    widget.onDonePressed();
  }

  @override
  Widget build(BuildContext context) {
    return new IntroSlider(
      slides: this.slides,
      onDonePress: this.onDonePress,
    );
  }
}
