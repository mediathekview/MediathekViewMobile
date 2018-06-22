package com.yourcompany.flutterws;

import android.annotation.TargetApi;
import android.app.DownloadManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;

import com.yourcompany.flutterws.download.DownloadCallHandler;
import com.yourcompany.flutterws.download.DownloadStreamHandler;
import com.yourcompany.flutterws.download.DownloadUtil;
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
  private static final String DOWNLOAD_METHOD_CHANNEL = "samples.flutter.io/download";
  private static final String VIDEO_METHOD_CHANNEL = "samples.flutter.io/video";
  private static final String DOWNLOAD_EVENT_CHANNEL = "samples.flutter.io/downloadEvent";
  private static final String VIDEO_EVENT_CHANNEL = "samples.flutter.io/videoEvent";

  public static Context context;
  public static MainActivity mainActivity;

  MethodChannel downloadMethodChannel;
  MethodChannel videoMethodChannel;
  EventChannel downloadEventChannel;
  EventChannel videoEventChannel;

  DownloadManager downloadManager;

  //Handler
  DownloadStreamHandler downloadStreamHandler;
  DownloadCallHandler downloadCallHandler;


  //mapping: userChoosenId -> downloadManager id
  public static ConcurrentHashMap<String, Integer> currentlyRunning = new ConcurrentHashMap();

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    context = this.getApplicationContext();
    mainActivity = this;

    downloadManager = (DownloadManager)context.getSystemService(DOWNLOAD_SERVICE);

    // downloadManager.getUriForDownloadedFile() -> in broadcast reciever done

    //event channel
    downloadEventChannel = new EventChannel(getFlutterView(), DOWNLOAD_EVENT_CHANNEL);
    downloadStreamHandler = new DownloadStreamHandler(downloadManager);
    downloadEventChannel.setStreamHandler(downloadStreamHandler);

    //method channel download
    downloadMethodChannel = new MethodChannel(getFlutterView(), DOWNLOAD_METHOD_CHANNEL);
    downloadCallHandler = new DownloadCallHandler(context, downloadManager, downloadStreamHandler);
    downloadMethodChannel.setMethodCallHandler(downloadCallHandler);

    //event channel
    videoEventChannel = new EventChannel(getFlutterView(), VIDEO_EVENT_CHANNEL);
    VideoStreamHandler videoStreamHandler = new VideoStreamHandler();
    videoEventChannel.setStreamHandler(videoStreamHandler);

    //method channel video player
    videoMethodChannel = new MethodChannel(getFlutterView(), VIDEO_METHOD_CHANNEL);
    videoMethodChannel.setMethodCallHandler(new VideoCallHandler(context, videoStreamHandler));

  }

  @Override
  public void onRequestPermissionsResult(int requestCode,
                                         String permissions[], int[] grantResults) {
    switch (requestCode) {
      case 0: {
        // If request is cancelled, the result arrays are empty.
        if (grantResults.length > 0
                && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
          Log.i("Permission","Permission granted!");

          //To get last request file download after grant of permission
          String fileName = downloadCallHandler.getLastRequestedDownloadFileName();
          String videoUrl = downloadCallHandler.getLastRequestedDownloadVideoUrl();
          String userDownloadId = downloadCallHandler.getLastRequestedDownloadUserDownloadId();

          Integer downloadManagerId = (int) DownloadUtil.enqueueFile(context, downloadManager, fileName, videoUrl);

          if (downloadManagerId == -1){

            return;
          }

          if (userDownloadId == null || userDownloadId.isEmpty()) {
            Log.i("Method Call Handler", "User Download id not specified. Putting in download list:  userId " + userDownloadId + "  and manager id " + downloadManagerId);
            MainActivity.currentlyRunning.put(String.valueOf(downloadManagerId), downloadManagerId);
          } else {
            MainActivity.currentlyRunning.put(userDownloadId, downloadManagerId);
          }
          downloadStreamHandler.startProgressChecker();

        } else {
          Log.i("Permission","Permission NOT granted!");

          // permission denied, boo! Disable the
          // functionality that depends on this permission.
          Toast.makeText(MainActivity.this, "Download nicht möglich", Toast.LENGTH_SHORT).show();
        }
        return;
      }
    }
  }
}
