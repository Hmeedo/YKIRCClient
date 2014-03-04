#import <UIKit/UIKit.h>
#import "YKIRCClient.h"

@interface BootViewController : UIViewController <YKIRCClientDeleate>

@property (nonatomic, strong) YKIRCClient *client;
@property (weak, nonatomic) IBOutlet UITextField *hostField;
@property (weak, nonatomic) IBOutlet UITextField *rawMessageField;
@property (weak, nonatomic) IBOutlet UITextView *textView;

- (IBAction)connect:(id)sender;
- (IBAction)sendRawMessage:(id)sender;

@end
