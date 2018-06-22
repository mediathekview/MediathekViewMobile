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

public class DownloadStreamHandler implements EventChannel.StreamHandler {

    final DownloadManager downloadManager;
    static EventChannel.EventSink events;
    ScheduledExecutorService scheduledExecutorService;
    private String TAG = "DownloadStreamHandler";

    public DownloadStreamHandler(DownloadManager downloadManager) {
        this.downloadManager = downloadManager;
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink events) {
        this.events = events;
        scheduleProgressChecker();
    }

    @Override
    public void onCancel(Object o) {
        scheduledExecutorService.shutdown();
        Log.e(TAG, "Chancel Download Stream Handler");
    }

    public void startProgressChecker() {
        scheduledExecutorService.shutdown();
        scheduleProgressChecker();
//        if (scheduledExecutorService == null || scheduledExecutorService.isShutdown() || scheduledExecutorService.isTerminated())
//            scheduleProgressChecker();
//        else {
//            Log.i(TAG, "Executor service already running - do not trigger start");
//        }
    }


    private void scheduleProgressChecker() {

        scheduledExecutorService = Executors.newScheduledThreadPool(1);

        Runnable task = () -> {
            if (MainActivity.currentlyRunning.isEmpty()) {
                scheduledExecutorService.shutdown();
                Log.i(TAG, "Shutting down progress checker - there are no downloads currently");
                return;
            }
//            Log.i(TAG, "Getting progress of currently " + MainActivity.currentlyRunning.size() + " downloads");

            Set<Map.Entry<String, Integer>> entries = MainActivity.currentlyRunning.entrySet();

            //TO be complian with older android version
            for (Map.Entry<String, Integer> entry : entries){

                Map<String, String> arguments = com.yourcompany.flutterws.download.DownloadUtil.getStatus(downloadManager, entry.getValue(), entry.getKey());

                if (arguments.isEmpty()) {
                    Log.i(TAG, "Arguments for user id -  " + entry.getKey() + " - are empty - download not found. Removing from list");
                    MainActivity.currentlyRunning.remove(entry.getKey());

                    arguments.put("id", entry.getKey());
                    arguments.put("statusText", "STATUS_CANCELED");
                    arguments.put("reasonText", "Download removed externally");
                    arguments.put("totalActiveCount", String.valueOf(MainActivity.currentlyRunning.size()));
                    events.success(arguments);
                    //Todo works for only one download - however what if > 1 - also get no update anymore
                    Log.i(TAG, "Local state out of sync - shutting down executor service.");
                    this.scheduledExecutorService.shutdown();
                    return;
                }

                String id = arguments.get("id");

                if (arguments.get("statusText").equals("STATUS_FAILED")) {
                    Log.i(TAG, "Download with id " + id + " failed - removing from active list");
                    MainActivity.currentlyRunning.remove(id);
                    Log.i(TAG, "active list size after removal :>" + MainActivity.currentlyRunning.size());
                } else if (arguments.get("statusText").equals("STATUS_SUCCESSFUL")) {
                    Log.i(TAG, "Download with id " + id + " finished - removing from active list");
                    MainActivity.currentlyRunning.remove(id);
                }
                events.success(arguments);

            }
        };
        Log.i(TAG, "Registering executor service : Getting progress of active downloads");
        scheduledExecutorService.scheduleAtFixedRate(task, 0, 2, TimeUnit.SECONDS);
    }

    public void notifyChanceled(String userId) {
        Map<String, String> arguments = new HashMap<>();
        arguments.put("id", userId);
        arguments.put("statusText", "STATUS_CANCELED");
        arguments.put("reasonText", "Download chanceled by user");
        arguments.put("totalActiveCount", String.valueOf(MainActivity.currentlyRunning.size()));
        events.success(arguments);
    }
}
