#import <Foundation/Foundation.h>
#import "YKIRCUser.h"

typedef NS_ENUM(NSUInteger, YKIRCMessageType) {
    YKIRCMessageTypeUnknown,
    YKIRCMessageTypeNumeric,
    YKIRCMessageTypeJoin,
    YKIRCMessageTypePart,
    YKIRCMessageTypePrivMsg,
    YKIRCMessageTypePing,
    YKIRCMessageTypeNotice,
};

@interface YKIRCMessage : NSObject

- (id)initWithMessage:(NSString *)message;

@property (nonatomic, strong, readonly) NSArray *params;
@property (nonatomic, strong) YKIRCUser *user;
@property (nonatomic, copy) NSString *sender;
@property (nonatomic, copy) NSString *command;
@property (nonatomic, copy) NSString *trail;
@property (nonatomic, assign) YKIRCMessageType type;

@end
