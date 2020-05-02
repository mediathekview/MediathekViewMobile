package com.mediathekview.mobile.samsung_cast;

import android.util.Log;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;

public class ReadinessStreamHandler implements EventChannel.StreamHandler {

    static EventChannel.EventSink events;
    private String TAG = "ReadinessStreamHandler";

    public ReadinessStreamHandler() {

    }

    @Override
    public void onListen(Object o, EventChannel.EventSink events) {
        this.events = events;
        Log.i(TAG, "Listening to TV connection events channel");
    }

    @Override
    public void onCancel(Object o) {
        Log.e(TAG, "Chancel TV connection stream handler");
    }

    public void reportCurrentlyChecking(String tvName){
        reportTvReadiness(tvName, "currently_checking");
    }

    public void reportReady(String tvName){
        reportTvReadiness(tvName, "ready");
    }

    public void reportNotReady(String tvName){
        reportTvReadiness(tvName, "not_ready");
    }

    public void reportTvReadiness(String tvName, String status){
        if (events == null) {
            Log.i(TAG, "TV discovery: cannot report TV readiness as event channel is null");
            return;
        }

        Map<String, Object> returnArguments = new HashMap<>();
        returnArguments.put("status", status);
        returnArguments.put("name", tvName);
        events.success(returnArguments);
    }


}
