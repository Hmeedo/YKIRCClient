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

- (void)onConnected:(YKIRCClient *)ircClient
{
    [_client joinToChannel:@"#channel"];
}

- (IBAction)sendMessage:(id)sender
{
    NSString *message = _textField.text;
    [_client sendMessage:message recipient:@"#channel"];
}

@end
