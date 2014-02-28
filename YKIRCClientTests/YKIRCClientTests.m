#import <XCTest/XCTest.h>
#import "YKIRCClient.h"

@interface YKIRCClient ()

- (void)sendPass;
- (void)sendNick;
- (void)sendUser;
- (YKIRCMessage *)messageWithRawMessage:(NSString *)rawMessage;

@end

@interface YKIRCMessage ()

- (void)parseMessage;

@end

@interface YKIRCClientTests : XCTestCase

@end

@implementation YKIRCClientTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    YKIRCClient *client = [YKIRCClient new];
    XCTAssertEqualObjects(client.sock.delegate, client);
}

- (void)testUser
{
    YKIRCClient *client = [YKIRCClient new];
    XCTAssertNotNil(client.user);
}

- (void)testConnect
{
    NSString *host = @"example.com";
    UInt16 port = 80;
    
    id sockMock = [OCMockObject mockForClass:[AsyncSocket class]];
    YKIRCClient *client = [YKIRCClient new];
    client.sock = sockMock;
    client.host = host;
    client.port = port;

    [[sockMock expect] connectToHost:host onPort:port error:nil];
    [client connect];
    
    [sockMock verify];
}

- (void)testSendNickWhenConnected
{
    NSString *host = @"example.com";
    UInt16 port = 80;
    
    YKIRCClient *client = [YKIRCClient new];
    client.host = host;
    client.port = port;
    
    id clientMock = [OCMockObject partialMockForObject:client];
    [[clientMock expect] sendNick];
    
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didConnectToHost:host port:port];
    [clientMock verify];
}

- (void)testSendPassWhenConnected
{
    NSString *host = @"example.com";
    UInt16 port = 80;
    NSString *pass = @"pass";
    
    YKIRCClient *client = [YKIRCClient new];
    client.host = host;
    client.port = port;
    client.pass = pass;
    
    id clientMock = [OCMockObject partialMockForObject:client];
    [[clientMock expect] sendPass];
    
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didConnectToHost:host port:port];
    [clientMock verify];
}

- (void)testSendNickAfterSendPass
{
    NSString *host = @"example.com";
    UInt16 port = 80;
    NSString *pass = @"pass";
    
    YKIRCClient *client = [YKIRCClient new];
    client.host = host;
    client.port = port;
    client.pass = pass;

    id clientMock = [OCMockObject partialMockForObject:client];
    [[clientMock expect] sendNick];
    
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didWriteDataWithTag:kYKIRCClientSockTagPass];
    [clientMock verify];
}

- (void)testSendUserAfterSendNick
{
    NSString *host = @"example.com";
    UInt16 port = 80;
    
    YKIRCClient *client = [YKIRCClient new];
    client.host = host;
    client.port = port;
    
    id clientMock = [OCMockObject partialMockForObject:client];
    [[clientMock expect] sendUser];
    
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didWriteDataWithTag:kYKIRCClientSockTagNick];
    [clientMock verify];
}

- (void)testCallConnectedDelegate
{
    id delegateMock = [OCMockObject mockForProtocol:@protocol(YKIRCClientDeleate)];
    YKIRCClient *client = [YKIRCClient new];
    client.delegate = delegateMock;

    [[delegateMock expect] ircClientOnConnected:client];
    
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didWriteDataWithTag:kYKIRCClientSockTagUser];
    [delegateMock verify];
}

