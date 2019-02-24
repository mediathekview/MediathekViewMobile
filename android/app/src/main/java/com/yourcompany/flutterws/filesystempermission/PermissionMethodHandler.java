package com.yourcompany.flutterws.filesystempermission;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import com.yourcompany.flutterws.MainActivity;

import java.util.HashMap;

import androidx.core.app.ActivityCompat;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class PermissionMethodHandler implements MethodChannel.MethodCallHandler {

    private static final String TAG = "Permission";
    private Context context;

    public PermissionMethodHandler(Context context) {
        this.context = context;
    }

    @TargetApi(Build.VERSION_CODES.GINGERBREAD)
    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        Log.i(TAG, "Method call with identifier " + call.method + " received");

         if (call.method.equals("hasFilesystemPermission")) {

            Log.i(TAG, "Android: checking for Filesystem Permission");
            HashMap<String, String> res = new HashMap<>();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && context.checkSelfPermission("android.permission.WRITE_EXTERNAL_STORAGE")
                        != PackageManager.PERMISSION_GRANTED) {

                Log.i(TAG, "has no permission");
                res.put("hasPermission", String.valueOf(false));
            } else {
                Log.i(TAG, "has permission already");
                res.put("hasPermission", String.valueOf(true));
            }
             result.success(res);
        }
        else if (call.method.equals("askUserForPermission")){
             Log.i(TAG, "Android: asking for Filesystem Permission");
             HashMap<String, String> res = new HashMap<>();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (context.checkSelfPermission("android.permission.WRITE_EXTERNAL_STORAGE")
                        != PackageManager.PERMISSION_GRANTED) {

                    ActivityCompat.requestPermissions(MainActivity.mainActivity,
                            new String[]{"android.permission.WRITE_EXTERNAL_STORAGE"},
                            0);
                    res.put("AlreadyGranted", String.valueOf(false));
                }
            }else {
                res.put("AlreadyGranted", String.valueOf(true));
            }
             // Permission already granted
            result.success(res);
        }
    }
}
