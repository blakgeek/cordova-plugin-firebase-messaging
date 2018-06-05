package com.google.firebase.messaging;

import android.os.Bundle;
import java.lang.reflect.Field;

/**
 * Created by blakgeek on 1/10/18.
 */

public class RawRemoteMessage {

    private final RemoteMessage remoteMessage;

    public RawRemoteMessage(RemoteMessage remoteMessage) {
        this.remoteMessage = remoteMessage;
    }

    public Bundle getRawBundle() {

        Field[] fields = RemoteMessage.class.getDeclaredFields();
        Bundle bundle = new Bundle();
        for(Field field : fields){
            if(field.getType().equals(Bundle.class)) {
                try {
                    bundle = (Bundle) field.get(remoteMessage);
                } catch (IllegalAccessException e) {
                    e.printStackTrace();
                }
            }
            break;
        }
        return bundle;
    }
}
