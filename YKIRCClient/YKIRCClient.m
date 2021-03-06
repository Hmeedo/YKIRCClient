#import "YKIRCClient.h"

NSTimeInterval const kYKIRCClientDefaultTimeout = 60;
NSUInteger const kYKIRCClientSockTagPass = 1;
NSUInteger const kYKIRCClientSockTagNick = 2;
NSUInteger const kYKIRCClientSockTagUser = 3;
NSUInteger const kYKIRCClientSockTagPong = 4;
NSUInteger const kYKIRCClientSockTagPrivMsg = 5;
NSUInteger const kYKIRCClientSockTagJoin = 6;
NSUInteger const kYKIRCClientSockTagPart = 7;

NSUInteger const kYKIRCClientReplyCommandWelcome = 1;
NSUInteger const kYKIRCClientReplyCommandYourHost = 2;
NSUInteger const kYKIRCClientReplyCommandCreated = 3;
NSUInteger const kYKIRCClientReplyCommandMyInfo = 4;

NSUInteger const kYKIRCClientReplyCommandMotdStart = 375;
NSUInteger const kYKIRCClientReplyCommandMotd = 372;
NSUInteger const kYKIRCClientReplyCommandEndOfMotd = 376;
NSUInteger const kYKIRCClientReplyCommandNamReply = 353;
NSUInteger const kYKIRCClientReplyCommandEndOfNames = 366;

@interface YKIRCClient ()

@end

@implementation YKIRCClient

- (id)init
{
    self = [super init];
    if (self) {
        _sock = [[AsyncSocket alloc] initWithDelegate:self];
        _user = [YKIRCUser new];
        _serverReply = [YKIRCServerReply new];
        _channels = @[].mutableCopy;
    }
    return self;
}

#pragma mark - Public methods

- (void)connect
{
    [_sock connectToHost:_host onPort:_port error:nil];
}

- (void)joinChannelTo:(NSString *)channel
{
    if (_sock.isConnected) {
        [self sendRawString:[NSString stringWithFormat:@"JOIN %@", channel]
                        tag:kYKIRCClientSockTagJoin];
    } else {
        YKIRCLog(@"No connect yet.");
    }
}

- (void)partChannelFrom:(NSString *)channel
{
    if (_sock.isConnected) {
        [self sendRawString:[NSString stringWithFormat:@"PART %@", channel]
                        tag:kYKIRCClientSockTagPart];
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
    [self sendRawString:[NSString stringWithFormat:@"PRIVMSG %@ %@", recipient, message]
                    tag:kYKIRCClientSockTagPrivMsg];
}

- (YKIRCChannel *)channelWithName:(NSString *)name
{
    NSUInteger index = [self indexOfChannelWithName:name];
    if (index != NSNotFound) {
        return [_channels objectAtIndex:index];
    }
    return nil;
}

#pragma mark - Private methods

- (void)sendPass
{
    [self sendRawString:[NSString stringWithFormat:@"PASS %@", _pass]
                    tag:kYKIRCClientSockTagPass];
}

- (void)sendNick
{
    [self sendRawString:[NSString stringWithFormat:@"NICK %@", _user.nick]
                    tag:kYKIRCClientSockTagNick];
}

- (void)sendUser
{
    [self sendRawString:[NSString stringWithFormat:@"USER %@ %d * :%@", _user.name, _user.mode, _user.realName]
                    tag:kYKIRCClientSockTagUser];
}

- (NSUInteger)indexOfChannelWithName:(NSString *)name
{
    int i = 0;
    for (YKIRCChannel *channel in _channels) {
        if ([channel.name isEqualToString:name]) {
            return i;
        }
        i++;
    }
    return NSNotFound;
}

- (void)parseNumericCommandWithMessage:(YKIRCMessage *)message
{
    switch (message.numericCommand) {
        case kYKIRCClientReplyCommandWelcome:
            self.serverReply.welcome = message.trail;
            break;
        case kYKIRCClientReplyCommandYourHost:
            self.serverReply.yourHost = message.trail;
            break;
        case kYKIRCClientReplyCommandCreated:
            self.serverReply.created = message.trail;
            break;
        case kYKIRCClientReplyCommandMyInfo:
            self.serverReply.myInfo = message.trail;
            break;
        case kYKIRCClientReplyCommandMotdStart:
            self.serverReply.motd = message.trail;
            break;
        case kYKIRCClientReplyCommandMotd:
        case kYKIRCClientReplyCommandEndOfMotd: {
            NSString *text = [NSString stringWithFormat:@"\n%@", message.trail];
            self.serverReply.motd = [self.serverReply.motd stringByAppendingString:text];
            break;
        }
        case kYKIRCClientReplyCommandNamReply: {
            NSString *channelMode = message.params[1];
            NSString *channelName = message.params[2];
            YKIRCChannel *channel;
            NSUInteger index = [self indexOfChannelWithName:channelName];
            if (index == NSNotFound) {
                channel = [[YKIRCChannel alloc] initWithName:channelName modeString:channelMode];
                [_channels addObject:channel];
            } else {
                channel = [_channels objectAtIndex:index];
            }
            NSArray *users = [message.trail componentsSeparatedByString:@" "];
            for (NSString *nick in users) {
                [channel addUser:nick];
            }
            break;
        }
        default:
            break;
    }
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
        case kYKIRCClientSockTagPrivMsg:
        case kYKIRCClientSockTagJoin:
        case kYKIRCClientSockTagPart:
            break;
        default:
            break;
    }
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (!data) {
        YKIRCLog(@"Received null message");
    } else {
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
                [self parseNumericCommandWithMessage:message];
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
    }

	if ([sock isConnected])
		[sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];
}

@end
