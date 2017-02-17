package com.blakgeek.cordova.plugin.firebase;

import android.util.Log;

import com.google.firebase.iid.FirebaseInstanceId;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.gson.Gson;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class FirebaseMessagingPlugin extends CordovaPlugin {

    private static final String TAG = "FCMPlugin";
    private static final String EVENT_PUSH_NOTIFICATION = "pushnotification";
    private static final String ACTION_INIT = "init";
    private static final String ACTION_SUBSCRIBE = "subscribe";
    private static final String ACTION_UNSUBSCRIBE = "unsubscribe";
    private static final String ACTION_GET_TOKEN = "getToken";
    private static final String ACTION_FLUSH = "flush";

    private static CordovaWebView gWebView;
    private static List<Map<String, Object>> pendingNotifications = new ArrayList<>();
    private static boolean inForeground = false;
    private static CallbackContext eventContext;

    public FirebaseMessagingPlugin() {
    }

    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        gWebView = webView;
    }

    public boolean execute(final String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {

        switch (action) {
            case ACTION_INIT:
                return init(args, callbackContext);
            case ACTION_SUBSCRIBE:
                return subscribe(args, callbackContext);
            case ACTION_UNSUBSCRIBE:
                return unsubscribe(args, callbackContext);
            case ACTION_GET_TOKEN:
                return getToken(callbackContext);
            case ACTION_FLUSH:
                return flush();
        }

        return true;
    }

    private boolean getToken(final CallbackContext callbackContext) {

        cordova.getActivity().runOnUiThread(new Runnable() {
            public void run() {
                try {
                    String token = FirebaseInstanceId.getInstance().getToken();
                    callbackContext.success(token);
                    Log.d(TAG, "\tToken: " + token);
                } catch (Exception e) {
                    Log.d(TAG, "\tError retrieving token");
                    callbackContext.error(e.getMessage());
                }
            }
        });
        return true;
    }

    private boolean subscribe(final JSONArray args, final CallbackContext callbackContext) {

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    String topic = args.getString(0);
                    FirebaseMessaging.getInstance().subscribeToTopic(topic);
                    callbackContext.success();
                    Log.d(TAG, "Subscribed To Topic: " + topic);
                } catch (Exception e) {
                    callbackContext.error(e.getMessage());
                }
            }
        });
        return true;
    }

    private boolean unsubscribe(final JSONArray args, final CallbackContext callbackContext) {

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    String topic = args.getString(0);
                    FirebaseMessaging.getInstance().subscribeToTopic(topic);
                    callbackContext.success();
                    Log.d(TAG, "Unsubscribed From Topic: " + topic);
                } catch (Exception e) {
                    callbackContext.error(e.getMessage());
                }
            }
        });
        return true;
    }

    private boolean init(JSONArray args, CallbackContext callbackContext) {
        eventContext = callbackContext;
        return true;
    }

    private boolean flush() {

        for(Map<String, Object> payload : pendingNotifications) {
            raiseEvent(EVENT_PUSH_NOTIFICATION, payload);
        }
        pendingNotifications.clear();
        return true;
    }

    static void sendPushPayload(Map<String, Object> payload) {

        Log.d(TAG, "==> FCMPlugin sendPushPayload");
        Log.d(TAG, "\tgWebView: " + gWebView);

        if (gWebView != null) {
            raiseEvent(EVENT_PUSH_NOTIFICATION, payload);
        } else {
            pendingNotifications.add(payload);
        }
    }

    private static void raiseEvent(String type) {
        raiseEvent(type, null);
    }

    private static void raiseEvent(String type, Object payload) {

        if (eventContext != null) {

            try {
                JSONObject event = new JSONObject();
                Gson gson = new Gson();
                JSONObject data = new JSONObject(gson.toJson(payload));
                event.put("type", type);
                event.put("data", data);
                PluginResult result = new PluginResult(PluginResult.Status.OK, event);
                result.setKeepCallback(true);
                eventContext.sendPluginResult(result);

            } catch (JSONException e) {
                Log.d(TAG, "raising event failed: " + e.getMessage());
            }
        }
    }

    @Override
    public void onPause(boolean multitasking) {

        inForeground = false;
    }

    @Override
    public void onResume(boolean multitasking) {

        inForeground = true;
    }

    @Override
    public void onStart() {

        inForeground = true;
    }

    static boolean isInForeground() {
        return inForeground;
    }

    public static boolean isActive() {
        return gWebView != null;
    }
}
