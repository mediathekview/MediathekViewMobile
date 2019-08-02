package com.mediathekview.mobile.activity;

import android.app.ActionBar;
import android.app.Activity;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import com.google.android.exoplayer2.C;
import com.google.android.exoplayer2.ExoPlayerFactory;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.source.ExtractorMediaSource;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.dash.DashMediaSource;
import com.google.android.exoplayer2.source.dash.DefaultDashChunkSource;
import com.google.android.exoplayer2.source.hls.HlsMediaSource;
import com.google.android.exoplayer2.source.smoothstreaming.DefaultSsChunkSource;
import com.google.android.exoplayer2.source.smoothstreaming.SsMediaSource;
import com.google.android.exoplayer2.trackselection.AdaptiveTrackSelection;
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector;
import com.google.android.exoplayer2.trackselection.TrackSelection;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.SimpleExoPlayerView;
import com.google.android.exoplayer2.upstream.*;
import com.google.android.exoplayer2.upstream.cache.*;
import com.google.android.exoplayer2.util.Util;
import com.mediathekview.mobile.MainActivity;
import com.mediathekview.mobile.R;
import com.mediathekview.mobile.video.PlayerEventListener;
import com.mediathekview.mobile.video.VideoCallHandler;

import java.io.File;
import java.util.concurrent.TimeUnit;

import io.reactivex.Observable;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.disposables.Disposable;

//Based of mainly from  https://github.com/yusufcakmak/ExoPlayerSample
public class VideoPlayerActivity extends Activity {

    private SimpleExoPlayerView simpleExoPlayerView;
    private SimpleExoPlayer player;

    private DataSource.Factory mediaDataSourceFactory;
    private DefaultTrackSelector trackSelector;
    private boolean shouldAutoPlay;


    private ImageView ivHideControllerButton;
    private Uri filePath;
    private String videoId;
    private long playbackPosition;

    //Cache functionality
    private static final DefaultBandwidthMeter BANDWIDTH_METER = new DefaultBandwidthMeter();
    private static String userAgent;
    private static Cache downloadCache;
    private static File downloadDirectory;
    private static final String DOWNLOAD_CONTENT_DIRECTORY = "mediathekviewcache";


