#import "YKIRCClient.h"

static NSTimeInterval const kYKIRCClientDefaultTimeout = 60;
static NSUInteger const kYKIRCClientSockTagPass = 0;
static NSUInteger const kYKIRCClientSockTagNick = 1;
static NSUInteger const kYKIRCClientSockTagUser = 2;
static NSUInteger const kYKIRCClientSockTagPong = 3;

@interface YKIRCClient ()

@end

@implementation YKIRCClient

- (id)init
{
    self = [super init];
    if (self) {
        _sock = [[AsyncSocket alloc] initWithDelegate:self];
    }
    return self;
}

#pragma mark - Public methods

- (YKIRCUser *)user
{
    if (!_user) {
        _user = [YKIRCUser new];
    }
    return _user;
}

- (void)connect
{
    [_sock connectToHost:_host onPort:_port error:nil];
}

- (void)joinChannelTo:(NSString *)channel
{
    if (_sock.isConnected) {
        [self sendRawString:[NSString stringWithFormat:@"JOIN %@", channel]
                        tag:0];
    } else {
        YKIRCLog(@"No connect yet.");
    }
}

- (void)partChannelFrom:(NSString *)channel
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
    [self sendRawString:msg tag:0];
}

#pragma mark - Private methods

- (void)sendPass {
    [self sendRawString:[NSString stringWithFormat:@"PASS %@", _pass]
                    tag:kYKIRCClientSockTagPass];
}

- (void)sendNick {
    [self sendRawString:[NSString stringWithFormat:@"NICK %@", _user.nick]
                    tag:kYKIRCClientSockTagNick];
}

- (void)sendUser {
    [self sendRawString:[NSString stringWithFormat:@"USER %@ %d * :%@", _user.name, _user.mode, _user.realName]
                    tag:kYKIRCClientSockTagUser];
}

#pragma mark - AsyncSocketDelegate

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    YKIRCLog(@"Connect to %@ on %d", host, port);
	[_sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];

    if (_pass) {
        [self sendPass];
    } else {
        [self sendNick];
    }
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    switch (tag) {
        case kYKIRCClientSockTagPass:
            [self sendNick];
            break;
        case kYKIRCClientSockTagNick:
            [self sendUser];
            break;
        case kYKIRCClientSockTagUser:
            [self.delegate ircClientOnConnected:self];
            break;
        default:
            break;
    }
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *receivedMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    YKIRCLog(@"<<< %@", receivedMessage);
    YKIRCMessage *message = [[YKIRCMessage alloc] initWithRawMessage:receivedMessage];
    switch (message.type) {
        case YKIRCMessageTypePrivMsg:
            if ([self.delegate respondsToSelector:@selector(ircClient:onMessage:)])
                [self.delegate ircClient:self onMessage:message];
            break;
        case YKIRCMessageTypeNotice:
            if ([self.delegate respondsToSelector:@selector(ircClient:onNotice:)])
                [self.delegate ircClient:self onNotice:message];
            break;
        case YKIRCMessageTypePing:
            [self sendRawString:@"PONG 0" tag:kYKIRCClientSockTagPong];
            break;
        case YKIRCMessageTypeJoin:
            if ([self.delegate respondsToSelector:@selector(ircClient:onJoin:)])
                [self.delegate ircClient:self onJoin:message];
            break;
        case YKIRCMessageTypePart:
            if ([self.delegate respondsToSelector:@selector(ircClient:onPart:)])
                [self.delegate ircClient:self onPart:message];
            break;
        case YKIRCMessageTypeNumeric:
            if ([self.delegate respondsToSelector:@selector(ircClient:onCommandResponse:)])
                [self.delegate ircClient:self onCommandResponse:message];
            break;
        case YKIRCMessageTypeUnknown:
            if ([self.delegate respondsToSelector:@selector(ircClient:onUnknownResponse:)])
                [self.delegate ircClient:self onUnknownResponse:message];
            break;
        case YKIRCMessageTypeQuit:
            if ([self.delegate respondsToSelector:@selector(ircClient:onQuit:)])
                [self.delegate ircClient:self onQuit:message];
            break;
        case YKIRCMessageTypeMode:
            if ([self.delegate respondsToSelector:@selector(ircClient:onMode:)])
                [self.delegate ircClient:self onMode:message];
            break;
        case YKIRCMessageTypeTopic:
            if ([self.delegate respondsToSelector:@selector(ircClient:onTopic:)])
                [self.delegate ircClient:self onTopic:message];
            break;
        default:
            YKIRCLog(@"Received invalid response: %@", receivedMessage);
            break;
    }

	if ([sock isConnected])
		[sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];
}

@end
