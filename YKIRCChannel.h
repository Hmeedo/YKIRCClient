#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, YKIRCChannelMode) {
    YKIRCChannelModeSecret,
    YKIRCChannelModePrivate,
    YKIRCChannelModeOther,
};

@interface YKIRCChannel : NSObject

@property (nonatomic, readonly) YKIRCChannelMode mode;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSMutableArray *users;

- (id)initWithName:(NSString *)name modeString:(NSString *)modeString;
- (void)addUser:(NSString *)nick;

@end
