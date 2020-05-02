package com.mediathekview.mobile;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import com.mediathekview.mobile.samsung_cast.ReadinessStreamHandler;
import com.mediathekview.mobile.samsung_cast.FoundTVsStreamHandler;
import com.mediathekview.mobile.samsung_cast.LostTVsStreamHandler;
import com.mediathekview.mobile.samsung_cast.PlaybackPositionStreamHandler;
import com.mediathekview.mobile.samsung_cast.PlayerStreamHandler;
import com.mediathekview.mobile.samsung_cast.SamsungMediaLauncher;
import com.mediathekview.mobile.samsung_cast.SamsungTVDiscovery;
import com.mediathekview.mobile.samsung_cast.TvCastMethodHandler;
import com.mediathekview.mobile.video.VideoCallHandler;
import com.mediathekview.mobile.filesystempermission.FilesystemPermissionStreamHandler;
import com.mediathekview.mobile.filesystempermission.PermissionMethodHandler;
import com.mediathekview.mobile.video.VideoProgressStreamHandler;
import com.mediathekview.mobile.video.VideoStreamHandler;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

@TargetApi(Build.VERSION_CODES.GINGERBREAD)
public class MainActivity extends FlutterActivity{
  private static final String VIDEO_METHOD_CHANNEL = "com.mediathekview.mobile/video";
  private static final String VIDEO_EVENT_CHANNEL = "com.mediathekview.mobile/videoEvent";
  private static final String VIDEO_PROGRESS_EVENT_CHANNEL = "com.mediathekview.mobile/videoProgressEvent";
  private static final String PERMISSION_METHOD_CHANNEL = "com.mediathekview.mobile/permission";
  private static final String PERMISSION_EVENT_CHANNEL = "com.mediathekview.mobile/permissionEvent";
  private static final String SAMSUNG_METHOD_CHANNEL = "com.mediathekview.mobile/samsungTVCast";
  private static final String SAMSUNG_TV_FOUND_EVENT_CHANNEL = "com.mediathekview.mobile/samsungTVFound";
  private static final String SAMSUNG_TV_LOST_EVENT_CHANNEL = "com.mediathekview.mobile/samsungTVLost";
  private static final String SAMSUNG_TV_READINESS_EVENT_CHANNEL = "com.mediathekview.mobile/samsungTVReadiness";
  private static final String SAMSUNG_TV_PLAYER_EVENT_CHANNEL = "com.mediathekview.mobile/samsungTVPlayer";
  private static final String SAMSUNG_TV_PLAYBACK_POSITION_EVENT_CHANNEL = "com.mediathekview.mobile/samsungTVPlaybackPosition";

  public static Context context;
  public static MainActivity mainActivity;

  MethodChannel videoMethodChannel;
  EventChannel videoEventChannel;
  MethodChannel permissionMethodChannel;
  EventChannel permissionEventChannel;
  EventChannel progressEventChannel;

  MethodChannel samsungMethodChannel;
  EventChannel samsungTvFoundEventChannel;
  EventChannel samsungTvLostEventChannel;
  EventChannel samsungTvReadinessEventChannel;
  EventChannel samsungTvPlayerEventChannel;
  EventChannel samsungTvPlaybackPositionEventChannel;


  public static VideoProgressStreamHandler videoProgressStreamHandler;


  //Handler
  FilesystemPermissionStreamHandler filesystemPermissionStreamHandler;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    context = this.getApplicationContext();
    mainActivity = this;

    //video player
    videoEventChannel = new EventChannel(getFlutterView(), VIDEO_EVENT_CHANNEL);
    VideoStreamHandler videoStreamHandler = new VideoStreamHandler();
    videoEventChannel.setStreamHandler(videoStreamHandler);

    videoMethodChannel = new MethodChannel(getFlutterView(), VIDEO_METHOD_CHANNEL);
    videoMethodChannel.setMethodCallHandler(new VideoCallHandler(context, videoStreamHandler));

    // video progress
    progressEventChannel = new EventChannel(getFlutterView(), VIDEO_PROGRESS_EVENT_CHANNEL);
    videoProgressStreamHandler = new VideoProgressStreamHandler();
    progressEventChannel.setStreamHandler(videoProgressStreamHandler);

    //Permissions
    permissionEventChannel = new EventChannel(getFlutterView(), PERMISSION_EVENT_CHANNEL);
    filesystemPermissionStreamHandler = new FilesystemPermissionStreamHandler();
    permissionEventChannel.setStreamHandler(filesystemPermissionStreamHandler);

    permissionMethodChannel = new MethodChannel(getFlutterView(), PERMISSION_METHOD_CHANNEL);
    permissionMethodChannel.setMethodCallHandler(new PermissionMethodHandler(context));

    //Samsung TV Cast
    samsungTvFoundEventChannel = new EventChannel(getFlutterView(), SAMSUNG_TV_FOUND_EVENT_CHANNEL);
    FoundTVsStreamHandler foundTVsStreamHandler = new FoundTVsStreamHandler();
    samsungTvFoundEventChannel.setStreamHandler(foundTVsStreamHandler);

    samsungTvLostEventChannel = new EventChannel(getFlutterView(), SAMSUNG_TV_LOST_EVENT_CHANNEL);
    LostTVsStreamHandler lostTVsStreamHandler = new LostTVsStreamHandler();
    samsungTvLostEventChannel.setStreamHandler(lostTVsStreamHandler);

    samsungTvReadinessEventChannel = new EventChannel(getFlutterView(), SAMSUNG_TV_READINESS_EVENT_CHANNEL);
    ReadinessStreamHandler readinessStreamHandler = new ReadinessStreamHandler();
    samsungTvReadinessEventChannel.setStreamHandler(readinessStreamHandler);

    samsungTvPlayerEventChannel = new EventChannel(getFlutterView(), SAMSUNG_TV_PLAYER_EVENT_CHANNEL);
    PlayerStreamHandler playerStreamHandler = new PlayerStreamHandler();
    samsungTvPlayerEventChannel.setStreamHandler(playerStreamHandler);

    samsungTvPlaybackPositionEventChannel = new EventChannel(getFlutterView(), SAMSUNG_TV_PLAYBACK_POSITION_EVENT_CHANNEL);
    PlaybackPositionStreamHandler playbackPositionStreamHandler = new PlaybackPositionStreamHandler();
    samsungTvPlaybackPositionEventChannel.setStreamHandler(playbackPositionStreamHandler);

    SamsungTVDiscovery samsungTvDiscovery = SamsungTVDiscovery.getInstance(context, foundTVsStreamHandler, lostTVsStreamHandler);
    SamsungMediaLauncher samsungMediaLauncher = SamsungMediaLauncher.getInstance(readinessStreamHandler, playerStreamHandler, playbackPositionStreamHandler);

    TvCastMethodHandler tvCastMethodHandler = new TvCastMethodHandler(samsungTvDiscovery, samsungMediaLauncher, readinessStreamHandler);
    samsungMethodChannel = new MethodChannel(getFlutterView(), SAMSUNG_METHOD_CHANNEL);
    samsungMethodChannel.setMethodCallHandler(tvCastMethodHandler);
  }

  @Override
  public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
    switch (requestCode) {
      case 0: {
        // If request is cancelled, the result arrays are empty.
        if (grantResults.length > 0
                && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
          Log.i("Permission","Filesystem permission granted!");
          filesystemPermissionStreamHandler.permissionGranted(true);
        } else {
          Log.i("Permission","Filesystem permission NOT granted!");
          filesystemPermissionStreamHandler.permissionGranted(false);
        }
        return;
      }
    }
  }
}
