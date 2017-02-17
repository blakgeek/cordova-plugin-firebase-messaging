# Cordova Firebase Messaging Plugin
This plugin adds Firebase Cloud Messaging support to your Cordova and Phonegap apps.

The goal was have push notifications be fired as native javascript events and make of Promises.

## How do I install it? ##

```
cordova plugin add https://github.com/blakgeek/cordova-plugin-firebase-messaging
```

or

```
phonegap local plugin add https://github.com/blakgeek/cordova-plugin-firebase-messaging
```

## How do I use it? ##

```javascript
window.addEventListener('pushnotification', function(notification) {
    
    // was the app in the forground when the notification was received?
    var inForground = notification.$foreground;
    // was the app active when then notification was received?
    notification.$active;
    
    alert()
}, false);
```



This plugin was inspired by this great plugin https://github.com/fechanique/cordova-plugin-fcm thanks fechanique.



