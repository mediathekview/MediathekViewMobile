package com.mediathekview.mobile.samsung_cast;


import android.net.Uri;
import android.util.Log;

import com.samsung.multiscreen.AudioPlayer;
import com.samsung.multiscreen.Channel;
import com.samsung.multiscreen.Client;
import com.samsung.multiscreen.Error;
import com.samsung.multiscreen.Player;
import com.samsung.multiscreen.Result;
import com.samsung.multiscreen.Service;
import com.samsung.multiscreen.VideoPlayer;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class SamsungMediaLauncher {
    static final String TAG                      = "SamsungMediaLauncher";

    private static SamsungMediaLauncher mInstance = null;
    private Service mService = null;
    private VideoPlayer mVideoPlayer = null;
    private ReadinessStreamHandler readinessStreamHandler;
    private PlayerStreamHandler playerStreamHandler;
    private PlaybackPositionStreamHandler playbackPositionStreamHandler;
    private Integer startingPositionMilliseconds;
    // indicates that the TV player just started. Used to be able to differentiate in BufferingComplete()
    // between a "skip forward" and initial start (then seek to starting position)
    private boolean initialStart;

    // EVENT HANDLERS
    private SamsungMediaLauncher(ReadinessStreamHandler connection, PlayerStreamHandler playerStreamHandler, PlaybackPositionStreamHandler playbackPositionStreamHandler){
        super();
        this.readinessStreamHandler = connection;
        this.playerStreamHandler = playerStreamHandler;
        this.playbackPositionStreamHandler = playbackPositionStreamHandler;
    }

    public static SamsungMediaLauncher getInstance(ReadinessStreamHandler readinessStreamHandler, PlayerStreamHandler playerStreamHandler, PlaybackPositionStreamHandler playbackPositionStreamHandler) {
        if(null == mInstance){
            mInstance = new SamsungMediaLauncher(readinessStreamHandler, playerStreamHandler, playbackPositionStreamHandler);
        }
        return mInstance;
    }

    public void setService(final Service service){
        service.isDMPSupported(new Result<Boolean>() {
            @Override
            public void onSuccess(Boolean isSupported) {
                if (isSupported) {
                    mService = service;
                    initMediaPlayer();
                    // technically the websocket connection is not established,
                    // only the check if the DMP is available
                    readinessStreamHandler.reportReady(mService.getName());
                } else {
                    readinessStreamHandler.reportNotReady(service.getName());
                }
            }

            @Override
            public void onError(Error error) {
                Log.d(TAG, "ERROR received" + error.toString());
                playerStreamHandler.reportError(error.getMessage());
            }
        });
    }

    private void initMediaPlayer() {
         mVideoPlayer = this.mService.createVideoPlayer("Default Media Player");

        VideoPlayer.OnVideoPlayerListener videoPlayerListener = new VideoPlayer.OnVideoPlayerListener() {
            @Override
            public void onBufferingStart() {
                Log.v(TAG, "PlayerNotice: onBufferingStart V");
            }

            @Override
            public void onBufferingComplete()
            {
                Log.v(TAG, "Buffering complete. Now seek to " + startingPositionMilliseconds.toString());
                if (initialStart) {
                    initialStart = false;
                    seekTo(startingPositionMilliseconds);
                }
            }

            @Override
            public void onBufferingProgress(int progress) {
            }

            @Override
            public void onCurrentPlayTime(int progress) {
                playbackPositionStreamHandler.updatePlaybackPosition(progress);
            }

            @Override
            public void onStreamingStarted(int duration) {
                Log.v(TAG, "PlayerNotice: onStreamingStarted V: " + duration);
                playerStreamHandler.reportPlaying();
            }

            @Override
            public void onStreamCompleted() {
                Log.v(TAG, "PlayerNotice: onStreamCompleted V");
                playerStreamHandler.reportPlayerPaused();
            }

            @Override
            public void onPlay() {
                Log.v(TAG, "PlayerNotice: onPlay V");
                playerStreamHandler.reportPlaying();
            }

            @Override
            public void onPause() {
                Log.v(TAG, "PlayerNotice: onPause V");
                playerStreamHandler.reportPlayerPaused();
            }

            @Override
            public void onStop() {
                Log.v(TAG, "PlayerNotice: onStop V");
                playerStreamHandler.reportPlayerStopped();
            }

            @Override
            public void onForward() {
                Log.v(TAG, "PlayerNotice: onForward V");
            }

            @Override
            public void onRewind() {
                Log.v(TAG, "PlayerNotice: onRewind V");
            }

            @Override
            public void onMute() {
                Log.v(TAG, "PlayerNotice: onMute V");

            }

            @Override
            public void onUnMute() {
                Log.v(TAG, "PlayerNotice: onUnMute V");
            }

            @Override
            public void onNext() {
                Log.v(TAG, "PlayerNotice: onNext V");
            }

            @Override
            public void onPrevious() {
                Log.v(TAG, "PlayerNotice: onPrevious V");
            }

            @Override
            public void onError(Error error) {
                Log.v(TAG, "PlayerNotice: onError V: " + error.getMessage());
                playerStreamHandler.reportError(error.getMessage());
            }

            @Override
            public void onAddToList(JSONObject enqueuedItem) {
                Log.v(TAG, "PlayerNotice: onAddToList V: " + enqueuedItem.toString());
            }

            @Override
            public void onRemoveFromList(JSONObject dequeuedItem) {
                Log.v(TAG, "PlayerNotice: onRemoveFromList V: " + dequeuedItem.toString());
            }

            @Override
            public void onClearList() {
                Log.v(TAG, "PlayerNotice: onClearList V");
            }

            @Override
            public void onGetList(JSONArray queueList) {
                Log.v(TAG, "PlayerNotice: onGetList V: " + queueList.toString());
            }

            @Override
            public void onRepeat(Player.RepeatMode repeatMode) {
            }

            @Override
            public void onCurrentPlaying(JSONObject currentItem, String playerType) {
                Log.v(TAG, "PlayerNotice: onCurrentPlaying V: " + currentItem.toString());
            }

            @Override
            public void onControlStatus(int volLevel, Boolean muteStatus, VideoPlayer.RepeatMode repeatStatus) {
                Log.v(TAG, "PlayerNotice: onControlStatus V: vol: " + volLevel + ", mute: " + muteStatus + ", repeat: " + repeatStatus.name());
            }

            @Override
            public void onVolumeChange(int level) {
                Log.v(TAG, "PlayerNotice: onVolumeChange V: " + level);
            }

            @Override
            public void onPlayerInitialized() {
                Log.v(TAG, "PlayerNotice: onPlayerInitialized V");
                //mAudioPlayer.removePlayerWatermark();
            }

            @Override
            public void onPlayerChange(String playerType) {
                Log.v(TAG, "PlayerNotice: onPlayerChange V");
            }

            @Override
            public void onApplicationResume() {
                Log.v(TAG, "PlayerNotice: onApplicationResume V");
            }

            @Override
            public void onApplicationSuspend() {
                Log.v(TAG, "PlayerNotice: onApplicationSuspend V");
            }
        };
        mVideoPlayer.addOnMessageListener(videoPlayerListener);

        mVideoPlayer.setOnErrorListener(new Channel.OnErrorListener() {
            @Override
            public void onError(com.samsung.multiscreen.Error error) {
                Log.v(TAG, "setOnErrorListener() called: Error: " + error.getCode() + error.getName() + error.getMessage());
                playerStreamHandler.reportError(error.getMessage());
            }
        });
    }

    private void resetService(){
        this.mService = null;
    }


    /**
     * Method to play content on T.V.
     * @param uri : Url of content which has to be launched on TV.
     * @param title : title of the video.
     */
    void playContent(final String uri,
                     final String title,
                     final Integer startingPositionMilliseconds) {
        if (mVideoPlayer == null ||  mService == null) {
            return;
        }
        Log.i(TAG, "Android: should play video with starting position: " + startingPositionMilliseconds.toString() + " and url " + uri);

        this.startingPositionMilliseconds = startingPositionMilliseconds;
        this.initialStart = true;

        mVideoPlayer.playContent(Uri.parse(uri),
                title,
                null,
                new Result<Boolean>() {
                    @Override
                    public void onSuccess(Boolean r) {
                        Log.v(TAG, "playContent() is successful");
                    }

                    @Override
                    public void onError(com.samsung.multiscreen.Error error) {
                        Log.v(TAG, "playContent(): onError: " + error.getMessage());
                        // during the initial play of the video, the websocket connection to the TV is established.
                        // If that fails, the TV is disconnected
                        readinessStreamHandler.reportNotReady(mService.getName());
                        playerStreamHandler.reportError(error.getMessage());
                    }
                });
        mVideoPlayer.setOnConnectListener(new Channel.OnConnectListener() {
            @Override
            public void onConnect(Client client) {
                Log.v(TAG, "Connection to TV successful");
            }
        });

        mVideoPlayer.setOnDisconnectListener(new Channel.OnDisconnectListener() {
            @Override
            public void onDisconnect(Client client) {
                Log.v(TAG, "Successfully disconnected!");
                playerStreamHandler.reportPlayerDisconnected();
            }
        });
    }

    /*playback controls*/
    void play(){
            mVideoPlayer.play();
    }

    void pause(){
            mVideoPlayer.pause();
    }

    void disconnect() {
        resetService();
        mVideoPlayer.disconnect();
    }
    void stop(){
        mVideoPlayer.stop();
    }

    void forward(){
            mVideoPlayer.forward();
    }

    void rewind(){
            mVideoPlayer.rewind();
    }

    void mute(){
            mVideoPlayer.mute();
    }

    void unmute(){
            mVideoPlayer.unMute();
    }

    void enqueue(final Uri uri,
                 final String title,
                 final Uri thumbnailUrl) {
        mVideoPlayer.addToList(uri, title, thumbnailUrl);
    }

    void enqueue(final List<Map<String, String>> list) {
            mVideoPlayer.addToList(list);
    }

    void dequeue(final Uri uri) {
            mVideoPlayer.removeFromList(uri);
    }

    void fetchQueue() {
            mVideoPlayer.getList();
    }

    void clearQueue() {
            mVideoPlayer.clearList();
    }

    void repeatQueue() {
            mVideoPlayer.repeat();
    }


    void seekTo(int playbackPosition) {
        mVideoPlayer.seekTo(playbackPosition, TimeUnit.MILLISECONDS);
    }

    void getControlStatus() {
            mVideoPlayer.getControlStatus();
    }

    void setVolume(int level) {
            mVideoPlayer.setVolume(level);
    }

    void volumeUp() {
            mVideoPlayer.volumeUp();
    }

    void volumeDown() {
            mVideoPlayer.volumeDown();
    }

    void next() {
            mVideoPlayer.next();
    }

    void setRepeat(AudioPlayer.RepeatMode mode) {
            mVideoPlayer.setRepeat(mode);
    }

    void previous() {
            mVideoPlayer.previous();
    }

    void resumeApplicationInForeground() {
            mVideoPlayer.resumeApplicationInForeground();
    }
}
