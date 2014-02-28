#import "YKIRCMessage.h"

#define kYKIRCMessagePartsPrefix  0
#define kYKIRCMessagePartsCommand 1
#define kYKIRCMessagePartsParams  2
#define kYKIRCMessagePartsTrail   3

#define PRIVMSG @"PRIVMSG"
#define NOTICE @"NOTICE"
#define JOIN @"JOIN"
#define PART @"PART"
#define PING @"PING"
#define QUIT @"QUIT"
#define MODE @"MODE"
#define TOPIC @"TOPIC"

@interface YKIRCMessage ()

@property (nonatomic, strong) NSMutableArray *parts;

@end

@implementation YKIRCMessage

+ (NSRegularExpression *)messageRe
{
    static NSRegularExpression *_messageRe;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        NSString *pattern = @"^(?::(\\S+) )?(\\S+)(?: (?!:)(.+?))?(?: :(.+))?$";
        _messageRe = [NSRegularExpression regularExpressionWithPattern:pattern
                                                        options:NSRegularExpressionCaseInsensitive
                                                          error:&error];

    });
    return _messageRe;
}

+ (NSRegularExpression *)userRe
{
    static NSRegularExpression *_userRe;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        NSString *pattern = @"^(?:(.+)!~?(.+)?@(\\S+))$";
        _userRe = [NSRegularExpression regularExpressionWithPattern:pattern
                                                               options:NSRegularExpressionCaseInsensitive
                                                                 error:&error];
        
    });
    return _userRe;
}

- (id)initWithRawMessage:(NSString *)rawMessage
{
    self = [super init];
    if (self) {
        _rawMessage = rawMessage;
        _parts = @[].mutableCopy;
        _numericCommand = NSNotFound;
        if (rawMessage.length)
            [self parseMessage];
    }
    return self;
}

- (void)parseMessage
{
    NSArray *matches = [[[self class] messageRe] matchesInString:_rawMessage
                                                         options:NSMatchingReportProgress
                                                           range:NSMakeRange(0, _rawMessage.length)];
    if (!matches.count) return;
    
    NSTextCheckingResult *result = matches[0];
    for (int i = 1; i < [result numberOfRanges]; i++) {
        NSRange r = [result rangeAtIndex:i];
        if (r.location == NSNotFound) {
            [_parts addObject:[NSNull null]];
        } else {
            [_parts addObject:[_rawMessage substringWithRange:r]];
        }
    }
    
    [self parsePrefix];
    
    _command = [_parts objectAtIndex:kYKIRCMessagePartsCommand];
    NSCharacterSet *stringCharacterSet = [NSCharacterSet characterSetWithCharactersInString:_command];
    NSCharacterSet *digitCharacterSet = [NSCharacterSet decimalDigitCharacterSet];
    if ([digitCharacterSet isSupersetOfSet:stringCharacterSet]) {
        _numericCommand = [_command integerValue];
    }

    NSString *params = [_parts objectAtIndex:kYKIRCMessagePartsParams];
    if (![params isEqual:[NSNull null]])
        _params = [params componentsSeparatedByString:@" "];
    
    if (_parts.count > kYKIRCMessagePartsTrail)
        _trail = [_parts objectAtIndex:kYKIRCMessagePartsTrail];
}

- (void)parsePrefix
{
    NSString *prefix = [_parts objectAtIndex:kYKIRCMessagePartsPrefix];
    if ([prefix isEqual:[NSNull null]]) return;
    
    NSRange range = [prefix rangeOfString:@"!"];
    if (range.location != NSNotFound) {
        NSArray *matches = [[[self class] userRe] matchesInString:prefix
                                                          options:NSMatchingReportProgress
                                                            range:NSMakeRange(0, prefix.length)];
        NSTextCheckingResult *result = matches[0];
        NSMutableArray *matchStrings = @[].mutableCopy;
        for (int i = 1; i < [result numberOfRanges]; i++) {
            NSRange r = [result rangeAtIndex:i];
            if (r.location != NSNotFound) {
                [matchStrings addObject:[prefix substringWithRange:r]];
            }
        }
        _user = [YKIRCUser new];
        _user.nick = matchStrings[0];
        _user.name = matchStrings[1];
        _user.server = matchStrings[2];
    } else {
        _sender = prefix;
    }
}

- (YKIRCMessageType)type
{
    if ([_command isEqualToString:PRIVMSG]) return YKIRCMessageTypePrivMsg;
    else if ([_command isEqualToString:NOTICE]) return YKIRCMessageTypeNotice;
    else if ([_command isEqualToString:JOIN]) return YKIRCMessageTypeJoin;
    else if ([_command isEqualToString:PART]) return YKIRCMessageTypePart;
    else if ([_command isEqualToString:PING]) return YKIRCMessageTypePing;
    else if ([_command isEqualToString:QUIT]) return YKIRCMessageTypeQuit;
    else if ([_command isEqualToString:MODE]) return YKIRCMessageTypeMode;
    else if ([_command isEqualToString:TOPIC]) return YKIRCMessageTypeTopic;
    else {
        if (_numericCommand != NSNotFound) {
            return YKIRCMessageTypeNumeric;
        } else {
            return YKIRCMessageTypeUnknown;
        }
    }
}

@end
