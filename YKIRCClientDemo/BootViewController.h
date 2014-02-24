#import <UIKit/UIKit.h>
#import "YKIRCClient.h"

@interface BootViewController : UIViewController <YKIRCClientDeleate>

@property (nonatomic, strong) YKIRCClient *client;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextField *joinChannelField;
@property (weak, nonatomic) IBOutlet UITextField *partChannelField;
@property (weak, nonatomic) IBOutlet UITextField *rawTextField;
@property (weak, nonatomic) IBOutlet UITextView *textView;

- (IBAction)sendMessage:(id)sender;
- (IBAction)joinChannel:(id)sender;
- (IBAction)partChannel:(id)sender;
- (IBAction)sendRawMessage:(id)sender;

@end
