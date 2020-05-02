package com.mediathekview.mobile.samsung_cast;

import android.annotation.TargetApi;
import android.os.Build;
import android.util.Log;

import com.samsung.multiscreen.Service;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class TvCastMethodHandler implements MethodChannel.MethodCallHandler {

    private static final String TAG = "TvCast";
    private SamsungTVDiscovery discovery;
    private SamsungMediaLauncher launcher;
    private ReadinessStreamHandler readinessStreamHandler;

    public TvCastMethodHandler(SamsungTVDiscovery discovery, SamsungMediaLauncher launcher, ReadinessStreamHandler readinessStreamHandler) {
        this.launcher = launcher;
        this.discovery = discovery;
        this.readinessStreamHandler = readinessStreamHandler;
    }

    @TargetApi(Build.VERSION_CODES.GINGERBREAD)
    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
         if (call.method.equals("startDiscovery")) {

            Log.i(TAG, "Android: received startDiscovery");
            discovery.startDiscovery(true);
            return;
        }

        if (call.method.equals("stopDiscovery")){
             Log.i(TAG, "Android: received stopDiscovery");

             discovery.stopDiscovery();
            return;
        }

        if (call.method.equals("check")){
            String tvName = call.argument("tvName");
            Log.i(TAG, "Android: checking if TV can be used for streaming: " + tvName);

            readinessStreamHandler.reportCurrentlyChecking(tvName);

            Service tvService = discovery.getTvForName(tvName);

            if (tvService == null) {
                readinessStreamHandler.reportNotReady(tvName);
                return;
            }

            // create video player and check if the TV supports the Default Media Player
            launcher.setService(tvService);

            return;
        }

        if (call.method.equals("play")){
            String url = call.argument("url");
            String title = call.argument("title");
            String position = call.argument("startingPosition");
            Long startingPosition = Long.parseLong(position);

            launcher.playContent(url, title, startingPosition.intValue());
            return;
        }

        if (call.method.equals("pause")){
            Log.i(TAG, "Android: should pause current video playback");
            launcher.pause();
            return;
        }

        if (call.method.equals("disconnect")){
            Log.i(TAG, "Android: should disconnect from TV");
            launcher.disconnect();
            return;
        }

        if (call.method.equals("stop")){
            Log.i(TAG, "Android: should stop video player");
            launcher.stop();
            return;
        }

        if (call.method.equals("resume")){
            Log.i(TAG, "Android: should resume current video playback");
            launcher.play();
            return;
        }

        if (call.method.equals("mute")){
            Log.i(TAG, "Android: should mute current video playback");
            launcher.mute();
            return;
        }

        if (call.method.equals("unmute")){
            Log.i(TAG, "Android: should unmute current video playback");
            launcher.unmute();
            return;
        }

        if (call.method.equals("seekTo")){
            String seekTo = call.argument("seekTo");
            Long seekPosition = Long.parseLong(seekTo);

            Log.i(TAG, "Android: should seekTo " + seekTo);

            launcher.seekTo(seekPosition.intValue());
            return;
        }
    }
}
