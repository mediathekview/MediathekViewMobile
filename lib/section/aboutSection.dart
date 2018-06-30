import 'package:flutter/material.dart';
import 'package:flutter_ws/util/textStyles.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSection extends StatelessWidget {
  static const eMailAddress =
      'mailto:kontakt.mediathekview.mobile@gmail.com?subject=Feedback zu MediathekView Mobile&body=<body>Hi Daniel,';
  static const eMailAddressKontonummer =
      'mailto:kontakt.mediathekview.mobile@gmail.com?subject=Spende - Kontonummer Anfrage&body=<body>Hi Daniel, Ich würde gerne etwas spenden und brauche dazu deine Kontonummer. Ich möchte folgende Summe spenden: ';
  static const githubUrl =
      'https://github.com/danielfoehrKn/MediathekViewMobile';
  static const payPal = 'https://paypal.me/danielfoehr';

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: new AppBar(
        centerTitle: true,
        title: new Text('About'),
//            backgroundColor: new Color(0xffffbf00),
        elevation: 6.0,
        backgroundColor: Colors.grey[800],
      ),
      body: new Column(
        children: <Widget>[
          new Card(
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: new Text('About', style: aboutSectionTitle),
                  subtitle: new Text(
                      'Dies ist ein Open-Source Projekt (Apache 2.0-Lizenz) basierend auf der API von MediathekViewWeb. Es werden die Mediatheken der öffentlich-rechtliche TV Sender unterstützt.'),
                ),
              ],
            ),
          ),
          new Card(
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new ListTile(
                  leading: const Icon(Icons.feedback),
                  title: new Text('Feedback', style: aboutSectionTitle),
                  subtitle: new Text(
                      'Anregungen, Wünsche oder (miese) Bugs? Gib Feedback auf Github oder per Mail. Danke für deinen Beitrag!'),
                ),
                new ButtonTheme.bar(
                  // make buttons use the appropriate styles for cards
                  child: new ButtonBar(
                    children: <Widget>[
                      new FlatButton(
                        color: Colors.grey[800],
                        child: new Text('E-Mail', style: body2TextStyle),
                        onPressed: () => _launchURL(eMailAddress),
                      ),
                      new FlatButton(
                        color: Colors.grey[800],
                        child: new Text('Github', style: body2TextStyle),
                        onPressed: () => _launchURL(githubUrl),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          new Card(
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: new Text('Spenden / Donate', style: aboutSectionTitle),
                  subtitle: const Text(
                      'Jeder gespendete Euro wird direkt in Updates investiert (oder Kaffee)'),
                ),
                new ButtonTheme.bar(
                  // make buttons use the appropriate styles for cards
                  child: new ButtonBar(
                    children: <Widget>[
                      new FlatButton(
                        color: Colors.grey[800],
                        child: new Text('Kontonummer auf Anfrage',
                            style: body2TextStyle),
                        onPressed: () => _launchURL(eMailAddressKontonummer),
                      ),
                      new FlatButton(
                        color: Colors.blue,
                        child: new Text('Paypal', style: body2TextStyle),
                        onPressed: () => _launchURL(payPal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

_launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    print('Could not launch $url');
  }
}
