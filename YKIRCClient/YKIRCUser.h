#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, YKIRCUserMode) {
    YKIRCUserModeDefault,
    YKIRCUserMode_a,
    YKIRCUserMode_i,
    YKIRCUserMode_w,
    YKIRCUserMode_r,
    YKIRCUserMode_o,
    YKIRCUserMode_O,
    YKIRCUserMode_s,
};

@interface YKIRCUser : NSObject

@property (nonatomic, copy) NSString *nick;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *server;
@property (nonatomic, copy) NSString *realName;
@property (nonatomic, assign) YKIRCUserMode mode;

@end
