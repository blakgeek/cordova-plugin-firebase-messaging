//
//  AppDelegate+FirebaseMessagingPlugin.m
//  TestApp
//
//  Created by felipe on 12/06/16.
//
//
#import "AppDelegate+FirebaseMessagingPlugin.h"
#import "FirebaseMessagingPlugin.h"
#import <objc/runtime.h>


#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

@import UserNotifications;

#endif

@import Firebase;

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

@interface AppDelegate () <UNUserNotificationCenterDelegate, FIRMessagingDelegate>
@end

#endif

#import "Firebase.h"

@implementation AppDelegate (MCPlugin)

NSString *const kGCMMessageIDKey = @"gcm.message_id";

static NSDictionary *pendingMessage;

//Method swizzling
+ (void)load {
    Method original = class_getInstanceMethod(self, @selector(application:didFinishLaunchingWithOptions:));
    Method custom = class_getInstanceMethod(self, @selector(application:customDidFinishLaunchingWithOptions:));
    method_exchangeImplementations(original, custom);
}

- (BOOL)application:(UIApplication *)application customDidFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [self application:application customDidFinishLaunchingWithOptions:launchOptions];

    NSLog(@"DidFinishLaunchingWithOptions");
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    [FIRMessaging messaging].delegate = self;
    [FIRApp configure];

    return YES;
}

// [START receive_message]
- (void)   application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)message
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification

    // Print message ID.
    NSLog(@"Message ID: %@", message[kGCMMessageIDKey]);

    // Pring full message.
    NSLog(@"%@", message);

    NSMutableDictionary *payload = [message mutableCopy];

    //USER NOT TAPPED NOTIFICATION
    if (application.applicationState == UIApplicationStateActive) {
        payload[@"$appState"] = @(0);
        [FirebaseMessagingPlugin.instance raiseEvent:@"pushnotification" withPayload:payload];
        // app is in background or in stand by (NOTIFICATION WILL BE TAPPED)
    } else {
        payload[@"$appState"] = @(1);
        pendingMessage = payload;
    }

    completionHandler(UIBackgroundFetchResultNoData);
}
// [END receive_message]



+ (NSDictionary *)getPendingMessage {
    NSDictionary *message = pendingMessage;
    pendingMessage = nil;
    return message;
}

// [START ios_10_message_handling]
// Receive displayed notifications for iOS 10 devices.
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

// Handle incoming notification messages while app is in the foreground.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    // Print message ID.

    NSMutableDictionary *payload = [notification.request.content.userInfo mutableCopy];
    payload[@"$appState"] = @(0);
    [FirebaseMessagingPlugin.instance raiseEvent:@"pushnotification" withPayload:payload];

    // Change this to your preferred presentation option
    completionHandler(UNNotificationPresentationOptionNone);
}

// Handle notification messages after display notification is tapped by the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)())completionHandler {
    NSMutableDictionary *payload = [response.notification.request.content.userInfo mutableCopy];
    payload[@"$appState"] = @(1);
    pendingMessage = payload;

    completionHandler();
}

- (void)messaging:(nonnull FIRMessaging *)messaging didReceiveMessage:(nonnull FIRMessagingRemoteMessage *)remoteMessage {

    NSMutableDictionary *payload = [remoteMessage.appData mutableCopy];
    payload[@"$appState"] = @(0);
    [FirebaseMessagingPlugin.instance raiseEvent:@"pushnotification" withPayload:payload];
}

- (void)messaging:(nonnull FIRMessaging *)messaging didReceiveRegistrationToken:(nonnull NSString *)fcmToken {
    if (FirebaseMessagingPlugin.instance && fcmToken) {
        [FirebaseMessagingPlugin.instance raiseEvent:@"registrationIdChange" withPayload:@{
                @"registrationId": fcmToken
        }];
    }
}

#endif
// [END ios_10_data_message_handling]

@end
