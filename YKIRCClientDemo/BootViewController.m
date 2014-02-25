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
    _client.host = @"IRC host";
    _client.port = 6667;
//    _client.pass = @"pass";
    _client.user.nick = @"nick";
    _client.user.name = @"username";
    _client.user.mode = 0;
    _client.user.realName = @"realname";
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
    [_client sendRawString:rawText tag:0];
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
    if (message.user.nick) {
        NSLog(@"nick: %@", message.user.nick);
    } else {
        NSLog(@"sender: %@", message.sender);
    }
    NSLog(@"receiver: %@", message.params[0]);
    NSLog(@"text: %@", message.trail);
}

- (void)ircClient:(YKIRCClient *)ircClient onNotice:(YKIRCMessage *)message
{
    NSLog(@"notice ---------");
    NSLog(@"sender: %@", message.sender);
    NSLog(@"receiver: %@", message.params[0]);
    NSLog(@"text: %@", message.trail);
}

- (void)ircClient:(YKIRCClient *)ircClient onJoin:(YKIRCMessage *)message
{
    NSLog(@"join ---------");
    NSLog(@"%@ has joined to %@", message.user.nick, message.trail);
}

- (void)ircClient:(YKIRCClient *)ircClient onPart:(YKIRCMessage *)message
{
    NSLog(@"part ---------");
    NSLog(@"%@ has left from %@ (%@)", message.user.nick, message.params[0], message.trail);
}

@end
