package com.yourcompany.flutterws;

import android.annotation.TargetApi;
import android.app.DownloadManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import com.yourcompany.flutterws.download.FilesystemPermissionStreamHandler;
import com.yourcompany.flutterws.download.PermissionMethodHandler;
import com.yourcompany.flutterws.video.VideoCallHandler;
import com.yourcompany.flutterws.video.VideoStreamHandler;

import java.util.concurrent.ConcurrentHashMap;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

//import io.flutter.plugins.GeneratedPluginRegistrant;

@TargetApi(Build.VERSION_CODES.GINGERBREAD)
public class MainActivity extends FlutterActivity{
  private static final String VIDEO_METHOD_CHANNEL = "samples.flutter.io/video";
  private static final String VIDEO_EVENT_CHANNEL = "samples.flutter.io/videoEvent";
  private static final String PERMISSION_METHOD_CHANNEL = "samples.flutter.io/permission";
  private static final String PERMISSION_EVENT_CHANNEL = "samples.flutter.io/permissionEvent";

  public static Context context;
  public static MainActivity mainActivity;

  MethodChannel videoMethodChannel;
  EventChannel videoEventChannel;
  MethodChannel permissionMethodChannel;
  EventChannel permissionEventChannel;

  //Handler
  FilesystemPermissionStreamHandler filesystemPermissionStreamHandler;


  //mapping: userChoosenId -> downloadManager id
  public static ConcurrentHashMap<String, Integer> currentlyRunning = new ConcurrentHashMap();

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


    //Permissions
    permissionEventChannel = new EventChannel(getFlutterView(), PERMISSION_EVENT_CHANNEL);
    filesystemPermissionStreamHandler = new FilesystemPermissionStreamHandler();
    permissionEventChannel.setStreamHandler(filesystemPermissionStreamHandler);

    permissionMethodChannel = new MethodChannel(getFlutterView(), PERMISSION_METHOD_CHANNEL);
    permissionMethodChannel.setMethodCallHandler(new PermissionMethodHandler(context));
  }

  @Override
  public void onRequestPermissionsResult(int requestCode,
                                         String permissions[], int[] grantResults) {
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
