#import "FlutterLocalNotificationsPlugin.h"
#import "NotificationTime.h"

static bool appResumingFromBackground;

@implementation FlutterLocalNotificationsPlugin

FlutterMethodChannel* channel;
NSString *const INITIALIZE_METHOD = @"initialize";
NSString *const SHOW_METHOD = @"show";
NSString *const SCHEDULE_METHOD = @"schedule";
NSString *const PERIODICALLY_SHOW_METHOD = @"periodicallyShow";
NSString *const SCHEDULE_DAILY = @"scheduleDaily";
NSString *const CANCEL_METHOD = @"cancel";
NSString *const CANCEL_ALL_METHOD = @"cancelAll";
NSString *const CHANNEL = @"dexterous.com/flutter/local_notifications";

NSString *const REQUEST_SOUND_PERMISSION = @"requestSoundPermission";
NSString *const REQUEST_ALERT_PERMISSION = @"requestAlertPermission";
NSString *const REQUEST_BADGE_PERMISSION = @"requestBadgePermission";
NSString *const DEFAULT_PRESENT_ALERT = @"defaultPresentAlert";
NSString *const DEFAULT_PRESENT_SOUND = @"defaultPresentSound";
NSString *const DEFAULT_PRESENT_BADGE = @"defaultPresentBadge";
NSString *const PLATFORM_SPECIFICS = @"platformSpecifics";
NSString *const ID = @"id";
NSString *const TITLE = @"title";
NSString *const BODY = @"body";
NSString *const SOUND = @"sound";
NSString *const PRESENT_ALERT = @"presentAlert";
NSString *const PRESENT_SOUND = @"presentSound";
NSString *const PRESENT_BADGE = @"presentBadge";
NSString *const MILLISECONDS_SINCE_EPOCH = @"millisecondsSinceEpoch";
NSString *const REPEAT_INTERVAL = @"repeatInterval";
NSString *const REPEAT_TIME = @"repeatTime";
NSString *const HOUR = @"hour";
NSString *const MINUTE = @"minute";
NSString *const SECOND = @"second";
NSString *const DAYS = @"days";
const int EVERY_MINUTE = 60;
const int HOURLY = 60 * 60;
const int DAILY = 60 * 60 * 24;
const int WEEKLY = 60 * 60 * 24 * 7;

const int SUNDAY = 1;
const int MONDAY = 2;
const int TUESDAY = 4;
const int WEDNESDAY = 8;
const int THURSDAY = 16;
const int FRIDAY = 32;
const int SATURDAY = 64;

NSString *const NOTIFICATION_ID = @"NotificationId";
NSString *const PAYLOAD = @"payload";
NSString *launchPayload;
bool displayAlert;
bool playSound;
bool updateBadge;
bool initialized;
+ (bool) resumingFromBackground { return appResumingFromBackground; }
UILocalNotification *launchNotification;

