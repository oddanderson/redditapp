//
//  RAPostTableViewController.m
//  RedditApp
//
//  Created by Todd Anderson on 9/16/14.
//  Copyright (c) 2014 ToddAnderson. All rights reserved.
//

#import "RAPostTableViewController.h"
#import "RAConnectionHandler.h"
#import "RAPost.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "RASelfPostViewController.h"
#import "RAPostWebViewController.h"

@implementation RAPostTableViewController {
    NSArray *_posts;
    NSString *_lastPostID;
    BOOL _querying;
    BOOL _endOfContent;
    BOOL _refreshing;
    CGFloat _tableWidth;
    UIActivityIndicatorView *_indicatorView;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _posts = @[];
        self.title = @"Posts";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self getPostsAfterLast:nil];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor purpleColor];
    [refreshControl addTarget:self action:@selector(refreshPosts) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshPosts {
    _lastPostID = nil;
    _endOfContent = NO;
    _refreshing = YES;
    [RAConnectionHandler cancelAllRequests];
    [self getPostsAfterLast:nil];
}

- (void)getPostsAfterLast:(NSString *)lastPostID {
    if (_querying || _endOfContent) {
        return;
    }
    _querying = YES;
    if (!_refreshing) {
        if (!_indicatorView) {
            _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            _indicatorView.frame = CGRectMake(0, 0, 300, 50);
            _indicatorView.color = [UIColor purpleColor];
            self.tableView.tableFooterView = _indicatorView;
        }
        [_indicatorView startAnimating];
    }
    NSString *query = @".json";
    if (lastPostID) {
        query = [query stringByAppendingFormat:@"?after=%@", lastPostID];
    }
    [RAConnectionHandler getRequestWithURL:query
                                      data:nil
                                  callback:^(NSDictionary *result, NSError *error) {
                                      _querying = NO;
                                      if (!_refreshing) {
                                          [_indicatorView stopAnimating];
                                      }
                                      if (error) {
                                          [self _handleConnectionError:error];
                                      } else {
                                          dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                              [self _loadDataFromRequest:result];
                                          });
                                      }
                                  }];
}

- (void)_loadDataFromRequest:(NSDictionary *)result {
    if (![result[@"kind"] isEqualToString:@"Listing"]) {
        //should never happen...
        NSLog(@"Turn down for what?!");
    }
    NSDictionary *data = result[@"data"];
    NSArray *JSONposts = data[@"children"];
    NSMutableArray *newPosts = [NSMutableArray array];
    for (NSDictionary *JSONpost in JSONposts) {
        NSDictionary *newPost = JSONpost[@"data"];
        RAPost *post = [[RAPost alloc] initWithJSONDictionary:newPost];
        [newPosts addObject:post];
    }
    _lastPostID = data[@"after"];
    if ((id)_lastPostID == [NSNull null]) {
        _endOfContent = YES;
        _indicatorView = nil;
    }
    @synchronized(_posts) {
        if (_refreshing) {
            _posts = newPosts;
        } else {
            _posts = [_posts arrayByAddingObjectsFromArray:newPosts];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            if (_endOfContent) {
                UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
                UILabel *footerLabel = [[UILabel alloc] init];
                footerLabel.frame = view.bounds;
                footerLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
                footerLabel.textAlignment = NSTextAlignmentCenter;
                footerLabel.font = [UIFont boldSystemFontOfSize:20];
                footerLabel.text = @"No more posts";
                [view addSubview:footerLabel];
                self.tableView.tableFooterView = view;
            }
            if (_refreshing) {
                [self.refreshControl endRefreshing];
                _refreshing = NO;
            }
        });
    }
}

- (void)_handleConnectionError:(NSError *)error {
    NSDictionary *userInfo = error.userInfo;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:userInfo[@"title"]
                                                        message:userInfo[@"message"]
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Retry", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self getPostsAfterLast:_lastPostID];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _posts.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *PostIdentifier = @"Post";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PostIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:PostIdentifier];
    }
    RAPost *post = _posts[indexPath.row];
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.text = post.title;
    cell.detailTextLabel.text = [post.score stringValue];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:post.postID]) {
        cell.textLabel.textColor = cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    } else {
        cell.textLabel.textColor = cell.detailTextLabel.textColor = [UIColor blackColor];
    }
    if (post.thumbnail) {
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:post.thumbnail] placeholderImage:[UIImage imageNamed:@"loading.png"]];
    } else {
        cell.imageView.image = nil;
    }
    if ([post isEmpty]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > (_posts.count - 5)) {
        [self getPostsAfterLast:_lastPostID];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RAPost *post = _posts[indexPath.row];
    if (post.isSelfPost) {
        if (![post isEmpty]) {
            RASelfPostViewController *selfPostVC = [[RASelfPostViewController alloc] init];
            selfPostVC.textBody = post.textBody;
            selfPostVC.title = post.title;
            [self.navigationController pushViewController:selfPostVC animated:YES];
        } else {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            return;
        }
    } else {
        RAPostWebViewController *webVC = [[RAPostWebViewController alloc] init];
        webVC.url = post.url;
        webVC.title = post.title;
        [self.navigationController pushViewController:webVC animated:YES];
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:post.postID];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self performSelector:@selector(reloadRow:) withObject:indexPath afterDelay:.1];
}

- (void)reloadRow:(NSIndexPath *)row {
    [self.tableView reloadRowsAtIndexPaths:@[row] withRowAnimation:UITableViewRowAnimationAutomatic];
}



@end
