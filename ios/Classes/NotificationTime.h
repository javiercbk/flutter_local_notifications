#import <Foundation/Foundation.h>

@interface NotificationTime : NSObject
    @property(nonatomic, strong) NSNumber *hour;
    @property(nonatomic, strong) NSNumber *minute;
    @property(nonatomic, strong) NSNumber *second;
    @property(nonatomic, strong) NSNumber *days;
@end