package com.google.firebase.messaging;

import android.os.Bundle;

/**
 * Created by blakgeek on 1/10/18.
 */

public class RawRemoteMessage {

    private final RemoteMessage remoteMessage;

    public RawRemoteMessage(RemoteMessage remoteMessage) {
        this.remoteMessage = remoteMessage;
    }

    public Bundle getRawBundle() {
        return remoteMessage.mBundle;
    }
}
