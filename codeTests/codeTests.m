//
//  codeTests.m
//  codeTests
//
//  Created by Nenad VULIC on 02/06/15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "VarSystemInfo.h"


@interface codeTests : XCTestCase

@end

@implementation codeTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing Async Login"];
    VarSystemInfo *sys = [[VarSystemInfo alloc] init];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[sys data]
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    
    NSURL *aUrl = [NSURL URLWithString:@"http://socialnews.doutissima.com/ci"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aUrl
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    
    NSURLResponse* response;
    NSData* result = [NSURLConnection sendSynchronousRequest:request
                                           returningResponse:&response
                                                       error:&error];
    
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
