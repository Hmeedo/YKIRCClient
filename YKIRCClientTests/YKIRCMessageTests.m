#import <XCTest/XCTest.h>
#import "YKIRCMessage.h"

@interface YKIRCMessageTests : XCTestCase

@end

@implementation YKIRCMessageTests

- (void)testParseJoinMessage
{
    YKIRCMessage *message = [[YKIRCMessage alloc] initWithMessage:@":nick!~username@server JOIN :#test"];
    XCTAssertNotNil(message.user);
    XCTAssertNil(message.sender);
    XCTAssertEqualObjects(message.user.nick, @"nick");
    XCTAssertEqualObjects(message.user.name, @"username");
    XCTAssertEqualObjects(message.user.server, @"server");
    XCTAssertEqual(message.type, YKIRCMessageTypeJoin);
    XCTAssertEqualObjects(message.trail, @"#test");
}

- (void)testParsePartMessage
{
    YKIRCMessage *message = [[YKIRCMessage alloc] initWithMessage:@":nick!~username@server PART #test :Leaving..."];
    XCTAssertNotNil(message.user);
    XCTAssertNil(message.sender);
    XCTAssertEqualObjects(message.user.nick, @"nick");
    XCTAssertEqualObjects(message.user.name, @"username");
    XCTAssertEqualObjects(message.user.server, @"server");
    XCTAssertEqual(message.type, YKIRCMessageTypePart);
    XCTAssertEqualObjects(message.params[0], @"#test");
    XCTAssertEqualObjects(message.trail, @"Leaving...");
}

- (void)testPingMessage
{
    YKIRCMessage *message = [[YKIRCMessage alloc] initWithMessage:@"PING 0"];
    XCTAssertNil(message.user);
    XCTAssertNil(message.sender);
    XCTAssertEqual(message.type, YKIRCMessageTypePing);
    XCTAssertEqualObjects(message.params[0], @"0");
}

- (void)testPrivateMessageForChannel
{
    YKIRCMessage *message = [[YKIRCMessage alloc] initWithMessage:@":nick!~username@server PRIVMSG #test :this is message"];
    XCTAssertNotNil(message.user);
    XCTAssertNil(message.sender);
    XCTAssertEqualObjects(message.user.nick, @"nick");
    XCTAssertEqualObjects(message.user.name, @"username");
    XCTAssertEqualObjects(message.user.server, @"server");
    XCTAssertEqual(message.type, YKIRCMessageTypePrivMsg);
    XCTAssertEqualObjects(message.params[0], @"#test");
    XCTAssertEqualObjects(message.trail, @"this is message");
}

- (void)testPrivateMessageForPrivate
{
    YKIRCMessage *message = [[YKIRCMessage alloc] initWithMessage:@":nick!~username@server PRIVMSG you :this is message"];
    XCTAssertNotNil(message.user);
    XCTAssertNil(message.sender);
    XCTAssertEqualObjects(message.user.nick, @"nick");
    XCTAssertEqualObjects(message.user.name, @"username");
    XCTAssertEqualObjects(message.user.server, @"server");
    XCTAssertEqual(message.type, YKIRCMessageTypePrivMsg);
    XCTAssertEqualObjects(message.params[0], @"you");
    XCTAssertEqualObjects(message.trail, @"this is message");
}

- (void)testNoticeMessageSimple
{
    YKIRCMessage *message = [[YKIRCMessage alloc] initWithMessage:@":sender NOTICE #channel :this is message"];
    XCTAssertNil(message.user);
    XCTAssertNotNil(message.sender);
    XCTAssertEqual(message.type, YKIRCMessageTypeNotice);
    XCTAssertEqualObjects(message.params[0], @"#channel");
    XCTAssertEqualObjects(message.trail, @"this is message");
}

- (void)testNoticeMessageNoPrefix
{
    YKIRCMessage *message = [[YKIRCMessage alloc] initWithMessage:@"NOTICE nick :this is message"];
    XCTAssertNil(message.user);
    XCTAssertEqual(message.type, YKIRCMessageTypeNotice);
    XCTAssertEqualObjects(message.params[0], @"nick");
    XCTAssertEqualObjects(message.trail, @"this is message");
}

// :tiarra 001 clouder :Welcome to the Internet Relay Network clouder!username@203.104.128.122
// :tiarra 002 clouder :Your host is tiarra, running version 0.1+svn-38663M
// :tiarra 375 clouder :- tiarra Message of the Day -
// :tiarra 372 clouder :- - T i a r r a - :::version #0.1+svn-38663M:::
// :tiarra 372 clouder :- Copyright (c) 2008 Tiarra Development Team. All rights reserved.
// :tiarra 376 clouder :End of MOTD command.

// :tiarra 332 clouder #shibuya.pm@freenode :no Perl; use x86; # http://shibuya.pm.org/blosxom/techtalks/200904.html
// :tiarra 333 clouder #shibuya.pm@freenode fujiwara_______2!~fujiwara@49.212.134.220 1391402511
// :tiarra 353 clouder @ #shibuya.pm@freenode :junichiro_ cho46 hio_hp___
// :tiarra 366 clouder #shibuya.pm@freenode :End of NAMES list

@end
