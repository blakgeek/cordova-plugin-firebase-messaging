#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

@interface FirebaseMessagingPlugin : CDVPlugin
{
    //NSString *notificationCallBack;
}

+ (FirebaseMessagingPlugin *)instance;
- (void)init:(CDVInvokedUrlCommand*)command;
- (void)getToken:(CDVInvokedUrlCommand*)command;
- (void)subscribe:(CDVInvokedUrlCommand*)command;
- (void)unsubscribe:(CDVInvokedUrlCommand*)command;
- (void)flush:(CDVInvokedUrlCommand*)command;
- (void)raiseEvent:(NSString *)type withPayload:(NSDictionary *)message;
@property (nonatomic) NSString *eventCallbackId;

@end