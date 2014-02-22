#import "YKIRCClient.h"

static NSTimeInterval const kYKIRCClientDefaultTimeout = 60;

static long const kYKIRCClientTagPass = 0;
static long const kYKIRCClientTagNick = 1;
static long const kYKIRCClientTagUser = 2;
static long const kYKIRCClientTagJoin = 3;
static long const kYKIRCClientTagPrivMsg = 4;

@interface YKIRCClient ()

@property (nonatomic, strong) NSMutableArray *channels;

@end

@implementation YKIRCClient

- (id)init
{
    self = [super init];
    if (self) {
        _socket = [[AsyncSocket alloc] initWithDelegate:self];
        _channels = @[].mutableCopy;
    }
    return self;
}

- (void)connect
{
    [_socket connectToHost:_host onPort:_port error:nil];
}

- (void)joinToChannel:(NSString *)channel
{
    if (_socket.isConnected) {
        [self sendRawString:[NSString stringWithFormat:@"JOIN %@ \r\n", channel]
                        tag:kYKIRCClientTagJoin];
    } else {
        NSLog(@"No connect yet.");
    }
}

- (void)sendRawString:(NSString *)string tag:(long)tag
{
    NSLog(@"--- %@", string);
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [_socket writeData:data withTimeout:kYKIRCClientDefaultTimeout tag:tag];
}

- (void)sendMessage:(NSString *)message recipient:(NSString *)recipient
{
    NSString *msg = [NSString stringWithFormat:@"PRIVMSG %@ %@ \r\n", recipient, message];
    [self sendRawString:msg tag:kYKIRCClientTagPrivMsg];
}

#pragma mark - Private methods

#pragma mark - AsyncSocketDelegate

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Connect to %@ on %d", host, port);
	[_socket readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];

    [self sendRawString:[NSString stringWithFormat:@"PASS %@ \r\n", _pass]
                    tag:kYKIRCClientTagPass];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    switch (tag) {
        case kYKIRCClientTagPass:
            NSLog(@"Sent pass");
            [self sendRawString:[NSString stringWithFormat:@"NICK %@ \r\n", _nickName]
                                tag:kYKIRCClientTagNick];
            break;
        case kYKIRCClientTagNick:
            NSLog(@"Sent nick");
            [self sendRawString:[NSString stringWithFormat:@"USER %@ %@ %@ :%@ \r\n", _userName, _hostName, _serverName, _realName]
                            tag:kYKIRCClientTagUser];
            break;
        case kYKIRCClientTagUser:
            NSLog(@"Sent user");
            [self.delegate onConnected:self];
            break;
        case kYKIRCClientTagJoin:
            NSLog(@"Joined");
            break;
        default:
            break;
    }
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"read data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

@end
