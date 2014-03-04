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
}

- (IBAction)connect:(id)sender
{
    NSString *host = _hostField.text;
    _client.host = host;
    _client.port = 6667;
//    _client.pass = @"pass";
    _client.user.nick = @"ykircclient";
    _client.user.name = @"ykircclient";
    _client.user.mode = 0;
    _client.user.realName = @"realname";
    [_client connect];
    [_hostField resignFirstResponder];
}

- (IBAction)sendRawMessage:(id)sender
{
    NSString *rawText = _rawMessageField.text;
    [_client sendRawString:rawText tag:-1];
    _rawMessageField.text = nil;
    [_rawMessageField resignFirstResponder];
}

- (void)appendTextViewWithText:(NSString *)text
{
    _textView.text = [_textView.text stringByAppendingString:text];
}

#pragma mark - YKIRCClientDelegate

- (void)ircClientOnConnected:(YKIRCClient *)ircClient
{
    NSLog(@"Connected!");
}

- (void)ircClient:(YKIRCClient *)ircClient onUnknownResponse:(YKIRCMessage *)message
{
    [self appendTextViewWithText:message.rawMessage];
}

- (void)ircClient:(YKIRCClient *)ircClient onMessage:(YKIRCMessage *)message
{
    NSLog(@"message ---------");
    NSString *text;
    if (message.user.nick) {
        text = [NSString stringWithFormat:@"%@: %@\n", message.user.nick, message.trail];
        NSLog(@"nick: %@", message.user.nick);
    } else {
        text = [NSString stringWithFormat:@"%@: %@\n", message.sender, message.trail];
        NSLog(@"sender: %@", message.sender);
    }
    NSLog(@"receiver: %@", message.params[0]);
    NSLog(@"text: %@", message.trail);
    [self appendTextViewWithText:text];
}

- (void)ircClient:(YKIRCClient *)ircClient onNotice:(YKIRCMessage *)message
{
    NSLog(@"notice ---------");
    NSString *text;
    if (message.user.nick) {
        text = [NSString stringWithFormat:@"%@: %@\n", message.user.nick, message.trail];
        NSLog(@"nick: %@", message.user.nick);
    } else {
        text = [NSString stringWithFormat:@"%@: %@\n", message.sender, message.trail];
        NSLog(@"sender: %@", message.sender);
    }
    NSLog(@"receiver: %@", message.params[0]);
    NSLog(@"text: %@", message.trail);
    [self appendTextViewWithText:text];
}

- (void)ircClient:(YKIRCClient *)ircClient onJoin:(YKIRCMessage *)message
{
    NSLog(@"join ---------");
    NSString *text = [NSString stringWithFormat:@"%@ has joined to %@\n", message.user.nick, message.params[0]];
    [self appendTextViewWithText:text];
}

- (void)ircClient:(YKIRCClient *)ircClient onPart:(YKIRCMessage *)message
{
    NSLog(@"part ---------");
    NSString *text = [NSString stringWithFormat:@"%@ has left from %@ (%@)\n", message.user.nick, message.params[0], message.trail];
    [self appendTextViewWithText:text];
}

- (void)ircClient:(YKIRCClient *)ircClient onCommandResponse:(YKIRCMessage *)message
{
    NSLog(@"command ---------");
    NSLog(@"%@", message.rawMessage);
    if ([message.command isEqualToString:@"376"]) {
        NSString *text = [NSString stringWithFormat:@"%@\n", ircClient.serverReply.motd];
        [self appendTextViewWithText:text];
    } else {
        [self appendTextViewWithText:message.rawMessage];
    }
}

@end
