#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/AsyncSocket.h>
#import "YKIRCMessage.h"
#import "YKIRCUser.h"

#if DEBUG
#define YKIRCLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#define YKIRCLog(fmt, ...)
#endif

extern NSTimeInterval const kYKIRCClientDefaultTimeout;
extern NSUInteger const kYKIRCClientSockTagPass;
extern NSUInteger const kYKIRCClientSockTagNick;
extern NSUInteger const kYKIRCClientSockTagUser;
extern NSUInteger const kYKIRCClientSockTagPong;
extern NSUInteger const kYKIRCClientSockTagPrivMsg;
extern NSUInteger const kYKIRCClientSockTagJoin;
extern NSUInteger const kYKIRCClientSockTagPart;

@class YKIRCClient;

@protocol YKIRCClientDeleate <NSObject>

@optional
- (void)ircClientOnConnected:(YKIRCClient *)ircClient;
- (void)ircClient:(YKIRCClient *)ircClient onUnknownResponse:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onNotice:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onMessage:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onJoin:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onPart:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onQuit:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onMode:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onTopic:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onCommandResponse:(YKIRCMessage *)message;

@end

@interface YKIRCClient : NSObject <AsyncSocketDelegate>

@property (weak) id<YKIRCClientDeleate> delegate;
@property (nonatomic, strong) AsyncSocket *sock;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) UInt16 port;
@property (nonatomic, copy) NSString *pass;
@property (nonatomic, strong) YKIRCUser *user;

- (void)connect;
- (void)joinChannelTo:(NSString *)channel;
- (void)partChannelFrom:(NSString *)channel;

- (void)sendRawString:(NSString *)string tag:(long)tag;
- (void)sendMessage:(NSString *)message recipient:(NSString *)recipient;

@end
