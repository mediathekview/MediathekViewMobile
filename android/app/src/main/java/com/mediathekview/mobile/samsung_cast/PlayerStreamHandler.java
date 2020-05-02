package com.mediathekview.mobile.samsung_cast;

import android.util.Log;
import java.util.HashMap;
import java.util.Map;
import io.flutter.plugin.common.EventChannel;

public class PlayerStreamHandler implements EventChannel.StreamHandler {

    static EventChannel.EventSink events;
    private String TAG = "PlayerStreamHandler";

    public PlayerStreamHandler() {

    }

    @Override
    public void onListen(Object o, EventChannel.EventSink events) {
        this.events = events;
        Log.i(TAG, "Listening to TV player events channel");
    }

    @Override
    public void onCancel(Object o) {
        Log.e(TAG, "Chancel TV player stream handler");
    }

    public void reportPlayerPaused(){
        reportPlayerStatus("paused");
    }

    public void reportPlayerStopped(){
        reportPlayerStatus("stopped");
    }

    public void reportPlayerDisconnected(){
        reportPlayerStatus("disconnected");
    }

    public void reportPlaying(){
        reportPlayerStatus("playing");
    }

    private void reportPlayerStatus(String status){
        if (events == null) {
            Log.i(TAG, "Samsung TV: cannot report player status as event channel is null");
            return;
        }

        Map<String, Object> returnArguments = new HashMap<>();
        returnArguments.put("status", status);
        events.success(returnArguments);
    }

    public void reportError(String message) {
        Map<String, Object> returnArguments = new HashMap<>();
        returnArguments.put("error", message);
        if (events == null) {
            Log.e(TAG, "Android: cannot report video playback error - event channel is null");
            return;
        }

        events.error(TAG, "Samsung TV reported an error: ", returnArguments);
    }


}
