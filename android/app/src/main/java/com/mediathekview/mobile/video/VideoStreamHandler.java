package com.mediathekview.mobile.video;

import android.graphics.Bitmap;
import android.media.ThumbnailUtils;
import android.os.AsyncTask;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;

import io.flutter.plugin.common.EventChannel;
import wseemann.media.FFmpegMediaMetadataRetriever;

public class VideoStreamHandler implements EventChannel.StreamHandler {

    static EventChannel.EventSink events;
    ScheduledExecutorService previewdExecutorService;
    private String TAG = "DownloadStreamHandler";


    public VideoStreamHandler() {

    }

    @Override
    public void onListen(Object o, EventChannel.EventSink events) {
        this.events = events;
        Log.i(TAG, "Listening to events channel");
        previewdExecutorService = Executors.newScheduledThreadPool(1);
    }

    @Override
    public void onCancel(Object o) {
        previewdExecutorService.shutdown();
        Log.e(TAG, "Chancel Download Stream Handler");
    }


    public void startPreviewTask(String url, String fileName, String videoId) {
        Handler handler = new Handler(Looper.getMainLooper());

        AsyncTask.execute(new Runnable() {
            @Override
            public void run() {
                FFmpegMediaMetadataRetriever mmr;
                try {
                    mmr = new FFmpegMediaMetadataRetriever();
                } catch (Exception e){
                    Log.i(TAG, "Initializing FFMPEG failed");
                    return;
                }
                Bitmap preview;
                Map<String, Object> returnArguments = new HashMap<>();

                if (fileName != null) {
                    File file = new File(Environment.getExternalStorageDirectory() + "/MediathekView", fileName);
                    Log.i(TAG, "Starting task: preview video with fileName" + fileName + ". File: Can Read: " + file.canRead() + " Lenght: " + file.length());
                    preview = ThumbnailUtils.createVideoThumbnail(Environment.getExternalStorageDirectory() + "/MediathekView/" + fileName, MediaStore.Images.Thumbnails.MINI_KIND);


                /*try {
                    FileInputStream fileInputStream = new FileInputStream(file);
                    Log.i(TAG, "Available: " + fileInputStream.available());
                    mmr.setDataSource(fileInputStream.getFD());
                } catch (java.io.IOException | IllegalArgumentException e) {
                    events.error(TAG, "File to generate preview from -  does not exist", null);
                    return;
                }*/
                } else {
                    Log.i(TAG, "Starting task: preview video with  url : " + url);
                    try {
                        mmr.setDataSource(url);
                        preview = mmr.getFrameAtTime(1000000, FFmpegMediaMetadataRetriever.OPTION_NEXT_SYNC); // frame at 2 seconds
                    } catch (Exception e) {
                        Log.e(TAG, "Could  not extract preview from: " + url + ". Error: " + e.getMessage());
                        returnArguments.put("videoId", videoId);
                        handler.post(() -> events.error(TAG, "Could not get preview bitmap", returnArguments));
                        return;
                    }
                    finally {
                        mmr.release();
                    }
                }


            /*preview = mmr.getFrameAtTime(1000000, FFmpegMediaMetadataRetriever.OPTION_NEXT_SYNC); // frame at 2 seconds
            mmr.release();
            */
                if (preview == null) {
                    Log.e(TAG, "Could not get preview bitmap");
                    returnArguments.put("videoId", videoId);
                    handler.post(() -> events.error(TAG, "Could not get preview bitmap", returnArguments));
                    return;
                }

                Log.i(TAG, "Preview - Retrieved Bitmap preview of size " + preview.getByteCount());


                ByteArrayOutputStream stream = new ByteArrayOutputStream();
                preview.compress(Bitmap.CompressFormat.PNG, 100, stream);
                byte[] byteArray = stream.toByteArray();
                preview.recycle();

                Log.i(TAG, "Byte array has size " + byteArray.length);

                returnArguments.put("image", byteArray);
                returnArguments.put("videoId", videoId);
                if (events == null){
                    Log.i(TAG, "Events channel is null");
                } else {
                    Log.i(TAG, "Events channel is not null");
                }

                //events.success(byteArray);
                handler.post(() -> events.success(returnArguments));
            }
        });
    }
}
