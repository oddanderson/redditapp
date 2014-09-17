//
//  RAPostWebViewController.m
//  RedditApp
//
//  Created by Todd Anderson on 9/16/14.
//  Copyright (c) 2014 ToddAnderson. All rights reserved.
//

#import "RAPostWebViewController.h"

@interface RAPostWebViewController ()

@end

@implementation RAPostWebViewController

- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{
    UIWebView *webView = [[UIWebView alloc] init];
    self.view = webView;
    NSURLRequest *request = [NSURLRequest requestWithURL:_url];
    [webView loadRequest:request];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