typedef NS_ENUM(NSInteger, RepeatInterval) {
    EveryMinute,
    Hourly,
    Daily,
    Weekly
};

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    channel = [FlutterMethodChannel
               methodChannelWithName:CHANNEL
               binaryMessenger:[registrar messenger]];
    FlutterLocalNotificationsPlugin* instance = [[FlutterLocalNotificationsPlugin alloc] init];
    if(@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = instance;
    }
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)initialize:(FlutterMethodCall * _Nonnull)call result:(FlutterResult _Nonnull)result {
    appResumingFromBackground = false;
    NSDictionary *arguments = [call arguments];
    if(arguments[DEFAULT_PRESENT_ALERT] != [NSNull null]) {
        displayAlert = [[arguments objectForKey:DEFAULT_PRESENT_ALERT] boolValue];
    }
    if(arguments[DEFAULT_PRESENT_SOUND] != [NSNull null]) {
        playSound = [[arguments objectForKey:DEFAULT_PRESENT_SOUND] boolValue];
    }
    if(arguments[DEFAULT_PRESENT_BADGE] != [NSNull null]) {
        updateBadge = [[arguments objectForKey:DEFAULT_PRESENT_BADGE] boolValue];
    }
    bool requestedSoundPermission = false;
    bool requestedAlertPermission = false;
    bool requestedBadgePermission = false;
    if (arguments[REQUEST_SOUND_PERMISSION] != [NSNull null]) {
        requestedSoundPermission = [arguments[REQUEST_SOUND_PERMISSION] boolValue];
    }
    if (arguments[REQUEST_ALERT_PERMISSION] != [NSNull null]) {
        requestedAlertPermission = [arguments[REQUEST_ALERT_PERMISSION] boolValue];
    }
    if (arguments[REQUEST_BADGE_PERMISSION] != [NSNull null]) {
        requestedBadgePermission = [arguments[REQUEST_BADGE_PERMISSION] boolValue];
    }
    if(@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        UNAuthorizationOptions authorizationOptions = 0;
        if (requestedSoundPermission) {
            authorizationOptions += UNAuthorizationOptionSound;
        }
        if (requestedAlertPermission) {
            authorizationOptions += UNAuthorizationOptionAlert;
        }
        if (requestedBadgePermission) {
            authorizationOptions += UNAuthorizationOptionBadge;
        }
        [center requestAuthorizationWithOptions:(authorizationOptions) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if(launchPayload != nil) {
                [FlutterLocalNotificationsPlugin handleSelectNotification:launchPayload];
            }
            result(@(granted));
        }];
    } else {
        UIUserNotificationType notificationTypes = 0;
        if (requestedSoundPermission) {
            notificationTypes |= UIUserNotificationTypeSound;
        }
        if (requestedAlertPermission) {
            notificationTypes |= UIUserNotificationTypeAlert;
        }
        if (requestedBadgePermission) {
            notificationTypes |= UIUserNotificationTypeBadge;
        }
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        if(launchNotification != nil) {
            NSString *payload = launchNotification.userInfo[PAYLOAD];
            [channel invokeMethod:@"selectNotification" arguments:payload];
        }
        result(@true);
    }
    initialized = true;
}

- (void)showNotification:(FlutterMethodCall * _Nonnull)call result:(FlutterResult _Nonnull)result {
    NSNumber *id = call.arguments[ID];
    NSString *title = call.arguments[TITLE];
    NSString *body = call.arguments[BODY];
    NSString *payload = call.arguments[PAYLOAD];
    bool presentAlert = displayAlert;
    bool presentSound = playSound;
    bool presentBadge = updateBadge;
    NSString *sound;
    if(call.arguments[PLATFORM_SPECIFICS] != [NSNull null]) {
        NSDictionary *platformSpecifics = call.arguments[PLATFORM_SPECIFICS];
        
        if(platformSpecifics[PRESENT_ALERT] != [NSNull null]) {
            presentAlert = [[platformSpecifics objectForKey:PRESENT_ALERT] boolValue];
        }
        if(platformSpecifics[PRESENT_SOUND] != [NSNull null]) {
            presentSound = [[platformSpecifics objectForKey:PRESENT_SOUND] boolValue];
        }
        if(platformSpecifics[PRESENT_BADGE] != [NSNull null]) {
            presentBadge = [[platformSpecifics objectForKey:PRESENT_BADGE] boolValue];
        }
        sound = platformSpecifics[SOUND];
    }
    NSNumber *secondsSinceEpoch;
    NSNumber *repeatInterval;
    NotificationTime *repeatTime;
    if([SCHEDULE_METHOD isEqualToString:call.method]) {
        secondsSinceEpoch = @([call.arguments[MILLISECONDS_SINCE_EPOCH] integerValue] / 1000);
    } else if([PERIODICALLY_SHOW_METHOD isEqualToString:call.method]) {
        repeatInterval = @([call.arguments[REPEAT_INTERVAL] integerValue]);
    } else if ([SCHEDULE_DAILY isEqualToString:call.method]) {
        NSDictionary *timeArguments = (NSDictionary *) call.arguments[REPEAT_TIME];
        repeatTime = [[NotificationTime alloc] init];
        if (timeArguments[HOUR] != [NSNull null]) {
            repeatTime.hour = @([timeArguments[HOUR] integerValue]);
        }
        if (timeArguments[MINUTE] != [NSNull null]) {
            repeatTime.minute = @([timeArguments[MINUTE] integerValue]);
        }
        if (timeArguments[SECOND] != [NSNull null]) {
            repeatTime.second = @([timeArguments[SECOND] integerValue]);
        }
        if (timeArguments[DAYS] != [NSNull null]) {
            repeatTime.days = @([timeArguments[DAYS] integerValue]);
        }
    }
    if(@available(iOS 10.0, *)) {
        if (repeatTime != nil) {
            [self showDailyUserNotification:id title:title body:body secondsSinceEpoch:secondsSinceEpoch repeatTime:repeatTime presentAlert:presentAlert  presentSound:presentSound presentBadge:presentBadge sound:sound payload:payload];
        } else {
            [self showUserNotification:id title:title body:body secondsSinceEpoch:secondsSinceEpoch repeatInterval:repeatInterval presentAlert:presentAlert  presentSound:presentSound presentBadge:presentBadge sound:sound payload:payload];
        }
    } else {
        if (repeatTime != nil) {
            [self showDailyLocalNotification:id title:title body:body secondsSinceEpoch:secondsSinceEpoch repeatTime:repeatTime presentAlert:presentAlert  presentSound:presentSound presentBadge:presentBadge sound:sound payload:payload];
        } else {
            [self showLocalNotification:id title:title body:body secondsSinceEpoch:secondsSinceEpoch repeatInterval:repeatInterval presentAlert:presentAlert  presentSound:presentSound presentBadge:presentBadge sound:sound payload:payload];
        }
    }
    result(nil);
}

