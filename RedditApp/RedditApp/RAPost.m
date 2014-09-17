//
//  RAPost.m
//  RedditApp
//
//  Created by Todd Anderson on 9/16/14.
//  Copyright (c) 2014 ToddAnderson. All rights reserved.
//

#import "RAPost.h"

@implementation RAPost

- (id)initWithJSONDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _title = dictionary[@"title"];
        _score = dictionary[@"score"];
        _numberOfComments = dictionary[@"num_comments"];
        NSString *thumbnail = dictionary[@"thumbnail"];

        if (thumbnail.length && (id)thumbnail != [NSNull null] && [thumbnail rangeOfString:@"jpg"].location != NSNotFound) {
            _thumbnail = thumbnail;
        }
        _selfPost = [dictionary[@"is_self"] boolValue];
        if (_selfPost) {
            _textBody = dictionary[@"selftext"];
        } else {
            NSString *urlString = dictionary[@"url"];
            _url = [NSURL URLWithString:urlString];
        }
        _postID = dictionary[@"id"];
    }
    return self;
}

- (BOOL)isEmpty {
    if (_selfPost) {
        return _textBody.length == 0;
    }
    return NO;
}

@end
