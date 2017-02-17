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
@import FirebaseInstanceID;
@import FirebaseMessaging;

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
    // Register for remote notifications

    // iOS 7.1 or earlier
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIRemoteNotificationType allNotificationTypes = (UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge);
        [application registerForRemoteNotificationTypes:allNotificationTypes];
#pragma clang diagnostic pop
    } else if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
        UIUserNotificationType allNotificationTypes =
                (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings =
                [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        // iOS 10 or later
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
        UNAuthorizationOptions authOptions =
                UNAuthorizationOptionAlert
                        | UNAuthorizationOptionSound
                        | UNAuthorizationOptionBadge;
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError *_Nullable error) {
        }];

        // For iOS 10 display notification (sent via APNS)
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
        // For iOS 10 data message (sent via FCM)
        [FIRMessaging messaging].remoteMessageDelegate = self;
        [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
    }

    // [START configure_firebase]
    [FIRApp configure];
    // [END configure_firebase]
    // Add observer for InstanceID token refresh callback.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                                 name:kFIRInstanceIDTokenRefreshNotification object:nil];
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
        payload[@"$fcmp:foreground"] = @"1";
        [FirebaseMessagingPlugin.instance raiseEvent:@"pushnotification" withPayload:payload];
        // app is in background or in stand by (NOTIFICATION WILL BE TAPPED)
    } else {
        payload[@"$fcmp:foreground"] = @"0";
        pendingMessage = payload;
    }

    completionHandler(UIBackgroundFetchResultNoData);
}
// [END receive_message]

// [START refresh_token]
- (void)tokenRefreshNotification:(NSNotification *)notification {
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    NSString *registrationId = [[FIRInstanceID instanceID] token];
    if(FirebaseMessagingPlugin.instance) {
        [FirebaseMessagingPlugin.instance raiseEvent:@"registrationIdChange" withPayload:@{
                @"registrationId": registrationId
        }];
    } else {
        NSLog(@"waiting") ;
    }
    [self connectToFcm];
}
// [END refresh_token]

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"app become active");
    [self connectToFcm];
}

// [START connect_to_fcm]
- (void)connectToFcm {
    // Won't connect since there is no token
    if (![[FIRInstanceID instanceID] token]) {
        return;
    }

    // Disconnect previous FCM connection if it exists.
    [[FIRMessaging messaging] disconnect];

    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Unable to connect to FCM. %@", error);
        } else {
            NSLog(@"Connected to FCM.");
        }
    }];
}

// [START disconnect_from_fcm]
- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"app entered background");
    [[FIRMessaging messaging] disconnect];
    NSLog(@"Disconnected from FCM");
}
// [END disconnect_from_fcm]

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

// Receive data message on iOS 10 devices while app is in the foreground.
- (void)applicationReceivedRemoteMessage:(FIRMessagingRemoteMessage *)remoteMessage {

    NSMutableDictionary *payload = [remoteMessage.appData mutableCopy];
    payload[@"$appState"] = @(0);
    [FirebaseMessagingPlugin.instance raiseEvent:@"pushnotification" withPayload:payload];

}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"APNs token retrieved: %@", deviceToken);
}

#endif
// [END ios_10_data_message_handling]

@end
