import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/main.dart';
import 'package:flutter_ws/util/countly.dart';
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
            new SettingsState(),
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

class SettingsState extends StatefulWidget {
  final Logger logger = new Logger('SettingsState');

  @override
  _SettingsStateState createState() => _SettingsStateState();
}

class _SettingsStateState extends State<SettingsState> {
  //global state
  AppSharedState appWideState;

  @override
  Widget build(BuildContext context) {
    appWideState = AppSharedStateContainer.of(context);
    bool hasCountlyConsent = appWideState.appState.sharedPreferences
        .getBool(HomePageState.SHARED_PREFERENCE_KEY_COUNTLY_CONSENT);

    return new Card(
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          new ListTile(
            leading: const Icon(Icons.pan_tool),
            title: new Text('GDPR', style: aboutSectionTitle),
            subtitle: const Text(
                'Darf MediathekView anonymisierte Crash und Nutzungsdaten sammeln? Das hilft uns die App zu verbessern.'),
          ),
          Container(
            margin: EdgeInsets.only(right: 10),
            child: Transform.scale(
              scale: 1.5,
              child: Switch(
                value: hasCountlyConsent,
                onChanged: (value) {
                  setState(() {
                    appWideState.appState.sharedPreferences.setBool(
                        HomePageState.SHARED_PREFERENCE_KEY_COUNTLY_CONSENT,
                        value);

                    if (appWideState.appState.sharedPreferences.containsKey(
                            HomePageState.SHARED_PREFERENCE_KEY_COUNTLY_API) &&
                        appWideState.appState.sharedPreferences.containsKey(
                            HomePageState
                                .SHARED_PREFERENCE_KEY_COUNTLY_APP_KEY)) {
                      String countlyAppKey = appWideState
                          .appState.sharedPreferences
                          .getString(HomePageState
                              .SHARED_PREFERENCE_KEY_COUNTLY_APP_KEY);
                      String countlyAPI =
                          appWideState.appState.sharedPreferences.getString(
                              HomePageState.SHARED_PREFERENCE_KEY_COUNTLY_API);
                      return CountlyUtil.initializeCountly(
                          widget.logger, countlyAPI, countlyAppKey, value);
                    }
                    CountlyUtil.loadCountlyInformationFromGithub(
                        widget.logger, appWideState, value);
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
