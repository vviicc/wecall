//
//  WCMoreWebPageViewController.m
//  WeCall
//
//  Created by Vic on 15-1-9.
//  Copyright (c) 2015年 feixiang. All rights reserved.
//

#import "WCMoreWebPageViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface WCMoreWebPageViewController ()<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *loadWebView;

@end

@implementation WCMoreWebPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.navigationItem.title = _webPageTitle;
    [_loadWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_loadURLString]]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    MBProgressHUD *hub = [MBProgressHUD HUDForView:self.view];
    hub.mode = MBProgressHUDModeText;
    hub.labelText = @"加载失败";
    [hub hide:YES afterDelay:2];
}

@end
