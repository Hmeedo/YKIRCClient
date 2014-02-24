#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/AsyncSocket.h>
#import "YKIRCMessage.h"

typedef NS_ENUM(NSUInteger, YKIRCClientMessageType) {
    YKIRCClientMessageTypeUnknown,
    YKIRCClientMessageTypePass,
    YKIRCClientMessageTypeNick,
    YKIRCClientMessageTypeUser,
    YKIRCClientMessageTypeJoin,
    YKIRCClientMessageTypePrivMsg,
    YKIRCClientMessageTypePing,
    YKIRCClientMessageTypePong,
    YKIRCClientMessageTypeNotice,
};

@class YKIRCClient;

@protocol YKIRCClientDeleate <NSObject>

- (void)ircClientOnConnected:(YKIRCClient *)ircClient;
- (void)ircClient:(YKIRCClient *)ircClient onReadData:(NSData *)data;
- (void)ircClient:(YKIRCClient *)ircClient onNotice:(YKIRCMessage *)message;
- (void)ircClient:(YKIRCClient *)ircClient onMessage:(YKIRCMessage *)message;

@end

@interface YKIRCClient : NSObject <AsyncSocketDelegate>

@property (weak) id<YKIRCClientDeleate> delegate;
@property (nonatomic, strong) AsyncSocket *sock;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) UInt16 port;
@property (nonatomic, copy) NSString *pass;
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, assign) NSUInteger userMode;
@property (nonatomic, copy) NSString *realName;

- (void)connect;
- (void)joinToChannel:(NSString *)channel;
- (void)partFromChannel:(NSString *)channel;

- (void)sendRawString:(NSString *)string tag:(long)tag;
- (void)sendMessage:(NSString *)message recipient:(NSString *)recipient;

@end
