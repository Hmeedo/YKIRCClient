#import "BootViewController.h"

@interface BootViewController ()

@end

@implementation BootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _client = [YKIRCClient new];
        _client.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _client.host = @"IRC Host";
    _client.port = 6667;
//    _client.pass = @"pass";
    _client.nickName = @"yournick";
    _client.userName = @"username";
    _client.serverName = @"servername";
    _client.hostName = @"hostname";
    _client.realName = @"realname";
    [_client connect];
}

- (IBAction)sendMessage:(id)sender
{
    NSString *message = _textField.text;
    [_client sendMessage:message recipient:@"#channel"];
    _textField.text = nil;
    [_textField resignFirstResponder];
}

#pragma mark - YKIRCClientDelegate

- (void)ircClientOnConnected:(YKIRCClient *)ircClient
{
    [ircClient joinToChannel:@"#channel"];
}

- (void)ircClient:(YKIRCClient *)ircClient onReadData:(NSData *)data
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *newText = [_textView.text stringByAppendingString:str];
    _textView.text = newText;
}

@end
