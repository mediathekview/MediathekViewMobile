package com.yourcompany.flutterws.video;

import android.graphics.Bitmap;
import android.media.ThumbnailUtils;
import android.os.Environment;
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
        previewdExecutorService = Executors.newScheduledThreadPool(1);
    }

    @Override
    public void onCancel(Object o) {
        previewdExecutorService.shutdown();
        Log.e(TAG, "Chancel Download Stream Handler");
    }


    public void startPreviewTask(String url, String fileName, String videoId) {

        Runnable task = () -> {

            FFmpegMediaMetadataRetriever mmr = new FFmpegMediaMetadataRetriever();
            Bitmap preview;

            if (fileName != null){

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
            }
            else {
                Log.i(TAG, "Starting task: preview video with  url : " + url);
                mmr.setDataSource(url);

                preview = mmr.getFrameAtTime(1000000, FFmpegMediaMetadataRetriever.OPTION_NEXT_SYNC); // frame at 2 seconds
                mmr.release();
            }


            /*preview = mmr.getFrameAtTime(1000000, FFmpegMediaMetadataRetriever.OPTION_NEXT_SYNC); // frame at 2 seconds
            mmr.release();
            */
            if (preview == null){
                Log.e(TAG, "Could not get preview bitmap");
                events.error(TAG, "Could not get preview bitmap", null);
                return;
            }

            Log.i(TAG, "Preview - Retrieved Bitmap preview of size " + preview.getByteCount());


            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            preview.compress(Bitmap.CompressFormat.PNG, 100, stream);
            byte[] byteArray = stream.toByteArray();
            preview.recycle();

            Map<String, Object> returnArguments =new HashMap<>();
            returnArguments.put("image", byteArray);
            returnArguments.put("videoId", videoId);

            events.success(returnArguments);
            //events.success(byteArray);
        };

        Log.i(TAG, "Starting executor service to generate preview for id " + videoId + " url: " + url + " filename: " + fileName);
        previewdExecutorService.execute(task);
    }
}
