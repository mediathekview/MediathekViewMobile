import 'package:flutter/material.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsSection extends StatelessWidget {
  static final Logger logger = new Logger('SettingsSection');
  static const githubUrl =
      'https://github.com/Mediathekview/MediathekViewMobile';
  static const payPal = 'https://paypal.me/danielfoehr';

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.grey[800],
      body: new SafeArea(
        child: ListView(
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
                        'Anregungen, Wünsche oder Bugs? Gib Feedback auf Github. Danke für deinen Beitrag!'),
                  ),
                  new ButtonTheme.bar(
                    // make buttons use the appropriate styles for cards
                    child: new ButtonBar(
                      children: <Widget>[
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
                    title:
                        new Text('Spenden / Donate', style: aboutSectionTitle),
                    subtitle: const Text(
                        'Dir gefällt die App? Ich würde mich über eine Spende freuen.'),
                  ),
                  new ButtonTheme.bar(
                    // make buttons use the appropriate styles for cards
                    child: new ButtonBar(
                      children: <Widget>[
                        new FlatButton(
                          color: Colors.blue,
                          child: new Text('Paypal', style: body2TextStyle),
                          onPressed: () {
                            _launchURL(payPal);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      logger.fine('Could not launch $url');
    }
  }
}
