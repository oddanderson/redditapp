//
//  RAConnectionHandler.m
//  RedditApp
//
//  Created by Todd Anderson on 4/29/14.
//  Copyright (c) 2014 Todd Anderson. All rights reserved.
//

#import "RAConnectionHandler.h"

static NSString *baseURL = @"http://reddit.com/";

@interface RAConnectionHandler ()

@end

@implementation RAConnectionHandler

+ (RAConnectionHandler *) connectionHandler {
    static RAConnectionHandler *connection = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        connection = [[self alloc] init];
    });
    return connection;
}

- (id) init {
    self = [super init];
    if (self) {
        [self _configureSession];
    }
    return self;
}

- (void)_configureSession {
    
    self.completionHandlerDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    [defaultConfigObject setHTTPAdditionalHeaders:headers];
    
    NSString *cachePath = @"/MyCacheDirectory";
    
    
    NSURLCache *myCache = [[NSURLCache alloc] initWithMemoryCapacity: 16384 diskCapacity: 268435456 diskPath: cachePath];
    defaultConfigObject.URLCache = myCache;
    defaultConfigObject.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    defaultConfigObject.HTTPMaximumConnectionsPerHost = 10;
    
    /* Create a session for each configurations. */
    self.defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                        delegate:self
                                                   delegateQueue:[NSOperationQueue mainQueue]];
}

- (void)handleResponseData:(NSData *)data urlResponse:(NSURLResponse *)response error:(NSError *)error callback:(RAConnectionCallback)callback {
    
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
    NSInteger statusCode = [HTTPResponse statusCode];
    NSLog(@"-----------------------------------------------");
    NSLog(@"Response %@ with error %@.\n", response, error);
    NSError *myError = nil;
    NSDictionary *result;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (statusCode != 200) {
        myError = [NSError errorWithDomain:@"http"
                                      code:0
                                  userInfo:@{@"title" : @"Connection Error",
                                             @"message" : @"There was a problem connecting to the server, please try again."}];
    } else {
        NSLog(@"Response Data:\n%@\n",
              [[NSString alloc] initWithData: data
                                    encoding: NSUTF8StringEncoding]);
        ;
        result = [NSJSONSerialization JSONObjectWithData:data
                                                 options:NSJSONReadingMutableLeaves
                                                   error:&myError];
    }
    callback(result, myError);
    NSLog(@"-----------------------------------------------");
}

+ (BOOL)getRequestWithURL:(NSString *)URLString data:(NSData *)data callback:(RAConnectionCallback)callback {
    
    RAConnectionHandler *connection = [RAConnectionHandler connectionHandler];
    [connection getRequestWithURL:URLString data:data callback:callback];
    return YES;
}

- (void)getRequestWithURL:(NSString *)URLString data:(NSData *)data callback:(RAConnectionCallback)callback {
    NSString *finalURLString = [NSString stringWithFormat:@"%@%@", baseURL, URLString];
    if (!data) {
        data = [NSData data];
    }
    NSURL *myURL = [NSURL URLWithString:finalURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:myURL];
    NSLog(@"Send get request to %@ with DATA:\n%@\nEND DATA\n",
          finalURLString,
          [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[self.defaultSession uploadTaskWithRequest:request
                                             fromData:data
                                    completionHandler:^(NSData *data, NSURLResponse *response,
                                                        NSError *error) {
                                        [self handleResponseData:data urlResponse:response error:error callback:callback];
                                    }] resume];
}

+ (void)postRequestWithURL:(NSString *)URLString data:(NSData *)data callback:(RAConnectionCallback)callback {
    NSString *finalURLString = [NSString stringWithFormat:@"%@%@", baseURL, URLString];
    RAConnectionHandler *connection = [RAConnectionHandler connectionHandler];
    
    NSURL *myURL = [NSURL URLWithString:finalURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:myURL];
    NSLog(@"Send post request with DATA:\n%@\nEND DATA\n",
          [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:data];
    [[connection.defaultSession dataTaskWithRequest:request
                                  completionHandler:^(NSData *data, NSURLResponse *response,
                                                      NSError *error) {
                                      [connection handleResponseData:data urlResponse:response error:error callback:callback];
                                  }] resume];

}

+ (void)cancelAllRequests {
    RAConnectionHandler *connection = [RAConnectionHandler connectionHandler];
    [connection.defaultSession invalidateAndCancel];
    [connection _configureSession];
}


@end
