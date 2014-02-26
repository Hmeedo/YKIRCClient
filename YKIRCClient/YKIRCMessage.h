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
    YKIRCMessageTypeQuit,
    YKIRCMessageTypeMode,
    YKIRCMessageTypeTopic,
};

@interface YKIRCMessage : NSObject

- (id)initWithRawMessage:(NSString *)rawMessage;

@property (nonatomic, copy) NSString *rawMessage;
@property (nonatomic, strong, readonly) NSArray *params;
@property (nonatomic, strong) YKIRCUser *user;
@property (nonatomic, copy) NSString *sender;
@property (nonatomic, copy) NSString *command;
@property (nonatomic, assign) NSUInteger numericCommand;
@property (nonatomic, copy) NSString *trail;
@property (nonatomic, assign) YKIRCMessageType type;

@end
