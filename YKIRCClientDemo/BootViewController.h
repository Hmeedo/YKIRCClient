#import <UIKit/UIKit.h>
#import "YKIRCClient.h"

@interface BootViewController : UIViewController <YKIRCClientDeleate>

@property (nonatomic, strong) YKIRCClient *client;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UITextView *textView;

- (IBAction)sendMessage:(id)sender;

@end
