#import "YKIRCClient.h"

static NSTimeInterval const kYKIRCClientDefaultTimeout = 60;

@interface YKIRCClient ()

@property (nonatomic, strong) NSMutableArray *channels;

@end

@implementation YKIRCClient

- (id)init
{
    self = [super init];
    if (self) {
        _sock = [[AsyncSocket alloc] initWithDelegate:self];
        _channels = @[].mutableCopy;
    }
    return self;
}

#pragma mark - Public methods

- (void)connect
{
    [_sock connectToHost:_host onPort:_port error:nil];
}

- (void)joinToChannel:(NSString *)channel
{
    if (_sock.isConnected) {
        [self sendRawString:[NSString stringWithFormat:@"JOIN %@", channel]
                        tag:YKIRCClientMessageTypeJoin];
    } else {
        YKIRCLog(@"No connect yet.");
    }
}

- (void)partFromChannel:(NSString *)channel
{
    if (_sock.isConnected) {
        [self sendRawString:[NSString stringWithFormat:@"PART %@", channel]
                        tag:0];
    } else {
        YKIRCLog(@"No connect yet.");
    }
}

- (void)sendRawString:(NSString *)string tag:(long)tag
{
    YKIRCLog(@">>> %@", string);
    NSString *rawString = [NSString stringWithFormat:@"%@\r\n", string];
    NSData *data = [rawString dataUsingEncoding:NSUTF8StringEncoding];
    [_sock writeData:data withTimeout:kYKIRCClientDefaultTimeout tag:tag];
}

- (void)sendMessage:(NSString *)message recipient:(NSString *)recipient
{
    NSString *msg = [NSString stringWithFormat:@"PRIVMSG %@ %@", recipient, message];
    [self sendRawString:msg tag:YKIRCClientMessageTypePrivMsg];
}

#pragma mark - Private methods

+ (NSRegularExpression *)regularExpressionWithPattern:(NSString *)pattern
{
    return [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
}

+ (NSDictionary *)regexs
{
    static NSDictionary *_regexs = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _regexs = @{
                   @"ping": [self regularExpressionWithPattern:@"^ping"],
                   @"privmsg": [self regularExpressionWithPattern:@"^:.* PRIVMSG (.*)$"],
                   @"notice": [self regularExpressionWithPattern:@"^:.* NOTICE (.*)$"],
                   @"join": [self regularExpressionWithPattern:@"^:(.*)!~(.*)@(.*) JOIN :(.*)$"],
                   @"part": [self regularExpressionWithPattern:@"^:(.*)!~(.*)@(.*) PART (.*) :(.*)$"],
                   };
    });
    return _regexs;
}

+ (BOOL)isMatchInString:(NSString *)string regexName:(NSString *)regexName
{
    NSRegularExpression *re = [[self regexs] objectForKey:regexName];
    return ([re numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)] > 0);
}

