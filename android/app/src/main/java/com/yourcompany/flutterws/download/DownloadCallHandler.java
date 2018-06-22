package com.yourcompany.flutterws.download;

import android.annotation.TargetApi;
import android.app.DownloadManager;
import android.content.Context;
import android.os.Build;
import android.util.Log;
import android.webkit.MimeTypeMap;

import com.yourcompany.flutterws.MainActivity;

import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class DownloadCallHandler implements MethodChannel.MethodCallHandler {

    private static final String TAG = "DOWNLOAD_CALL_HANDLER";
    private Context context;
    private DownloadManager downloadManager;
    private DownloadStreamHandler streamHandler;

    //Special case: No permission yet to access storage
    private String lastRequestedDownloadFileName;
    private String lastRequestedDownloadVideoUrl;
    private String lastRequestedDownloadUserDownloadId;

    public DownloadCallHandler(Context context, DownloadManager downloadManager, DownloadStreamHandler streamHandler) {
        this.context = context;
        this.downloadManager = downloadManager;
        this.streamHandler = streamHandler;
    }

    public String  getLastRequestedDownloadFileName(){return lastRequestedDownloadFileName;}
    public String  getLastRequestedDownloadVideoUrl(){return lastRequestedDownloadVideoUrl;}
    public String  getLastRequestedDownloadUserDownloadId(){return lastRequestedDownloadUserDownloadId;}

    @TargetApi(Build.VERSION_CODES.GINGERBREAD)
    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {

        Log.i("Method Call Handler", "Method call with identifier " + call.method + " received");

        if (call.method.equals("downloadFile")) {

            String fileName = call.argument("fileName");
            String videoUrl = call.argument("videoUrl");
            String userDownloadId = call.argument("userDownloadId");

            if (fileName == null || fileName.isEmpty() || videoUrl == null || videoUrl.isEmpty()) {
                result.error("Invalid Invocation", "Missing arguments. Both parameters 'fileName' and 'url' have to be specified", null);
                return;
            }


            if (MainActivity.currentlyRunning.get(userDownloadId) != null){
                Log.i("Method Call Handler", "File download with userId " + userDownloadId + " & name " + fileName + " is already running");
            }

            Log.i("Method Call Handler", "Download File Request received for file with userId " + userDownloadId + " & name " + fileName + " and url " + videoUrl + " and Mime Type " + MimeTypeMap.getFileExtensionFromUrl(videoUrl));


            Integer downloadManagerId = (int) com.yourcompany.flutterws.download.DownloadUtil.enqueueFile(context, downloadManager, fileName, videoUrl);

            if (downloadManagerId == -1){
                lastRequestedDownloadFileName = fileName;
                lastRequestedDownloadUserDownloadId = userDownloadId;
                lastRequestedDownloadVideoUrl = videoUrl;
                //result.error("No Permission", "Permission to write to external filesystem needed", null);
                result.success("-1");
                return;
            }

            //TODO check if progress is only needed once
            streamHandler.startProgressChecker();

            if (userDownloadId == null || userDownloadId.isEmpty()) {
                Log.i("Method Call Handler", "User Download id not specified. Putting in download list:  userId " + userDownloadId + "  and manager id " + downloadManagerId);
                streamHandler.startProgressChecker();
                MainActivity.currentlyRunning.put(String.valueOf(downloadManagerId), downloadManagerId);
                result.success(String.valueOf(downloadManagerId));
            } else {
                streamHandler.startProgressChecker();
                MainActivity.currentlyRunning.put(userDownloadId, downloadManagerId);
                result.success(userDownloadId);
            }

        }

        if (call.method.equals("status")) {
            String userId = call.argument("id");

            Map<String, String> returnParameters;
            Integer downloadManagerId = MainActivity.currentlyRunning.get(userId);

            if (downloadManagerId == null) {
                result.error("Not Found", " No download with id " + userId + "could be found", null);
                return;
            }

            Log.i("Method Call Handler", "Requesting download status for user id " + userId + " -> download id: " + downloadManagerId);

            try {
                returnParameters = com.yourcompany.flutterws.download.DownloadUtil.getStatus(downloadManager, downloadManagerId, userId);
               // Log.i("Method Call Handler", "Received download parameters " + returnParameters.entrySet().stream().map((entry) -> " " + entry.getKey() + ": " + entry.getValue() + " ").reduce(String::concat));
            } catch (Exception e) {
                Log.i("Method Call Handler", "Error getting download status for id " + userId + " Error: " + e.getMessage());
                result.error("Unknown error", e.getMessage(), e);
                return;
            }

            if (!returnParameters.isEmpty())
                result.success(returnParameters);
            else
                result.error("Unknown error", " No download with id " + userId + "could be found", null);
            return;
        }

        if (call.method.equals("cancelDownload")) {
            String userId = call.argument("id");
            Integer downloadManagerId = MainActivity.currentlyRunning.get(userId);

            if (downloadManagerId == null) {
                result.error("Download Unknown", "Download with id " + userId + " could not be removed because the ap does not know about a running download with that id", null);
                return;
            }
            Log.i("Method Call Handler", "Canceling video with id " + userId);
            int amountOfRemovedDownloads = downloadManager.remove(downloadManagerId);

            MainActivity.currentlyRunning.remove(userId);

            streamHandler.notifyChanceled(userId);

            if (amountOfRemovedDownloads == 0){
                result.error("Download Unknown" , "Download with id " + userId + " could not be removed because the Android DownloadManager has no download with that id. This might be an inconsistency between the current downloads in the app and the download manager.", null);
            } else {
                //currently only able to stop one download at a time anyways
                result.success(amountOfRemovedDownloads);
            }
        }
    }
}
