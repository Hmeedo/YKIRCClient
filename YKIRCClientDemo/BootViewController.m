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
    _client.nickName = @"nick";
    _client.userName = @"username";
    _client.userMode = 0;
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

- (IBAction)joinChannel:(id)sender
{
    NSString *channel = _joinChannelField.text;
    [_client joinToChannel:channel];
    _joinChannelField.text = nil;
    [_joinChannelField resignFirstResponder];
}

- (IBAction)partChannel:(id)sender
{
    NSString *channel = _partChannelField.text;
    [_client partFromChannel:channel];
    _partChannelField.text = nil;
    [_partChannelField resignFirstResponder];
}

- (IBAction)sendRawMessage:(id)sender
{
    NSString *rawText = _rawTextField.text;
    [_client sendRawString:rawText tag:YKIRCClientMessageTypeUnknown];
    _rawTextField.text = nil;
    [_rawTextField resignFirstResponder];
}

#pragma mark - YKIRCClientDelegate

- (void)ircClientOnConnected:(YKIRCClient *)ircClient
{
    NSLog(@"Connected!");
}

- (void)ircClient:(YKIRCClient *)ircClient onReadData:(NSData *)data
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *newText = [_textView.text stringByAppendingString:str];
    _textView.text = newText;
}

- (void)ircClient:(YKIRCClient *)ircClient onMessage:(YKIRCMessage *)message
{
    NSLog(@"message ---------");
    NSLog(@"receiver: %@", message.receiver);
    NSLog(@"text: %@", message.text);
}

- (void)ircClient:(YKIRCClient *)ircClient onNotice:(YKIRCMessage *)message
{
    NSLog(@"notice ---------");
    NSLog(@"receiver: %@", message.receiver);
    NSLog(@"text: %@", message.text);
}

- (void)ircClient:(YKIRCClient *)ircClient onJoin:(YKIRCUser *)user toChannel:(NSString *)channel
{
    NSLog(@"join ---------");
    NSLog(@"%@ has joined to %@", user.nickName, channel);
}

- (void)ircClient:(YKIRCClient *)ircClient onPart:(YKIRCUser *)user fromChannel:(NSString *)channel message:(NSString *)message
{
    NSLog(@"part ---------");
    NSLog(@"%@ has left from %@ (%@)", user.nickName, channel, message);
}

@end
