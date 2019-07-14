package com.mediathekview.mobile.video;

import android.util.Log;

import com.google.android.exoplayer2.ExoPlaybackException;

import java.util.HashMap;
import java.util.Map;
import io.flutter.plugin.common.EventChannel;

public class VideoProgressStreamHandler implements EventChannel.StreamHandler {

    static EventChannel.EventSink events;
    private String TAG = "VideoProgressStreamHandler";


    public VideoProgressStreamHandler() {

    }

    @Override
    public void onListen(Object o, EventChannel.EventSink events) {
        this.events = events;
        Log.i(TAG, "Listening to progress events channel");
    }

    @Override
    public void onCancel(Object o) {
        Log.i(TAG, "Chancel listening to video progress");
    }

    public void updateProgress(String videoId, Long progress) {
        Map<String, Object> returnArguments = new HashMap<>();
        returnArguments.put("videoId", videoId);
        returnArguments.put("progress", progress);
        if (events == null) {
            Log.e(TAG, "Android: cannot report video play progress - event channel is null");
            return;
        }

        events.success(returnArguments);
    }

    public void reportError(ExoPlaybackException error) {
        Map<String, Object> returnArguments = new HashMap<>();
        returnArguments.put("error", error.getMessage());
        if (events == null) {
            Log.e(TAG, "Android: cannot report error - event channel is null");
            return;
        }

        events.error(TAG, "Error playing video", returnArguments);
    }

}
