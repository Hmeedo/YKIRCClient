#import <XCTest/XCTest.h>
#import "YKIRCClient.h"

@interface YKIRCClient ()

- (void)sendPass;
- (void)sendNick;
- (void)sendUser;

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
    YKIRCClient *client = [[YKIRCClient alloc] init];
    XCTAssertEqualObjects(client.sock.delegate, client);
}

- (void)testUser
{
    YKIRCClient *client = [[YKIRCClient alloc] init];
    XCTAssertNotNil(client.user);
}

- (void)testConnect
{
    NSString *host = @"example.com";
    UInt16 port = 80;
    
    id sockMock = [OCMockObject mockForClass:[AsyncSocket class]];
    YKIRCClient *client = [[YKIRCClient alloc] init];
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
    
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    YKIRCClient *client = [[YKIRCClient alloc] init];
    client.host = host;
    client.port = port;
    
    id clientMock = [OCMockObject partialMockForObject:client];
    [[clientMock expect] sendNick];
    
    [client onSocket:sockMock didConnectToHost:host port:port];
    [clientMock verify];
}

- (void)testSendPassWhenConnected
{
    NSString *host = @"example.com";
    UInt16 port = 80;
    NSString *pass = @"pass";
    
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    YKIRCClient *client = [[YKIRCClient alloc] init];
    client.host = host;
    client.port = port;
    client.pass = pass;
    
    id clientMock = [OCMockObject partialMockForObject:client];
    [[clientMock expect] sendPass];
    
    [client onSocket:sockMock didConnectToHost:host port:port];
    [clientMock verify];
}

- (void)testSendNickAfterSendPass
{
    NSString *host = @"example.com";
    UInt16 port = 80;
    NSString *pass = @"pass";
    
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    YKIRCClient *client = [[YKIRCClient alloc] init];
    client.host = host;
    client.port = port;
    client.pass = pass;

    id clientMock = [OCMockObject partialMockForObject:client];
    [[clientMock expect] sendNick];
    
    [client onSocket:sockMock didWriteDataWithTag:kYKIRCClientSockTagPass];
    [clientMock verify];
}

- (void)testSendUserAfterSendNick
{
    NSString *host = @"example.com";
    UInt16 port = 80;
    
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    YKIRCClient *client = [[YKIRCClient alloc] init];
    client.host = host;
    client.port = port;
    
    id clientMock = [OCMockObject partialMockForObject:client];
    [[clientMock expect] sendUser];
    
    [client onSocket:sockMock didWriteDataWithTag:kYKIRCClientSockTagNick];
    [clientMock verify];
}

- (void)testCallConnectedDelegate
{
    NSString *host = @"example.com";
    UInt16 port = 80;
    
    id sockMock = [OCMockObject niceMockForClass:[AsyncSocket class]];
    id delegateMock = [OCMockObject mockForProtocol:@protocol(YKIRCClientDeleate)];
    YKIRCClient *client = [[YKIRCClient alloc] init];
    client.delegate = delegateMock;
    client.host = host;
    client.port = port;
    
    [[delegateMock expect] ircClientOnConnected:client];
    
    [client onSocket:sockMock didWriteDataWithTag:kYKIRCClientSockTagUser];
    [delegateMock verify];
}

@end
