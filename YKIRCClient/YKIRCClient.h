#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/AsyncSocket.h>
#import "YKIRCMessage.h"
#import "YKIRCUser.h"

#if DEBUG
#define YKIRCLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#define YKIRCLog(fmt, ...)
#endif

@class YKIRCClient;

@protocol YKIRCClientDeleate <NSObject>

- (void)ircClientOnConnected:(YKIRCClient *)ircClient;
- (void)ircClient:(YKIRCClient *)ircClient onReadData:(NSData *)data;
- (void)ircClient:(YKIRCClient *)ircClient onNotice:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onMessage:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onJoin:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onPart:(YKIRCMessage *)message;

@end

@interface YKIRCClient : NSObject <AsyncSocketDelegate>

@property (weak) id<YKIRCClientDeleate> delegate;
@property (nonatomic, strong) AsyncSocket *sock;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) UInt16 port;
@property (nonatomic, copy) NSString *pass;
@property (nonatomic, strong) YKIRCUser *user;

- (void)connect;
- (void)joinToChannel:(NSString *)channel;
- (void)partFromChannel:(NSString *)channel;

- (void)sendRawString:(NSString *)string tag:(long)tag;
- (void)sendMessage:(NSString *)message recipient:(NSString *)recipient;

@end
