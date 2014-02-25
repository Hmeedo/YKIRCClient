#import "YKIRCClient.h"

static NSTimeInterval const kYKIRCClientDefaultTimeout = 60;
static NSUInteger const kYKIRCClientSockTagPass = 0;
static NSUInteger const kYKIRCClientSockTagNick = 1;
static NSUInteger const kYKIRCClientSockTagUser = 2;
static NSUInteger const kYKIRCClientSockTagPong = 3;

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
        _user = [YKIRCUser new];
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
                        tag:0];
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
    [self sendRawString:msg tag:0];
}

#pragma mark - Private methods


#pragma mark - AsyncSocketDelegate

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    YKIRCLog(@"Connect to %@ on %d", host, port);
	[_sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];

    [self sendRawString:[NSString stringWithFormat:@"PASS %@", _pass]
                    tag:kYKIRCClientSockTagPass];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    switch (tag) {
        case kYKIRCClientSockTagPass:
            [self sendRawString:[NSString stringWithFormat:@"NICK %@", _user.nick]
                                tag:kYKIRCClientSockTagNick];
            break;
        case kYKIRCClientSockTagNick:
            [self sendRawString:[NSString stringWithFormat:@"USER %@ %d * :%@", _user.name, _user.mode, _user.realName]
                            tag:kYKIRCClientSockTagUser];
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
    YKIRCMessage *message = [[YKIRCMessage alloc] initWithMessage:receivedMessage];
    switch (message.type) {
        case YKIRCMessageTypePrivMsg:
            [self.delegate ircClient:self onMessage:message];
            break;
        case YKIRCMessageTypeNotice:
            [self.delegate ircClient:self onNotice:message];
            break;
        case YKIRCMessageTypePing:
            [self sendRawString:@"PONG 0" tag:kYKIRCClientSockTagPong];
            break;
        case YKIRCMessageTypeJoin:
            [self.delegate ircClient:self onJoin:message];
            break;
        case YKIRCMessageTypePart:
            [self.delegate ircClient:self onPart:message];
            break;
        default:
            [self.delegate ircClient:self onReadData:data];
            break;
    }

	if ([sock isConnected])
		[sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];
}

@end
