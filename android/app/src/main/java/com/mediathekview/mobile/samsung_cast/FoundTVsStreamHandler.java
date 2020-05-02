package com.mediathekview.mobile.samsung_cast;

import android.graphics.Bitmap;
import android.media.ThumbnailUtils;
import android.os.AsyncTask;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;

import io.flutter.plugin.common.EventChannel;
import wseemann.media.FFmpegMediaMetadataRetriever;

public class FoundTVsStreamHandler implements EventChannel.StreamHandler {

    static EventChannel.EventSink events;
    private String TAG = "FoundTvsStreamHandler";

    public FoundTVsStreamHandler() {

    }

    @Override
    public void onListen(Object o, EventChannel.EventSink events) {
        this.events = events;
        Log.i(TAG, "Listening to Found TVs events channel");
    }

    @Override
    public void onCancel(Object o) {
        Log.e(TAG, "Chancel Found TVs Stream Handler");
    }

    public void reportFoundTV(String tvName){
        if (events == null) {
            Log.i(TAG, "TV discovery: cannot notify about found TV as event channel is null");
            return;
        }

        Log.e(TAG, "Android: found TV");
        Map<String, Object> returnArguments = new HashMap<>();
        returnArguments.put("name", tvName);
        events.success(returnArguments);
    }
}
