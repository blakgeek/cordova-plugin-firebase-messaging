package com.blakgeek.cordova.plugin.firebase;

import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.media.RingtoneManager;
import android.net.Uri;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by Felipe Echanique on 08/06/2016.
 */
public class FirebaseMessagingPluginService extends FirebaseMessagingService {

    private static final String TAG = "FirebaseMessagingPlugin";

    /**
     * Called when message is received.
     *
     * @param remoteMessage Object representing the message received from Firebase Cloud Messaging.
     */
    // [START receive_message]
    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {

        Log.d(TAG, "==> MyFirebaseMessagingService onMessageReceived");
        String title = null;
        String message = null;
        RemoteMessage.Notification notification = remoteMessage.getNotification();

        if (notification != null) {
            title = notification.getTitle();
            message = notification.getBody();
        }

        Map<String, Object> data = new HashMap<>();
        if(!FirebaseMessagingPlugin.isActive()) {
            data.put("$appState", 2);
        } else if(FirebaseMessagingPlugin.isInForeground()) {
            data.put("$appState", 0);
        } else {
            data.put("$appState", 1);
        }

        for (String key : remoteMessage.getData().keySet()) {
            String value = remoteMessage.getData().get(key);
            Log.d(TAG, "\tKey: " + key + " Value: " + value);
            data.put(key, value);
            if (title == null && "title".equalsIgnoreCase(key)) {
                title = value;
            }

            if (message == null && "body".equalsIgnoreCase(key)) {
                message = value;
            }
        }

        Log.d(TAG, "\tNotification Data: " + data.toString());

        if(FirebaseMessagingPlugin.isInForeground()) {
            FirebaseMessagingPlugin.sendPushPayload(data);
        } else if(title != null || message != null){
            sendNotification(title, message, data);
        }
    }
    // [END receive_message]

    /**
     * Create and show a simple notification containing the received FCM message.
     *
     * @param messageBody FCM message body received.
     */
    private void sendNotification(String title, String messageBody, Map<String, Object> data) {
        Intent intent = new Intent(this, FirebaseMessagingPluginActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        for (String key : data.keySet()) {
            intent.putExtra(key, data.get(key).toString());
        }
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0 /* Request code */, intent,
            PendingIntent.FLAG_ONE_SHOT);

        Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
        NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(this)
            .setSmallIcon(getApplicationInfo().icon)
            .setContentTitle(title)
            .setContentText(messageBody)
            .setAutoCancel(true)
            .setSound(defaultSoundUri)
            .setContentIntent(pendingIntent);

        NotificationManager notificationManager =
            (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        notificationManager.notify(0 /* ID of notification */, notificationBuilder.build());
    }
}
