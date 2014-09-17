//
//  RAConnectionHandler.h
//  RedditApp
//
//  Created by Todd Anderson on 4/29/14.
//  Copyright (c) 2014 Todd Anderson. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RAConnectionCallback)(NSDictionary *result, NSError *error);

@interface RAConnectionHandler : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *defaultSession;
@property (nonatomic, strong) NSMutableDictionary *completionHandlerDictionary;


+ (RAConnectionHandler *)connectionHandler;
+ (BOOL) getRequestWithURL:(NSString *)URLString data:(NSData *)data callback:(RAConnectionCallback)callback;
+ (void) postRequestWithURL:(NSString *)URLString data:(NSData *)data callback:(RAConnectionCallback)callback;
+ (void) cancelAllRequests;

@end

