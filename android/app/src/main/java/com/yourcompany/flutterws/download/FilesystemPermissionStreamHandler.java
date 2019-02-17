package com.yourcompany.flutterws.download;

import android.app.DownloadManager;
import android.util.Log;

import com.yourcompany.flutterws.MainActivity;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import io.flutter.plugin.common.EventChannel;

public class FilesystemPermissionStreamHandler implements EventChannel.StreamHandler {

    static EventChannel.EventSink events;
    private String TAG = "FilesystemPermissionStreamHandler";


    @Override
    public void onListen(Object o, EventChannel.EventSink events) {
        this.events = events;
    }

    @Override
    public void onCancel(Object o) {
        //scheduledExecutorService.shutdown();
        Log.e(TAG, "Chancel Download Stream Handler");
    }

    public void permissionGranted(boolean granted){
        HashMap<String, String> result = new HashMap<>();
        result.put("Granted", String.valueOf(granted));
        events.success(result);
    }
}
