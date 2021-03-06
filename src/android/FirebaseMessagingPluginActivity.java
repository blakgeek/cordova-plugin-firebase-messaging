package com.blakgeek.cordova.plugin.firebase;

import android.app.Activity;
import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

public class FirebaseMessagingPluginActivity extends Activity {
    private static String TAG = "FCMPlugin";

    /*
     * this activity will be started if the user touches a notification that we own.
     * We send it's data off to the push plugin for processing.
     * If needed, we boot up the main activity to kickstart the application.
     * @see android.app.Activity#onCreate(android.os.Bundle)
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(TAG, "==> FCMPluginActivity onCreate");

        Map<String, Object> data = new HashMap<>();
        if (getIntent().getExtras() != null) {
            for (String key : getIntent().getExtras().keySet()) {
                data.put(key, getIntent().getExtras().get(key));
            }
        }

        data.put("$appState", FirebaseMessagingPlugin.isActive() ? 1 : 2);

        FirebaseMessagingPlugin.sendPushPayload(data);

        finish();

        forceMainActivityReload();
    }

    private void forceMainActivityReload() {
        PackageManager pm = getPackageManager();
        Intent launchIntent = pm.getLaunchIntentForPackage(getApplicationContext().getPackageName());
        startActivity(launchIntent);
    }

    @Override
    protected void onResume() {
        super.onResume();
        Log.d(TAG, "==> FCMPluginActivity onResume");
        final NotificationManager notificationManager = (NotificationManager) this.getSystemService(Context.NOTIFICATION_SERVICE);
        notificationManager.cancelAll();
    }


}