    public Observable<Long> progressObservable = Observable.interval(5, TimeUnit.SECONDS).map((second) -> player.getCurrentPosition() )
            .observeOn(AndroidSchedulers.mainThread());
    private Disposable playbackDisposable;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (Build.VERSION.SDK_INT < 16) {
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    WindowManager.LayoutParams.FLAG_FULLSCREEN);
        } else {
            View decorView = getWindow().getDecorView();
            // Hide the status bar.
            int uiOptions = View.SYSTEM_UI_FLAG_FULLSCREEN;
            decorView.setSystemUiVisibility(uiOptions);

            ActionBar actionBar = getActionBar();
            if (actionBar != null)
                actionBar.hide();
        }

        setContentView(R.layout.activity_video_player);


        userAgent = Util.getUserAgent(this, "MediathekView Mobile");


        String fileUrl = getIntent().getStringExtra(VideoCallHandler.FILE_PATH);
        videoId = getIntent().getStringExtra(VideoCallHandler.VIDEO_ID);
        playbackPosition = getIntent().getLongExtra(VideoCallHandler.PROGRESS, 0);
        filePath = Uri.parse(fileUrl);

        shouldAutoPlay = true;
        //bandwidthMeter = new DefaultBandwidthMeter();
        mediaDataSourceFactory = buildDataSourceFactory(true);
        ivHideControllerButton = (ImageView) findViewById(R.id.exo_controller);
    }

    private void initializePlayer() {

        simpleExoPlayerView = (SimpleExoPlayerView) findViewById(R.id.player_view);
        simpleExoPlayerView.requestFocus();

        TrackSelection.Factory videoTrackSelectionFactory =
                new AdaptiveTrackSelection.Factory(BANDWIDTH_METER);

        trackSelector = new DefaultTrackSelector(videoTrackSelectionFactory);

        player = ExoPlayerFactory.newSimpleInstance(this, trackSelector);

        MediaSource mediaSource = buildMediaSource(filePath);

        player.seekTo(playbackPosition);

        player.addListener(new PlayerEventListener(findViewById(R.id.exo_player_progress_bar), player, this));
        simpleExoPlayerView.setPlayer(player);
        simpleExoPlayerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT);

        player.setPlayWhenReady(shouldAutoPlay);

        player.prepare(mediaSource, false, false);

        Log.i("VideoPlayer", "Opening url " + filePath);


        ivHideControllerButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                simpleExoPlayerView.hideController();
            }
        });
    }

    private void trackProgress() {
         playbackDisposable = progressObservable.subscribe(progress -> {
                    Log.i("VideoPlayer", "Playback position: " + progress);
                    MainActivity.videoProgressStreamHandler.updateProgress(videoId, progress);
                });
    }

    private void stopTrackingProgress() {
        if (playbackDisposable != null) {
            playbackDisposable.dispose();
        }
    }

    private void releasePlayer() {
        if (player != null) {
            shouldAutoPlay = player.getPlayWhenReady();
            player.release();
            player = null;
            trackSelector = null;
        }
        stopTrackingProgress();
    }

    @Override
    public void onStart() {
        super.onStart();
        if (Util.SDK_INT > 23) {
            initializePlayer();
            trackProgress();
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        if ((Util.SDK_INT <= 23 || player == null)) {
            initializePlayer();
            trackProgress();
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        if (Util.SDK_INT <= 23) {
            releasePlayer();
            stopTrackingProgress();
        }
    }

    @Override
    public void onStop() {
        super.onStop();
        if (Util.SDK_INT > 23) {
            releasePlayer();
            stopTrackingProgress();
        }
    }



    // _________________The FOLLOWING IS TAKEN FROM https://github.com/google/ExoPlayer/blob/release-v2/demos/main/src/main/java/com/google/android/exoplayer2/demo/PlayerActivity.java  ------------------

    private MediaSource buildMediaSource(Uri uri) {
        //Fails for m3u8 urls?
        Log.i("VideoPlayer", "Mediasource for  url " + uri);
        @C.ContentType int type;
        if (uri.toString().contains("m3u8")) {
            type = 2;
            Log.i("VideoPlayer", "Detected live stream");

        } else {
            type = Util.inferContentType(uri);
        }
        switch (type) {
            case C.TYPE_DASH:

                Log.i("VideoPlayer", "Mime Type: DASH");

                return new DashMediaSource.Factory(
                        new DefaultDashChunkSource.Factory(mediaDataSourceFactory),
                        buildDataSourceFactory(false))
                        .createMediaSource(uri);
            case C.TYPE_SS:
                Log.i("VideoPlayer", "Mime Type: SS");

                return new SsMediaSource.Factory(
                        new DefaultSsChunkSource.Factory(mediaDataSourceFactory),
                        buildDataSourceFactory(false))
                        .createMediaSource(uri);


            case C.TYPE_HLS:
                Log.i("VideoPlayer", "Mime Type: HLS");
                return new HlsMediaSource.Factory(mediaDataSourceFactory)
                        .setAllowChunklessPreparation(true)
                        .createMediaSource(uri);
               /* return new HlsMediaSource((uri),
                        mediaDataSourceFactory, null, null); */
            case C.TYPE_OTHER:
                Log.i("VideoPlayer", "Mime Type: OTHER");
                return new ExtractorMediaSource.Factory(mediaDataSourceFactory).createMediaSource(uri);
                /*return new ExtractorMediaSource((filePath),
                        mediaDataSourceFactory, extractorsFactory, null, null);*/
            default: {
                //TODO show toast
                throw new IllegalStateException("Unsupported type: " + type);
            }
        }
    }

    /**
     * Returns a new DataSource factory.
     *
     * @param useBandwidthMeter Whether to set {@link #BANDWIDTH_METER} as a listener to the new
     *                          DataSource factory.
     * @return A new DataSource factory.
     */
    private DataSource.Factory buildDataSourceFactory(boolean useBandwidthMeter) {
        return buildDataSourceFactory(useBandwidthMeter ? BANDWIDTH_METER : null);
    }

    public DataSource.Factory buildDataSourceFactory(TransferListener listener) {
        DefaultDataSourceFactory upstreamFactory =
                new DefaultDataSourceFactory(this, listener, buildHttpDataSourceFactory(listener));
        return buildReadOnlyCacheDataSource(upstreamFactory, getDownloadCache());
    }

    /**
     * Returns a {@link HttpDataSource.Factory}.
     */
    public HttpDataSource.Factory buildHttpDataSourceFactory(
            TransferListener listener) {
        return new DefaultHttpDataSourceFactory(userAgent, listener);
    }

    private synchronized Cache getDownloadCache() {
        if (downloadCache == null) {
            File downloadContentDirectory = new File(getDownloadDirectory(), DOWNLOAD_CONTENT_DIRECTORY);
            downloadCache = new SimpleCache(downloadContentDirectory, new NoOpCacheEvictor());
        }
        return downloadCache;
    }

    private File getDownloadDirectory() {
        if (downloadDirectory == null) {
            downloadDirectory = getExternalFilesDir(null);
            if (downloadDirectory == null) {
                downloadDirectory = getFilesDir();
            }
        }
        return downloadDirectory;
    }

    private static CacheDataSourceFactory buildReadOnlyCacheDataSource(
            DefaultDataSourceFactory upstreamFactory, Cache cache) {
        return new CacheDataSourceFactory(
                cache,
                upstreamFactory,
                new FileDataSourceFactory(),
                /* cacheWriteDataSinkFactory= */ null,
                CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR,
                /* eventListener= */ null);
    }

}