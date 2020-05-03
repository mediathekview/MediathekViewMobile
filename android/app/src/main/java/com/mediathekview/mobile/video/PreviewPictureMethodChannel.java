package com.mediathekview.mobile.video;

import android.annotation.TargetApi;
import android.content.Context;
import android.os.Build;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class PreviewPictureMethodChannel implements MethodChannel.MethodCallHandler {

    private static final String TAG = "VIDEO_CALL_HANDLER";
    Context context;
    PreviewPictureEventChannel downloadStreamHandler;

    public PreviewPictureMethodChannel(Context context, PreviewPictureEventChannel streamHandler) {
        this.context = context;
        this.downloadStreamHandler = streamHandler;
    }

    @TargetApi(Build.VERSION_CODES.GINGERBREAD)
    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
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
