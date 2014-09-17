//
//  RAPost.h
//  RedditApp
//
//  Created by Todd Anderson on 9/16/14.
//  Copyright (c) 2014 ToddAnderson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RAPost : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) NSNumber *score;
@property (nonatomic) NSNumber *numberOfComments;
@property (nonatomic) NSString *thumbnail;
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *textBody;
@property (nonatomic, getter = isSelfPost) BOOL selfPost;
@property (nonatomic) NSString *postID;

- (id)initWithJSONDictionary:(NSDictionary *)dictionary;
- (BOOL)isEmpty;

@end
