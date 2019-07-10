package com.mediathekview.mobile.video;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

import com.mediathekview.mobile.MainActivity;
import com.mediathekview.mobile.activity.VideoPlayerActivity;

import java.io.File;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class VideoCallHandler implements MethodChannel.MethodCallHandler {

    private static final String TAG = "VIDEO_CALL_HANDLER";
    public static final String FILE_PATH = "FILE_PATH";
    public static final String VIDEO_ID = "VIDEO_ID";
    public static final String PROGRESS = "PROGRESS";
    Context context;
    com.mediathekview.mobile.video.VideoStreamHandler downloadStreamHandler;

    public VideoCallHandler(Context context, com.mediathekview.mobile.video.VideoStreamHandler streamHandler) {
        this.context = context;
        this.downloadStreamHandler = streamHandler;
    }

    @TargetApi(Build.VERSION_CODES.GINGERBREAD)
    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        Log.i("VIDEO Call Handler", "Method call with identifier " + call.method + " received");

        if (call.method.equals("playVideo")) {
            String filePath = call.argument("filePath");
            String videoId = call.argument("videoId");
            String progress = call.argument("progress");

            Log.i(TAG, "Opening video with  filePath : " + filePath + " at playback position: " + progress);

            Intent intent = new Intent(context, VideoPlayerActivity.class);
            intent.putExtra(FILE_PATH, filePath);
            intent.putExtra(VIDEO_ID, videoId);
            intent.putExtra(VIDEO_ID, videoId);
            intent.putExtra(PROGRESS, Long.parseLong(progress));
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            MainActivity.context.startActivity(intent);

            /*Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(filePath));

            //intent.setDataAndType(Uri.parse(filePath), mimeType);
            intent.setDataAndType(Uri.parse(filePath), mimeType);
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            MainActivity.context.startActivity(intent);*/

            result.success(null);
        }

        if (call.method.equals("deleteVideo")) {
//            String filePath = call.argument("filePath");
            String fileName = call.argument("fileName");

            Log.i(TAG, "Deleting video with  name : " + Environment.getExternalStorageDirectory() + "/MediathekView" + "/" + fileName);

            File file = new File(Environment.getExternalStorageDirectory() + "/MediathekView", fileName);

            if (!file.exists()) {
                result.error(TAG, "File to delete does not exist", null);
                return;
            }

            boolean deleted;
            try {
                deleted = file.delete();
            } catch (SecurityException e) {
                result.error(TAG, "Could not delete File", e);
                return;
            }

            if (!deleted) {
                result.error(TAG, "Could not delete File", null);
                return;
            }

            //reche
            File file2 = new File(Environment.getExternalStorageDirectory() + "/MediathekView", fileName);

            if (file2.exists()) {
                result.error(TAG, "File still exists dude...", null);
                return;
            }

            result.success(null);
        }

        if (call.method.equals("videoPreviewPicture")) {
            String videoId = call.argument("videoId");
            String url = call.argument("url");
            String fileName = call.argument("fileName");

            if (url == null && fileName == null) {
                result.error(TAG, "Either Url or filename must not be null retrieving a preview", null);
                return;
            }

            downloadStreamHandler.startPreviewTask(url, fileName, videoId);
            result.success(true);
        }

    }
}
