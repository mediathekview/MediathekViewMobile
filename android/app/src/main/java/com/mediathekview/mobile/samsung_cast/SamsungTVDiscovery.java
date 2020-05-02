package com.mediathekview.mobile.samsung_cast;

import android.content.Context;
import android.util.Log;
import android.view.View;

import com.samsung.multiscreen.Search;
import com.samsung.multiscreen.Service;

import java.util.HashMap;
import java.util.Map;



public class SamsungTVDiscovery extends View {
    private Context context;
    private static String TAG = "TVSearch";
    private Search mSearch = null;
    private static SamsungTVDiscovery mInstance = null;

    // EVENT Handlers
    FoundTVsStreamHandler foundTVsStreamHandler;
    LostTVsStreamHandler lostTVsStreamHandler;

    // keeps a list of available tvs
    Map<String, Service> availableTvs = new HashMap<>();

    public static SamsungTVDiscovery getInstance(Context context, FoundTVsStreamHandler foundTVsStreamHandler, LostTVsStreamHandler lostTVsStreamHandler) {
        if(mInstance == null) {
            mInstance = new SamsungTVDiscovery(context, foundTVsStreamHandler, lostTVsStreamHandler);
        }
        return mInstance;
    }


    private SamsungTVDiscovery(Context context, FoundTVsStreamHandler foundTVsStreamHandler, LostTVsStreamHandler lostTVsStreamHandler) {
        super(context);
        this.context = context;
        this.foundTVsStreamHandler=foundTVsStreamHandler;
        this.lostTVsStreamHandler=lostTVsStreamHandler;
    }

    public Service getTvForName(String name){
        return availableTvs.get(name);
    }

    private void addTV(final Service service) {
        if (service != null) {
            foundTVsStreamHandler.reportFoundTV(service.getName());
            availableTvs.put(service.getName(), service);
        }
    }

    private void removeTV(final Service service) {
        if (service != null &&  availableTvs.containsKey(service.getName())) {
            lostTVsStreamHandler.reportLostTV(service.getName());
            availableTvs.remove(service.getName());
        }
    }

    /*Start TV Discovery*/
    void startDiscovery(Boolean showStandbyDevices) {
        if(mSearch == null)
        {
            mSearch = Service.search(context);

            Log.v(TAG, "Device (" + mSearch + ") Search instantiated..");
            mSearch.setOnServiceFoundListener(new Search.OnServiceFoundListener() {
                @Override
                public void onFound(Service service) {
                    Log.v(TAG, "Discovered TV: " + service);
                    addTV(service);
                }
            });

            mSearch.setOnStartListener(new Search.OnStartListener() {
                @Override
                public void onStart() {
                    Log.v(TAG, "Starting Discovery.");
                }
            });

            mSearch.setOnStopListener(new Search.OnStopListener() {
                @Override
                public void onStop() {
                    Log.v(TAG, "Discovery Stopped.");
                }
            });

            mSearch.setOnServiceLostListener(new Search.OnServiceLostListener() {
                @Override
                public void onLost(Service service) {
                    Log.v(TAG, "Discovery: lost connection to TV");
                    removeTV(service);
                }
            });
        }

        mSearch.start(showStandbyDevices);
        return;
    }

    /* Stop TV Discovery*/
    void stopDiscovery() {
        if (null != mSearch)
        {
            mSearch.stop();
            Log.v(TAG, "Stopping Discovery.");
        }

    }
}

