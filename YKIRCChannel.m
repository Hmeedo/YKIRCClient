#import "YKIRCChannel.h"
#import "YKIRCUser.h"

@implementation YKIRCChannel

- (id)initWithName:(NSString *)name modeString:(NSString *)modeString
{
    self = [super init];
    if (self) {
        _name = name;
        _users = @[].mutableCopy;
        [self setModeWithString:modeString];
    }
    return self;
}

- (void)setModeWithString:(NSString *)modeString
{
    if ([modeString isEqualToString:@"@"]) {
        _mode = YKIRCChannelModeSecret;
    } else if ([modeString isEqualToString:@"*"]) {
        _mode = YKIRCChannelModePrivate;
    } else if ([modeString isEqualToString:@"="]) {
        _mode = YKIRCChannelModeOther;
    }
}

- (NSUInteger)indexOfUserWithNick:(NSString *)nick
{
    int i = 0;
    for (YKIRCUser *user in _users) {
        if ([user.nick isEqualToString:nick]) {
            return i;
        }
    }
    return NSNotFound;
}

- (void)addUser:(NSString *)nick
{
    YKIRCUser *user = [YKIRCUser new];
    if ([nick hasPrefix:@"@"] || [nick hasPrefix:@"+"]) {
        user.nick = [nick substringFromIndex:1];
        user.mode = YKIRCUserMode_o;
    } else {
        user.nick = nick;
    }
    NSUInteger index = [self indexOfUserWithNick:user.nick];
    if (index == NSNotFound) {
        [_users addObject:user];
    }
}

@end