- (void)cancelNotification:(FlutterMethodCall * _Nonnull)call result:(FlutterResult _Nonnull)result {
    NSNumber* id = (NSNumber*)call.arguments;
    if(@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center =  [UNUserNotificationCenter currentNotificationCenter];
        NSArray *idsToRemove = [[NSArray alloc] initWithObjects:[id stringValue], nil];
        [center removePendingNotificationRequestsWithIdentifiers:idsToRemove];
        [center removeDeliveredNotificationsWithIdentifiers:idsToRemove];
    } else {
        NSArray *notifications = [UIApplication sharedApplication].scheduledLocalNotifications;
        for( int i = 0; i < [notifications count]; i++) {
            UILocalNotification* localNotification = [notifications objectAtIndex:i];
            NSNumber *userInfoNotificationId = localNotification.userInfo[NOTIFICATION_ID];
            if([userInfoNotificationId longValue] == [id longValue]) {
                [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
                break;
            }
        }
    }
    result(nil);
}

- (void)cancelAllNotifications:(FlutterResult _Nonnull) result {
    if(@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center =  [UNUserNotificationCenter currentNotificationCenter];
        [center removeAllPendingNotificationRequests];
        [center removeAllDeliveredNotifications];
    } else {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
    result(nil);
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([INITIALIZE_METHOD isEqualToString:call.method]) {
        [self initialize:call result:result];
        
    } else if ([SHOW_METHOD isEqualToString:call.method] || [SCHEDULE_METHOD isEqualToString:call.method] || [PERIODICALLY_SHOW_METHOD isEqualToString:call.method] || [SCHEDULE_DAILY isEqualToString:call.method]) {
        [self showNotification:call result:result];
    } else if([CANCEL_METHOD isEqualToString:call.method]) {
        [self cancelNotification:call result:result];
    } else if([CANCEL_ALL_METHOD isEqualToString:call.method]) {
        [self cancelAllNotifications:result];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (void) showUserNotification:(NSNumber *)id title:(NSString *)title body:(NSString *)body secondsSinceEpoch:(NSNumber *)secondsSinceEpoch repeatInterval:(NSNumber *)repeatInterval presentAlert:(bool)presentAlert presentSound:(bool)presentSound presentBadge:(bool)presentBadge sound:(NSString*)sound payload:(NSString *)payload NS_AVAILABLE_IOS(10.0) {
    UNNotificationTrigger *trigger;
    UNMutableNotificationContent* content = [self buildNotificationContent:id title:title body:body presentAlert:presentAlert presentSound:presentSound sound:sound presentBadge:presentBadge payload:payload];
    if(secondsSinceEpoch == nil) {
        NSTimeInterval timeInterval = 0.1;
        Boolean repeats = NO;
        if(repeatInterval != nil) {
            switch([repeatInterval integerValue]) {
                case EveryMinute:
                    timeInterval = EVERY_MINUTE;
                    break;
                case Hourly:
                    timeInterval = HOURLY;
                    break;
                case Daily:
                    timeInterval = DAILY;
                    break;
                case Weekly:
                    timeInterval = WEEKLY;
                    break;
            }
            repeats = YES;
        }
        trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:timeInterval
            repeats:repeats];                                                      
    } else {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[secondsSinceEpoch integerValue]];
        NSCalendar *currentCalendar = [NSCalendar currentCalendar];
        NSDateComponents *dateComponents    = [currentCalendar components:(NSCalendarUnitYear  |
                                                                           NSCalendarUnitMonth |
                                                                           NSCalendarUnitDay   |
                                                                           NSCalendarUnitHour  |
                                                                           NSCalendarUnitMinute|
                                                                           NSCalendarUnitSecond) fromDate:date];
        trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:false];
    }
    UNNotificationRequest* notificationRequest = [UNNotificationRequest
                                                  requestWithIdentifier:[id stringValue] content:content trigger:trigger];
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:notificationRequest withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Unable to Add Notification Request");
        }
    }];
    
}

