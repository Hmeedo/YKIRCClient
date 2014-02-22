#import <UIKit/UIKit.h>
#import "YKIRCClient.h"

@interface BootViewController : UIViewController <YKIRCClientDeleate>

@property (nonatomic, strong) YKIRCClient *client;
@property (weak, nonatomic) IBOutlet UITextField *textField;

- (IBAction)sendMessage:(id)sender;

@end