- (void)testCallOnMessage
{
    id delegateMock = [OCMockObject mockForProtocol:@protocol(YKIRCClientDeleate)];
    YKIRCClient *client = [YKIRCClient new];
    client.delegate = delegateMock;
    
    [[delegateMock expect] ircClient:client onMessage:OCMOCK_ANY];
    
    NSData *data = [@":sender PRIVMSG #channel :message" dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    [delegateMock verify];
}

- (void)testCallOnNotice
{
    id delegateMock = [OCMockObject mockForProtocol:@protocol(YKIRCClientDeleate)];
    YKIRCClient *client = [YKIRCClient new];
    client.delegate = delegateMock;
    
    [[delegateMock expect] ircClient:client onNotice:OCMOCK_ANY];
    
    NSData *data = [@":sender NOTICE :message" dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    [delegateMock verify];
}

- (void)testCallOnPing
{
    YKIRCClient *client = [YKIRCClient new];
    id clientMock = [OCMockObject partialMockForObject:client];
    [[clientMock expect] sendRawString:@"PONG 0" tag:kYKIRCClientSockTagPong];

    NSData *data = [@"PING host" dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [clientMock onSocket:sockMock didReadData:data withTag:0];
    [clientMock verify];
}

- (void)testCallOnJoin
{
    id delegateMock = [OCMockObject mockForProtocol:@protocol(YKIRCClientDeleate)];
    YKIRCClient *client = [YKIRCClient new];
    client.delegate = delegateMock;
    
    [[delegateMock expect] ircClient:client onJoin:OCMOCK_ANY];
    
    NSData *data = [@":sender JOIN #channel" dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    [delegateMock verify];
}

- (void)testCallOnPart
{
    id delegateMock = [OCMockObject mockForProtocol:@protocol(YKIRCClientDeleate)];
    YKIRCClient *client = [YKIRCClient new];
    client.delegate = delegateMock;
    
    [[delegateMock expect] ircClient:client onPart:OCMOCK_ANY];
    
    NSData *data = [@":sender PART #channel :Disconnect" dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    [delegateMock verify];
}

- (void)testCallOnNumeric
{
    id delegateMock = [OCMockObject mockForProtocol:@protocol(YKIRCClientDeleate)];
    YKIRCClient *client = [YKIRCClient new];
    client.delegate = delegateMock;
    
    [[delegateMock expect] ircClient:client onCommandResponse:OCMOCK_ANY];
    
    NSData *data = [@":sender 333 foo :bar" dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    [delegateMock verify];
}

- (void)testCallOnUnknown
{
    id delegateMock = [OCMockObject mockForProtocol:@protocol(YKIRCClientDeleate)];
    YKIRCClient *client = [YKIRCClient new];
    client.delegate = delegateMock;
    
    [[delegateMock expect] ircClient:client onUnknownResponse:OCMOCK_ANY];
    
    NSData *data = [@":sender" dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    [delegateMock verify];
}

- (void)testCallOnQuit
{
    id delegateMock = [OCMockObject mockForProtocol:@protocol(YKIRCClientDeleate)];
    YKIRCClient *client = [YKIRCClient new];
    client.delegate = delegateMock;
    
    [[delegateMock expect] ircClient:client onQuit:OCMOCK_ANY];
    
    NSData *data = [@":sender QUIT :Disconnect" dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    [delegateMock verify];
}

- (void)testCallOnMode
{
    id delegateMock = [OCMockObject mockForProtocol:@protocol(YKIRCClientDeleate)];
    YKIRCClient *client = [YKIRCClient new];
    client.delegate = delegateMock;
    
    [[delegateMock expect] ircClient:client onMode:OCMOCK_ANY];
    
    NSData *data = [@":sender MODE #channel +sn" dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    [delegateMock verify];
}

- (void)testCallOnTopic
{
    id delegateMock = [OCMockObject mockForProtocol:@protocol(YKIRCClientDeleate)];
    YKIRCClient *client = [YKIRCClient new];
    client.delegate = delegateMock;
    
    [[delegateMock expect] ircClient:client onTopic:OCMOCK_ANY];
    
    NSData *data = [@":sender TOPIC #channel :new topic" dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    [delegateMock verify];
}

- (void)testWelcome
{
    YKIRCClient *client = [YKIRCClient new];
    NSString *trail = @"Welcome to the Internet Relay Network nick!user@host";
    NSString *rawMessage = [NSString stringWithFormat:@":sender 001 :%@", trail];
    NSData *data = [rawMessage dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    XCTAssertEqualObjects(client.serverReply.welcome, trail);
}

- (void)testYourHost
{
    YKIRCClient *client = [YKIRCClient new];
    NSString *trail = @"Your host is <servername>, running version <ver>";
    NSString *rawMessage = [NSString stringWithFormat:@":sender 002 :%@", trail];
    NSData *data = [rawMessage dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    XCTAssertEqualObjects(client.serverReply.yourHost, trail);
}

- (void)testCreated
{
    YKIRCClient *client = [YKIRCClient new];
    NSString *trail = @"This server was created <date>";
    NSString *rawMessage = [NSString stringWithFormat:@":sender 003 :%@", trail];
    NSData *data = [rawMessage dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    XCTAssertEqualObjects(client.serverReply.created, trail);
}

- (void)testMyInfo
{
    YKIRCClient *client = [YKIRCClient new];
    NSString *trail = @"<servername> <version> <available user modes> <available channel modes>";
    NSString *rawMessage = [NSString stringWithFormat:@":sender 004 :%@", trail];
    NSData *data = [rawMessage dataUsingEncoding:NSUTF8StringEncoding];
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    [client onSocket:sockMock didReadData:data withTag:0];
    XCTAssertEqualObjects(client.serverReply.myInfo, trail);
}

- (void)testMotd
{
    YKIRCClient *client = [YKIRCClient new];
    NSArray *cmds = @[ @(375), @(372), @(376) ];
    NSDictionary *trails = @{
                             @(375): @"- <server> Message of the day -",
                             @(372): @"<text>",
                             @(376): @"End of MOTD Command",
                             };
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    for (NSNumber *cmd in cmds) {
        NSString *rawMessage = [NSString stringWithFormat:@":sender %d :%@", [cmd integerValue], trails[cmd]];
        NSData *data = [rawMessage dataUsingEncoding:NSUTF8StringEncoding];
        [client onSocket:sockMock didReadData:data withTag:0];
    }
    XCTAssertEqualObjects(client.serverReply.motd,
                          @"- <server> Message of the day -\n<text>\nEnd of MOTD Command");
}

@end