- (void) showDailyUserNotification:(NSNumber *)id title:(NSString *)title body:(NSString *)body secondsSinceEpoch:(NSNumber *)secondsSinceEpoch repeatTime:(NotificationTime *)repeatTime presentAlert:(bool)presentAlert presentSound:(bool)presentSound presentBadge:(bool)presentBadge sound:(NSString*)sound payload:(NSString *)payload NS_AVAILABLE_IOS(10.0) {
    UNMutableNotificationContent* content = [self buildNotificationContent:id title:title body:body presentAlert:presentAlert presentSound:presentSound sound:sound presentBadge:presentBadge payload:payload];
    long days = [repeatTime.days integerValue];
    int baseNotificationId = [id intValue];
    if (days & SUNDAY) {
        baseNotificationId = [self queueDailyUserNotification:baseNotificationId content:content repeatTime:repeatTime weekday: 1];
    }
    if (days & MONDAY) {
        baseNotificationId = [self queueDailyUserNotification:baseNotificationId content:content repeatTime:repeatTime weekday: 2];
    }
    if (days & TUESDAY) {
        baseNotificationId = [self queueDailyUserNotification:baseNotificationId content:content repeatTime:repeatTime weekday: 3];
    }
    if (days & WEDNESDAY) {
        baseNotificationId = [self queueDailyUserNotification:baseNotificationId content:content repeatTime:repeatTime weekday: 4];
    }
    if (days & THURSDAY) {
        baseNotificationId = [self queueDailyUserNotification:baseNotificationId content:content repeatTime:repeatTime weekday: 5];
    }
    if (days & FRIDAY) {
        baseNotificationId = [self queueDailyUserNotification:baseNotificationId content:content repeatTime:repeatTime weekday: 6];
    }
    if (days & SATURDAY) {
        [self queueDailyUserNotification:baseNotificationId content:content repeatTime:repeatTime weekday: 7];
    }
}

- (int) queueDailyUserNotification:(int)baseNotificationId content:(UNMutableNotificationContent *)content repeatTime:(NotificationTime *)repeatTime weekday:(int)weekday {
    NSNumber *notificationId = [NSNumber numberWithInt:baseNotificationId];
    NSDateComponents *dayDateComponent = [self createDateComponentForWeekday:repeatTime weekday:weekday];
    UNNotificationTrigger *dayTrigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dayDateComponent repeats: YES];
    id dayId = [NSNumber numberWithInteger: notificationId];
    UNNotificationRequest* notificationRequest = [UNNotificationRequest
                                                  requestWithIdentifier:notificationId content:content trigger:dayTrigger];
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:notificationRequest withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Unable to Add Notification Request");
        }
    }];
    return [notificationId intValue] + 1;
}

