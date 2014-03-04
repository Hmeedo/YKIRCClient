#import "YKIRCUser.h"

@implementation YKIRCUser

- (id)init
{
    self = [super init];
    if (self) {
        _mode = YKIRCUserModeDefault;
    }
    return self;
}

@end
