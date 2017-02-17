//
//  AppDelegate+FirebaseMessagingPlugin.h
//  TestApp
//
//  Created by felipe on 12/06/16.
//
//

#import "AppDelegate.h"
#import <UIKit/UIKit.h>
#import <Cordova/CDVViewController.h>

@interface AppDelegate (FirebaseMessagingPlugin)

+ (NSDictionary*)getPendingMessage;

@end
