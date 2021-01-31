package com.mediathekview.mobile.samsung_cast;

import android.util.Log;
import java.util.HashMap;
import java.util.Map;
import io.flutter.plugin.common.EventChannel;

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
