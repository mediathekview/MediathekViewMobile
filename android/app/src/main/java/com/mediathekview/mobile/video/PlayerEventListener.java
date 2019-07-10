package com.mediathekview.mobile.video;

import android.app.Activity;
import android.content.Context;
import android.view.View;
import android.widget.ProgressBar;

import com.google.android.exoplayer2.ExoPlaybackException;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.PlaybackParameters;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.Timeline;
import com.google.android.exoplayer2.source.TrackGroupArray;
import com.google.android.exoplayer2.trackselection.TrackSelectionArray;

public class PlayerEventListener extends Player.DefaultEventListener {

    ProgressBar progressBar;
    ExoPlayer exoPlayer;
    Activity activity;


    public PlayerEventListener(ProgressBar progressBar, ExoPlayer exoPlayer, Activity activity) {
        this.progressBar = progressBar;
        this.exoPlayer = exoPlayer;
        this.activity = activity;
    }

    @Override
    public void onTimelineChanged(Timeline timeline, Object manifest) {

    }

    @Override
    public void onTracksChanged(TrackGroupArray trackGroups, TrackSelectionArray trackSelections) {

    }

    @Override
    public void onLoadingChanged(boolean isLoading) {

    }

    @Override
    public void onPlayerStateChanged(boolean playWhenReady, int playbackState) {
        if (playbackState == ExoPlayer.STATE_BUFFERING){
            progressBar.setVisibility(View.VISIBLE);
        } else {
            progressBar.setVisibility(View.INVISIBLE);
        }

        if (playbackState == ExoPlayer.STATE_ENDED){
            exoPlayer.release();
            activity.finish();
        }
    }

    @Override
    public void onRepeatModeChanged(int repeatMode) {

    }

    @Override
    public void onPlayerError(ExoPlaybackException error) {
        // TODO close activity and raise an error
    }


    @Override
    public void onPlaybackParametersChanged(PlaybackParameters playbackParameters) {

    }
}
