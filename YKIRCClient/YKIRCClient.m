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
        NSLog(@"No connect yet.");
    }
}

- (void)partFromChannel:(NSString *)channel
{
    if (_sock.isConnected) {
        [self sendRawString:[NSString stringWithFormat:@"PART %@", channel]
                        tag:0];
    } else {
        NSLog(@"No connect yet.");
    }
}

- (void)sendRawString:(NSString *)string tag:(long)tag
{
    NSLog(@">>> %@", string);
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

- (YKIRCClientMessageType)getMessageTypeWithReceivedMessage:(NSString *)receivedMessage
{
    if ([receivedMessage hasPrefix:@"PING"]) {
        return YKIRCClientMessageTypePing;
    } else if ([receivedMessage hasPrefix:@":"]) {
        NSRange range = [receivedMessage rangeOfString:@"PRIVMSG"];
        if (range.location != NSNotFound) {
            return YKIRCClientMessageTypePrivMsg;
        }
        range = [receivedMessage rangeOfString:@"NOTICE"];
        if (range.location != NSNotFound) {
            return YKIRCClientMessageTypeNotice;
        }
    }
    return YKIRCClientMessageTypeUnknown;
}

- (YKIRCMessage *)messageWithPrivateMessage:(NSString *)privateMessage
{
    NSRange range = [privateMessage rangeOfString:@"PRIVMSG"];
    NSString *line = [privateMessage substringFromIndex:range.location];
    NSArray *stuffs = [line componentsSeparatedByString:@" "];
    YKIRCMessage *message = [YKIRCMessage new];
    message.receiver = stuffs[1];
    message.text = stuffs[2];
    return message;
}

- (YKIRCMessage *)messageWithNotice:(NSString *)notice;
{
    NSRange range = [notice rangeOfString:@"PRIVMSG"];
    NSString *line = [notice substringFromIndex:range.location];
    NSArray *stuffs = [line componentsSeparatedByString:@" "];
    YKIRCMessage *message = [YKIRCMessage new];
    message.receiver = stuffs[1];
    message.text = stuffs[2];
    return message;
}

#pragma mark - AsyncSocketDelegate

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Connect to %@ on %d", host, port);
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
    NSLog(@"<<< %@", receivedMessage);
    YKIRCClientMessageType messageType = [self getMessageTypeWithReceivedMessage:receivedMessage];
    switch (messageType) {
        case YKIRCClientMessageTypePrivMsg: {
            YKIRCMessage *message = [self messageWithPrivateMessage:receivedMessage];
            [self.delegate ircClient:self onMessage:message];
            break;
        }
        case YKIRCClientMessageTypeNotice: {
            YKIRCMessage *message = [self messageWithNotice:receivedMessage];
            [self.delegate ircClient:self onNotice:message];
            break;
        }
        case YKIRCClientMessageTypePing:
            [self sendRawString:@"PONG 0" tag:YKIRCClientMessageTypePong];
            break;
        default:
            [self.delegate ircClient:self onReadData:data];
            break;
    }

	if ([sock isConnected])
		[sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];
}

@end