+ (NSArray *)matchesInString:(NSString *)string regexName:(NSString *)regexName
{
    NSRegularExpression *re = [[self regexs] objectForKey:regexName];
    NSArray *matches = [re matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    NSTextCheckingResult *result = matches[0];
    NSMutableArray *matchStrings = @[].mutableCopy;
    for (int i = 1; i < [result numberOfRanges]; i++) {
        NSRange r = [result rangeAtIndex:i];
        [matchStrings addObject:[string substringWithRange:r]];
    }
    return matchStrings;
}

- (YKIRCClientMessageType)getMessageTypeWithReceivedMessage:(NSString *)receivedMessage
{
    if ([YKIRCClient isMatchInString:receivedMessage regexName:@"ping"]) {
        return YKIRCClientMessageTypePing;
    } else if ([YKIRCClient isMatchInString:receivedMessage regexName:@"privmsg"]) {
        return YKIRCClientMessageTypePrivMsg;
    } else if ([YKIRCClient isMatchInString:receivedMessage regexName:@"notice"]) {
        return YKIRCClientMessageTypeNotice;
    } else if ([YKIRCClient isMatchInString:receivedMessage regexName:@"join"]) {
        return YKIRCClientMessageTypeJoin;
    } else if ([YKIRCClient isMatchInString:receivedMessage regexName:@"part"]) {
        return YKIRCClientMessageTypePart;
    }
    return YKIRCClientMessageTypeUnknown;
}

- (YKIRCMessage *)messageWithReceivedMessage:(NSString *)receivedMessage regexName:(NSString *)regexName
{
    NSArray *matches = [YKIRCClient matchesInString:receivedMessage regexName:regexName];
    NSArray *stuffs = [matches[0] componentsSeparatedByString:@" "];
    YKIRCMessage *message = [YKIRCMessage new];
    message.receiver = stuffs[0];
    message.text = stuffs[1];
    return message;
}

- (NSDictionary *)joinDataWithReceivedMessage:(NSString *)receivedMessage
{
    NSArray *matches = [YKIRCClient matchesInString:receivedMessage regexName:@"join"];
    YKIRCUser *user = [YKIRCUser new];
    user.nickName = matches[0];
    user.userName = matches[1];
    user.serverName = matches[2];
    return @{ @"user": user, @"channel": matches[3] };
}

- (NSDictionary *)partDataWithReceivedMessage:(NSString *)receivedMessage
{
    NSArray *matches = [YKIRCClient matchesInString:receivedMessage regexName:@"part"];
    YKIRCUser *user = [YKIRCUser new];
    user.nickName = matches[0];
    user.userName = matches[1];
    user.serverName = matches[2];
    return @{ @"user": user, @"channel": matches[3], @"message": matches[4] };
}

#pragma mark - AsyncSocketDelegate

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    YKIRCLog(@"Connect to %@ on %d", host, port);
	[_sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];

    [self sendRawString:[NSString stringWithFormat:@"PASS %@", _pass]
                    tag:YKIRCClientMessageTypePass];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    switch (tag) {
        case YKIRCClientMessageTypePass:
            [self sendRawString:[NSString stringWithFormat:@"NICK %@", _nickName]
                                tag:YKIRCClientMessageTypeNick];
            break;
        case YKIRCClientMessageTypeNick:
            [self sendRawString:[NSString stringWithFormat:@"USER %@ %d * :%@", _userName, _userMode, _realName]
                            tag:YKIRCClientMessageTypeUser];
            break;
        case YKIRCClientMessageTypeUser:
            [self.delegate ircClientOnConnected:self];
            break;
        case YKIRCClientMessageTypeJoin:
            break;
        default:
            break;
    }
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *receivedMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    YKIRCLog(@"<<< %@", receivedMessage);
    YKIRCClientMessageType messageType = [self getMessageTypeWithReceivedMessage:receivedMessage];
    switch (messageType) {
        case YKIRCClientMessageTypePrivMsg: {
            YKIRCMessage *message = [self messageWithReceivedMessage:receivedMessage regexName:@"privmsg"];
            [self.delegate ircClient:self onMessage:message];
            break;
        }
        case YKIRCClientMessageTypeNotice: {
            YKIRCMessage *message = [self messageWithReceivedMessage:receivedMessage regexName:@"notice"];
            [self.delegate ircClient:self onNotice:message];
            break;
        }
        case YKIRCClientMessageTypePing:
            [self sendRawString:@"PONG 0" tag:YKIRCClientMessageTypePong];
            break;
        case YKIRCClientMessageTypeJoin: {
            NSDictionary *data = [self joinDataWithReceivedMessage:receivedMessage];
            [self.delegate ircClient:self onJoin:data[@"user"] toChannel:data[@"channel"]];
            break;
        }
        case YKIRCClientMessageTypePart: {
            NSDictionary *data = [self partDataWithReceivedMessage:receivedMessage];
            [self.delegate ircClient:self onPart:data[@"user"] fromChannel:data[@"channel"] message:data[@"message"]];
            break;
        }
        default:
            [self.delegate ircClient:self onReadData:data];
            break;
    }

	if ([sock isConnected])
		[sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];
}

@end