- (NSDateComponents *) createDateComponentForWeekday:(NotificationTime *)repeatTime weekday:(int) weekday {
    NSDateComponents *dateComponent = [[NSDateComponents alloc] init];
    [dateComponent setHour:[repeatTime.hour integerValue]];
    [dateComponent setMinute:[repeatTime.minute integerValue]];
    [dateComponent setSecond:[repeatTime.second integerValue]];
    [dateComponent setWeekday: weekday];
    return dateComponent;
}

- (NSDictionary*)buildUserDict:(NSNumber *)id title:(NSString *)title presentAlert:(bool)presentAlert presentSound:(bool)presentSound presentBadge:(bool)presentBadge payload:(NSString *)payload {
    NSDictionary *userDict =[NSDictionary dictionaryWithObjectsAndKeys:id, NOTIFICATION_ID, title, TITLE, [NSNumber numberWithBool:presentAlert], PRESENT_ALERT, [NSNumber numberWithBool:presentSound], PRESENT_SOUND, [NSNumber numberWithBool:presentBadge], PRESENT_BADGE, payload, PAYLOAD, nil];
    return userDict;
}

- (UNMutableNotificationContent *) buildNotificationContent:(NSNumber *)id title:(NSString *)title body:(NSString *)body presentAlert:(bool)presentAlert presentSound:(bool)presentSound sound:(NSString*)sound presentBadge:(bool)presentBadge payload:(NSString *)payload {
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = body;
    if(presentSound) {
        if(!sound || [sound isKindOfClass:[NSNull class]]) {
            content.sound = UNNotificationSound.defaultSound;
        } else {
            content.sound = [UNNotificationSound soundNamed:sound];
        }
    }
    content.userInfo = [self buildUserDict:id title:title presentAlert:presentAlert presentSound:presentSound presentBadge:presentBadge payload:payload];
    return content;
}

- (UILocalNotification *) buildUILocalNotification:(NSNumber *)id title:(NSString *)title body:(NSString *)body presentAlert:(bool)presentAlert presentSound:(bool)presentSound presentBadge:(bool)presentBadge sound:(NSString*)sound payload:(NSString *)payload {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = body;
    if(@available(iOS 8.2, *)) {
        notification.alertTitle = title;
    }
    if(presentSound) {
        if(!sound || [sound isKindOfClass:[NSNull class]]){
            notification.soundName = UILocalNotificationDefaultSoundName;
        } else {
            notification.soundName = sound;
        }
    }
    notification.userInfo = [self buildUserDict:id title:title presentAlert:presentAlert presentSound:presentSound presentBadge:presentBadge payload:payload];
    return notification;
}

