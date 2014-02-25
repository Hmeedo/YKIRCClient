#import <Foundation/Foundation.h>

@interface YKIRCUser : NSObject

@property (nonatomic, copy) NSString *nick;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *server;
@property (nonatomic, copy) NSString *realName;
@property (nonatomic, assign) NSUInteger mode;

@end
