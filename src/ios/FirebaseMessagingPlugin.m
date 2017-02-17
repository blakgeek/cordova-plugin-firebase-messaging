#include <sys/types.h>
#include <sys/sysctl.h>

#import "AppDelegate+FirebaseMessagingPlugin.h"

#import <Cordova/CDV.h>
#import "FirebaseMessagingPlugin.h"
#import "Firebase.h"

@interface FirebaseMessagingPlugin () {}
@end

@implementation FirebaseMessagingPlugin

static FirebaseMessagingPlugin *fcmPluginInstance;

+ (FirebaseMessagingPlugin *) instance {

    return fcmPluginInstance;
}

- (void)init:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Cordova view ready");
    fcmPluginInstance = self;

    self.eventCallbackId = command.callbackId;

}

// GET TOKEN //
- (void) getToken:(CDVInvokedUrlCommand *)command
{
    NSLog(@"get Token");
    [self.commandDelegate runInBackground:^{
        NSString* token = [[FIRInstanceID instanceID] token];
        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:token];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

// UN/SUBSCRIBE TOPIC //
- (void)subscribe:(CDVInvokedUrlCommand *)command
{
    NSString* topic = command.arguments[0];
    NSLog(@"subscribe To Topic %@", topic);
    [self.commandDelegate runInBackground:^{
        if(topic != nil)[[FIRMessaging messaging] subscribeToTopic:[NSString stringWithFormat:@"/topics/%@", topic]];
        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:topic];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)unsubscribe:(CDVInvokedUrlCommand *)command
{
    NSString* topic = command.arguments[0];
    NSLog(@"unsubscribe From Topic %@", topic);
    [self.commandDelegate runInBackground:^{
        if(topic != nil)[[FIRMessaging messaging] unsubscribeFromTopic:[NSString stringWithFormat:@"/topics/%@", topic]];
        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:topic];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}


- (void)flush:(CDVInvokedUrlCommand *)command {

    NSDictionary* pendingMessage = [AppDelegate getPendingMessage];
    if (pendingMessage != nil) {
        [self raiseEvent:@"pushnotification" withPayload: pendingMessage];
    }
}

-(void)raiseEvent:(NSString*) type withPayload: (NSDictionary *)message
{
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: @{
            @"type": type,
            @"data": message
    }];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.eventCallbackId];
}

@end
