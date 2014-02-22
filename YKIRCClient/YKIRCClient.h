#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/AsyncSocket.h>

@class YKIRCClient;

@protocol YKIRCClientDeleate <NSObject>

- (void)onConnected:(YKIRCClient *)ircClient;

@end

@interface YKIRCClient : NSObject <AsyncSocketDelegate>

@property (weak) id<YKIRCClientDeleate> delegate;
@property (nonatomic, strong) AsyncSocket *socket;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) UInt16 port;
@property (nonatomic, copy) NSString *pass;
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *hostName;
@property (nonatomic, copy) NSString *serverName;
@property (nonatomic, copy) NSString *realName;

- (void)connect;
- (void)joinToChannel:(NSString *)channel;

- (void)sendRawString:(NSString *)string tag:(long)tag;
- (void)sendMessage:(NSString *)message recipient:(NSString *)recipient;

@end
