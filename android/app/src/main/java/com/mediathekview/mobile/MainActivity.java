package com.mediathekview.mobile;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import com.mediathekview.mobile.samsung_cast.ReadinessStreamHandler;
import com.mediathekview.mobile.samsung_cast.FoundTVsStreamHandler;
import com.mediathekview.mobile.samsung_cast.LostTVsStreamHandler;
import com.mediathekview.mobile.samsung_cast.PlaybackPositionStreamHandler;
import com.mediathekview.mobile.samsung_cast.PlayerStreamHandler;
import com.mediathekview.mobile.samsung_cast.SamsungMediaLauncher;
import com.mediathekview.mobile.samsung_cast.SamsungTVDiscovery;
import com.mediathekview.mobile.samsung_cast.TvCastMethodHandler;
import com.mediathekview.mobile.video.PreviewPictureMethodChannel;
import com.mediathekview.mobile.filesystempermission.FilesystemPermissionStreamHandler;
import com.mediathekview.mobile.filesystempermission.PermissionMethodHandler;
import com.mediathekview.mobile.video.PreviewPictureEventChannel;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

@TargetApi(Build.VERSION_CODES.GINGERBREAD)
public class MainActivity extends FlutterActivity{
  private static final String VIDEO_METHOD_CHANNEL = "com.mediathekview.mobile/video";
  private static final String VIDEO_EVENT_CHANNEL = "com.mediathekview.mobile/videoEvent";
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

  MethodChannel samsungMethodChannel;
  EventChannel samsungTvFoundEventChannel;
  EventChannel samsungTvLostEventChannel;
  EventChannel samsungTvReadinessEventChannel;
  EventChannel samsungTvPlayerEventChannel;
  EventChannel samsungTvPlaybackPositionEventChannel;


  //Handler
  FilesystemPermissionStreamHandler filesystemPermissionStreamHandler;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        Log.i("Startup Android","configureFlutterEngine called!");
        mainActivity = this;
        context = this.getApplicationContext();
        PreviewPictureEventChannel previewPictureEventChannel = new PreviewPictureEventChannel();
        videoEventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), VIDEO_EVENT_CHANNEL);
        videoEventChannel.setStreamHandler(previewPictureEventChannel);
        videoMethodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), VIDEO_METHOD_CHANNEL);
        videoMethodChannel.setMethodCallHandler(new PreviewPictureMethodChannel(context, previewPictureEventChannel));

        //Permissions
        permissionEventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), PERMISSION_EVENT_CHANNEL);
        filesystemPermissionStreamHandler = new FilesystemPermissionStreamHandler();
        permissionEventChannel.setStreamHandler(filesystemPermissionStreamHandler);

        permissionMethodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), PERMISSION_METHOD_CHANNEL);
        permissionMethodChannel.setMethodCallHandler(new PermissionMethodHandler(context));

        //Samsung TV Cast
        samsungTvFoundEventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SAMSUNG_TV_FOUND_EVENT_CHANNEL);
        FoundTVsStreamHandler foundTVsStreamHandler = new FoundTVsStreamHandler();
        samsungTvFoundEventChannel.setStreamHandler(foundTVsStreamHandler);

        samsungTvLostEventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SAMSUNG_TV_LOST_EVENT_CHANNEL);
        LostTVsStreamHandler lostTVsStreamHandler = new LostTVsStreamHandler();
        samsungTvLostEventChannel.setStreamHandler(lostTVsStreamHandler);

        samsungTvReadinessEventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SAMSUNG_TV_READINESS_EVENT_CHANNEL);
        ReadinessStreamHandler readinessStreamHandler = new ReadinessStreamHandler();
        samsungTvReadinessEventChannel.setStreamHandler(readinessStreamHandler);

        samsungTvPlayerEventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SAMSUNG_TV_PLAYER_EVENT_CHANNEL);
        PlayerStreamHandler playerStreamHandler = new PlayerStreamHandler();
        samsungTvPlayerEventChannel.setStreamHandler(playerStreamHandler);

        samsungTvPlaybackPositionEventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SAMSUNG_TV_PLAYBACK_POSITION_EVENT_CHANNEL);
        PlaybackPositionStreamHandler playbackPositionStreamHandler = new PlaybackPositionStreamHandler();
        samsungTvPlaybackPositionEventChannel.setStreamHandler(playbackPositionStreamHandler);

        SamsungTVDiscovery samsungTvDiscovery = SamsungTVDiscovery.getInstance(context, foundTVsStreamHandler, lostTVsStreamHandler);
        SamsungMediaLauncher samsungMediaLauncher = SamsungMediaLauncher.getInstance(readinessStreamHandler, playerStreamHandler, playbackPositionStreamHandler);

        TvCastMethodHandler tvCastMethodHandler = new TvCastMethodHandler(samsungTvDiscovery, samsungMediaLauncher, readinessStreamHandler);
        samsungMethodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SAMSUNG_METHOD_CHANNEL);
        samsungMethodChannel.setMethodCallHandler(tvCastMethodHandler);

        // while the plugins in registerWith are generated based on the flutter pubspec.yaml
        // based on which plugins support android, we still need to explicitly call it here
        GeneratedPluginRegistrant.registerWith(flutterEngine);
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