- (void) showLocalNotification:(NSNumber *)id title:(NSString *)title body:(NSString *)body secondsSinceEpoch:(NSNumber *)secondsSinceEpoch repeatInterval:(NSNumber *)repeatInterval presentAlert:(bool)presentAlert presentSound:(bool)presentSound presentBadge:(bool)presentBadge sound:(NSString*)sound payload:(NSString *)payload {
    UILocalNotification *notification = [self buildUILocalNotification:id title:title body:body presentAlert:presentAlert presentSound:presentSound presentBadge:presentBadge sound:sound payload:payload];
    if(secondsSinceEpoch == nil) {
        if(repeatInterval != nil) {
            NSTimeInterval timeInterval = 0;
            switch([repeatInterval integerValue]) {
                case EveryMinute:
                    timeInterval = EVERY_MINUTE;
                    notification.repeatInterval = NSCalendarUnitMinute;
                    break;
                case Hourly:
                    timeInterval = HOURLY;
                    notification.repeatInterval = NSCalendarUnitHour;
                    break;
                case Daily:
                    timeInterval = DAILY;
                    notification.repeatInterval = NSCalendarUnitDay;
                    break;
                case Weekly:
                    timeInterval = WEEKLY;
                    notification.repeatInterval = NSCalendarUnitWeekOfYear;
                    break;
            }
            notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:timeInterval];
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            return;
        }
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    } else {
        notification.fireDate = [NSDate dateWithTimeIntervalSince1970:[secondsSinceEpoch integerValue]];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

- (void) showDailyLocalNotification:(NSNumber *)id title:(NSString *)title body:(NSString *)body secondsSinceEpoch:(NSNumber *)secondsSinceEpoch repeatTime:(NotificationTime *)repeatTime presentAlert:(bool)presentAlert presentSound:(bool)presentSound presentBadge:(bool)presentBadge sound:(NSString*)sound payload:(NSString *)payload {
    UILocalNotification *notification = [self buildUILocalNotification:id title:title body:body presentAlert:presentAlert presentSound:presentSound presentBadge:presentBadge sound:sound payload:payload];
    notification.repeatInterval = NSCalendarUnitWeekOfYear;
    int days = [repeatTime.days integerValue];
    if (days & SUNDAY) {
        notification.fireDate = [self createFireDateForWeekday:repeatTime weekday:1];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    if (days & MONDAY) {
        notification.fireDate = [self createFireDateForWeekday:repeatTime weekday:2];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    if (days & TUESDAY) {
        notification.fireDate = [self createFireDateForWeekday:repeatTime weekday:3];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    if (days & WEDNESDAY) {
        notification.fireDate = [self createFireDateForWeekday:repeatTime weekday:4];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    if (days & THURSDAY) {
        notification.fireDate = [self createFireDateForWeekday:repeatTime weekday:5];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    if (days & FRIDAY) {
        notification.fireDate = [self createFireDateForWeekday:repeatTime weekday:6];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    if (days & SATURDAY) {
        notification.fireDate = [self createFireDateForWeekday:repeatTime weekday:7];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

- (NSDate *) createFireDateForWeekday:(NotificationTime *)repeatTime weekday:(int)weekday {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    [components setHour:[repeatTime.hour integerValue]];
    [components setMinute:[repeatTime.minute integerValue]];
    [components setSecond:[repeatTime.second integerValue]];
    [components setWeekday: weekday];
    return [calendar dateFromComponents:components];
}


- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification :(UNNotification *)notification withCompletionHandler :(void (^)(UNNotificationPresentationOptions))completionHandler NS_AVAILABLE_IOS(10.0) {
    UNNotificationPresentationOptions presentationOptions = 0;
    NSNumber *presentAlertValue = (NSNumber*)notification.request.content.userInfo[PRESENT_ALERT];
    NSNumber *presentSoundValue = (NSNumber*)notification.request.content.userInfo[PRESENT_SOUND];
    NSNumber *presentBadgeValue = (NSNumber*)notification.request.content.userInfo[PRESENT_BADGE];
    bool presentAlert = [presentAlertValue boolValue];
    bool presentSound = [presentSoundValue boolValue];
    bool presentBadge = [presentBadgeValue boolValue];
    if(presentAlert) {
        presentationOptions |= UNNotificationPresentationOptionAlert;
    }
    if(presentSound){
        presentationOptions |= UNNotificationPresentationOptionSound;
    }
    if(presentBadge) {
        presentationOptions |= UNNotificationPresentationOptionBadge;
    }
    completionHandler(presentationOptions);
}

+ (void)handleSelectNotification:(NSString *)payload {
    [channel invokeMethod:@"selectNotification" arguments:payload];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler NS_AVAILABLE_IOS(10.0) {
    if ([response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]) {
        
        NSString *payload = (NSString *) response.notification.request.content.userInfo[PAYLOAD];
        if(initialized) {
            [FlutterLocalNotificationsPlugin handleSelectNotification:payload];
        } else {
            launchPayload = payload;
        }
        
    }
}
- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (launchOptions != nil) {
        launchNotification = (UILocalNotification *)[launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    }
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    appResumingFromBackground = true;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    appResumingFromBackground = false;
}

@end
