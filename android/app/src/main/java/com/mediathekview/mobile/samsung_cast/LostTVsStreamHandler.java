package com.mediathekview.mobile.samsung_cast;

import android.util.Log;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;

public class LostTVsStreamHandler implements EventChannel.StreamHandler {

    static EventChannel.EventSink events;
    private String TAG = "LostTvsStreamHandler";

    public LostTVsStreamHandler() {

    }

    @Override
    public void onListen(Object o, EventChannel.EventSink events) {
        this.events = events;
        Log.i(TAG, "Listening to Lost TVs events channel");
    }

    @Override
    public void onCancel(Object o) {
        Log.e(TAG, "Chancel Lost TVs Stream Handler");
    }

    public void reportLostTV(String tvName){
        if (events == null) {
            Log.i(TAG, "TV discovery: cannot notify about lost TV as event channel is null");
            return;
        }

        Map<String, Object> returnArguments = new HashMap<>();
        returnArguments.put("name", tvName);
        events.success(returnArguments);
    }
}
