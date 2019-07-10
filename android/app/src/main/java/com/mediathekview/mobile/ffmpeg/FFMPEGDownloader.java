package com.mediathekview.mobile.ffmpeg;

import android.content.Context;
import android.util.Log;

import com.github.hiteshsondhi88.libffmpeg.ExecuteBinaryResponseHandler;
import com.github.hiteshsondhi88.libffmpeg.FFmpeg;
import com.github.hiteshsondhi88.libffmpeg.LoadBinaryResponseHandler;
import com.github.hiteshsondhi88.libffmpeg.exceptions.FFmpegCommandAlreadyRunningException;
import com.github.hiteshsondhi88.libffmpeg.exceptions.FFmpegNotSupportedException;

public class FFMPEGDownloader {
    static Boolean ffmpegSupport = false;
    static Context context;

    //Initialize FFMPEG library
    public static void initialize(Context c) {
        context = c;
        final FFmpeg ffmpeg = FFmpeg.getInstance(context.getApplicationContext());
        try {
            ffmpeg.loadBinary(new LoadBinaryResponseHandler() {
                @Override
                public void onSuccess() {
                    Log.i("Android","FFMPEG is supported by this device");
                    ffmpegSupport = true;
                }
            });
        } catch (FFmpegNotSupportedException e) {
            Log.i("Android","FFMPEG is NOT supported by this device");
        }
    }


    public static void downloadM3U8ToMp4(String url) throws FFmpegNotSupportedException {

        if (ffmpegSupport == false){
            throw new FFmpegNotSupportedException("FFMPEG NOT SUPPORTED");
        }

        FFmpeg ffmpeg = FFmpeg.getInstance(context);
        try {
            // to execute "ffmpeg -version" command you just need to pass "-version"
            ffmpeg.execute(new String[]{"-version"}, new ExecuteBinaryResponseHandler() {

                @Override
                public void onStart() {
                    Log.i("FFMPEG Android","Started download of url: " + url);
                }

                @Override
                public void onProgress(String message) {
                    Log.i("FFMPEG Android","Progress Update: " + message);
                }

                @Override
                public void onFailure(String message) {
                    Log.i("FFMPEG Android","FAILED " + message);
                }

                @Override
                public void onSuccess(String message) {
                    Log.i("FFMPEG Android","Successful download: " + message);
                }

                @Override
                public void onFinish() {
                    Log.i("FFMPEG Android","FFMPEG Finished");
                }
            });
        } catch (FFmpegCommandAlreadyRunningException e) {
            // Handle if FFmpeg is already running
            Log.w("FFMPEG Android","FFMPEG is already running");
        }
    }

}
