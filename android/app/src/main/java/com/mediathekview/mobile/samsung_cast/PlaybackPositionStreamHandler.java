package com.mediathekview.mobile.samsung_cast;

import android.util.Log;

import com.google.android.exoplayer2.ExoPlaybackException;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;

public class PlaybackPositionStreamHandler implements EventChannel.StreamHandler {

    static EventChannel.EventSink events;
    private String TAG = "PlaybackPositionStreamHandler";


    public PlaybackPositionStreamHandler() {

    }

    @Override
    public void onListen(Object o, EventChannel.EventSink events) {
        this.events = events;
        Log.i(TAG, "Listening to playback position events channel");
    }

    @Override
    public void onCancel(Object o) {
        Log.i(TAG, "Chancel listening to playback position events channel");
    }

    public void updatePlaybackPosition(int position) {
        Map<String, Object> returnArguments = new HashMap<>();
        returnArguments.put("playbackPosition", position);
        if (events == null) {
            Log.e(TAG, "Android: cannot report video playback position - event channel is null");
            return;
        }

        events.success(returnArguments);
    }

}
