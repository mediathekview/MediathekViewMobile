package com.mediathekview.mobile.filesystempermission;

import android.util.Log;

import java.util.HashMap;

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
        Log.e(TAG, "Chancel Download Stream Handler");
    }

    public void permissionGranted(boolean granted){
        HashMap<String, String> result = new HashMap<>();
        result.put("Granted", String.valueOf(granted));
        events.success(result);
    }
}
