package com.yourcompany.flutterws.download;

import android.annotation.TargetApi;
import android.app.DownloadManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.support.v4.app.ActivityCompat;
import android.util.Log;
import android.webkit.MimeTypeMap;

import com.yourcompany.flutterws.MainActivity;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import static android.app.DownloadManager.Request.VISIBILITY_HIDDEN;


public class DownloadUtil {

    @TargetApi(Build.VERSION_CODES.HONEYCOMB)
     public static long enqueueFile(Context context, DownloadManager manager, String filename, String uri) {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (context.checkSelfPermission("android.permission.WRITE_EXTERNAL_STORAGE")
                    != PackageManager.PERMISSION_GRANTED) {

                ActivityCompat.requestPermissions(MainActivity.mainActivity,
                        new String[]{"android.permission.WRITE_EXTERNAL_STORAGE"},
                        0);
                return -1;
            }
        }
        File direct = new File(Environment.getExternalStorageDirectory()
                + "/MediathekView");

        direct.mkdirs();

        DownloadManager.Request request = new DownloadManager.Request(Uri.parse(uri))
                .setTitle(filename)
                .setMimeType(MimeTypeMap.getFileExtensionFromUrl(uri))
                .setNotificationVisibility(VISIBILITY_HIDDEN)
                .setDestinationInExternalPublicDir("/MediathekView", filename);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB)
        {
            request.allowScanningByMediaScanner();
//            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
        }

        return  manager.enqueue(request);
    }

    @TargetApi(Build.VERSION_CODES.GINGERBREAD)
    public static Map<String, String> getStatus(DownloadManager downloadManager, Integer downloadManagerId, String userDownloadId){

    DownloadManager.Query ImageDownloadQuery = new DownloadManager.Query();
    ImageDownloadQuery.setFilterById(downloadManagerId);
    Cursor cursor = downloadManager.query(ImageDownloadQuery);

        if(cursor.moveToFirst())
            return  getReturnArguments(cursor, userDownloadId, downloadManagerId, downloadManager);
        return new HashMap<>();
    }

    @TargetApi(Build.VERSION_CODES.HONEYCOMB)
    private static Map<String, String> getReturnArguments(Cursor cursor, String userDownloadId, Integer downloadManagerId, DownloadManager downloadManager){
        Map<String, String> returnArguments = new HashMap<>();

        int columnIndex = cursor.getColumnIndex(DownloadManager.COLUMN_STATUS);
        int status = cursor.getInt(columnIndex);
        int columnReason = cursor.getColumnIndex(DownloadManager.COLUMN_REASON);
        int reason = cursor.getInt(columnReason);

        String statusText = "";
        String reasonText = "";

        switch(status){
            case DownloadManager.STATUS_FAILED:
                statusText = "STATUS_FAILED";
                switch(reason){
                    case DownloadManager.ERROR_CANNOT_RESUME:
                        reasonText = "ERROR_CANNOT_RESUME";
                        break;
                    case DownloadManager.ERROR_DEVICE_NOT_FOUND:
                        reasonText = "ERROR_DEVICE_NOT_FOUND";
                        break;
                    case DownloadManager.ERROR_FILE_ALREADY_EXISTS:
                        reasonText = "ERROR_FILE_ALREADY_EXISTS";
                        break;
                    case DownloadManager.ERROR_FILE_ERROR:
                        reasonText = "ERROR_FILE_ERROR";
                        break;
                    case DownloadManager.ERROR_HTTP_DATA_ERROR:
                        reasonText = "ERROR_HTTP_DATA_ERROR";
                        break;
                    case DownloadManager.ERROR_INSUFFICIENT_SPACE:
                        reasonText = "ERROR_INSUFFICIENT_SPACE";
                        break;
                    case DownloadManager.ERROR_TOO_MANY_REDIRECTS:
                        reasonText = "ERROR_TOO_MANY_REDIRECTS";
                        break;
                    case DownloadManager.ERROR_UNHANDLED_HTTP_CODE:
                        reasonText = "ERROR_UNHANDLED_HTTP_CODE";
                        break;
                    case DownloadManager.ERROR_UNKNOWN:
                        reasonText = "ERROR_UNKNOWN";
                        break;
                }
                break;
            case DownloadManager.STATUS_PAUSED:
                statusText = "STATUS_PAUSED";
                switch(reason){
                    case DownloadManager.PAUSED_QUEUED_FOR_WIFI:
                        reasonText = "PAUSED_QUEUED_FOR_WIFI";
                        break;
                    case DownloadManager.PAUSED_UNKNOWN:
                        reasonText = "PAUSED_UNKNOWN";
                        break;
                    case DownloadManager.PAUSED_WAITING_FOR_NETWORK:
                        reasonText = "PAUSED_WAITING_FOR_NETWORK";
                        break;
                    case DownloadManager.PAUSED_WAITING_TO_RETRY:
                        reasonText = "PAUSED_WAITING_TO_RETRY";
                        break;
                }
                break;
            case DownloadManager.STATUS_PENDING:
                statusText = "STATUS_PENDING";
                break;
            case DownloadManager.STATUS_RUNNING:
                statusText = "STATUS_RUNNING";
                break;
            case DownloadManager.STATUS_SUCCESSFUL:
                statusText = "STATUS_SUCCESSFUL";
                Uri path  = downloadManager.getUriForDownloadedFile(downloadManagerId);
                String mimeType = downloadManager.getMimeTypeForDownloadedFile(downloadManagerId);
                returnArguments.put("filePath", path.toString());
                returnArguments.put("mimeType", mimeType);
                break;
        }
        int bytesDownloaded = cursor.getInt(cursor
                .getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));

        int bytesTotal = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));
        final double dlProgress = ((bytesDownloaded * 100l) / bytesTotal);

//        Log.i("Download Util", "Video: "+ userDownloadId + " - Bytes Downloaded so far : " + bytesDownloaded);
//        Log.i("Download Util", "Video: "+ userDownloadId + " - Bytes Total : " + bytesTotal);
        Log.i("Download Util", "Video: "+ userDownloadId + " - Progress : " + dlProgress);

        if (bytesTotal == 0 || bytesTotal < 0)
            returnArguments.put("progress", "-1");
         else returnArguments.put("progress", String.valueOf(dlProgress));

        returnArguments.put("totalActiveCount", String.valueOf(MainActivity.currentlyRunning.size()));
        returnArguments.put("statusText", statusText);
        returnArguments.put("reasonText", reasonText);
        returnArguments.put("id", userDownloadId);

        return returnArguments;
    }
}
