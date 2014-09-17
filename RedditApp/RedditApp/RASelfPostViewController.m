//
//  RASelfPostViewController.m
//  RedditApp
//
//  Created by Todd Anderson on 9/16/14.
//  Copyright (c) 2014 ToddAnderson. All rights reserved.
//

#import "RASelfPostViewController.h"

@implementation RASelfPostViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.title = @"Post";
    }
    return self;
}

- (void)loadView {
    UITextView *textView = [[UITextView alloc] init];
    textView.editable = NO;
    textView.text = _textBody;
    self.view = textView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
