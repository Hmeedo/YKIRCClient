#import <Foundation/Foundation.h>

@interface YKIRCServerReply : NSObject

@property (nonatomic, copy) NSString *welcome;
@property (nonatomic, copy) NSString *yourHost;
@property (nonatomic, copy) NSString *created;
@property (nonatomic, copy) NSString *myInfo;
@property (nonatomic, copy) NSString *motd;

@end
