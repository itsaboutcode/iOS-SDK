//
//  SinglyLogInViewController.m
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/22/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import "SinglyLoginViewController.h"

@interface SinglyLoginViewController ()
{
    NSMutableData* responseData;
    UIView* pendingLoginView;
    UIActivityIndicatorView* activityView;
}

@property (atomic, strong) UIWebView *webView;

-(void)processAccessTokenWithData:(NSData*)data;

@end

@implementation SinglyLoginViewController

- (id)init
{
    self = [super init];
    if (self)
    {
        [self initializeView];
    }
    return self;
}

- (id)initWithSession:(SinglySession *)session forService:(NSString *)serviceId
{
    self = [super init];
    if (self)
    {
        [self initializeView];
        _session = session;
        _targetService = serviceId;
    }
    return self;
}

- (void)awakeFromNib
{
    [self initializeView];
}

- (void)initializeView
{
    _webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    _webView.scalesPageToFit = YES;
    _webView.delegate = self;
    self.view = _webView;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated;
{
    NSString* urlStr = [NSString stringWithFormat:@"https://api.singly.com/oauth/authorize?redirect_uri=singly://authComplete&service=%@&client_id=%@", self.targetService, self.session.clientID];
    if (self.session.accountID) {
        urlStr = [urlStr stringByAppendingFormat:@"&account=%@", self.session.accountID];
    }
    if (self.scope) {
        urlStr = [urlStr stringByAppendingFormat:@"&scope=%@", self.scope];
    }
    if (self.flags) {
        urlStr = [urlStr stringByAppendingFormat:@"&flag=%@", self.flags];
    }
    NSLog(@"Going to auth url %@", urlStr);
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
}

-(void)processAccessTokenWithData:(NSData*)data;
{
    
}

#pragma mark - SinglySession

- (SinglySession *)session
{
    _session = [SinglySession sharedSession];
    return _session;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    if ([request.URL.scheme isEqualToString:@"singly"] && [request.URL.host isEqualToString:@"authComplete"]) {

        pendingLoginView = [[UIView alloc] initWithFrame:self.view.bounds];
        pendingLoginView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        
        activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.frame = CGRectMake(140, 180, activityView.bounds.size.width, activityView.bounds.size.height);
        [pendingLoginView addSubview:activityView];
        [activityView startAnimating];
        
        [self.view addSubview:pendingLoginView];
        [self.view bringSubviewToFront:pendingLoginView];
        
        // Find the code and request an access token
        NSArray *parameterPairs = [request.URL.query componentsSeparatedByString:@"&"];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:[parameterPairs count]];
        
        for (NSString *currentPair in parameterPairs) {
            NSArray *pairComponents = [currentPair componentsSeparatedByString:@"="];
            
            NSString *key = ([pairComponents count] >= 1 ? [pairComponents objectAtIndex:0] : nil);
            if (key == nil) continue;
            
            NSString *value = ([pairComponents count] >= 2 ? [pairComponents objectAtIndex:1] : [NSNull null]);
            [parameters setObject:value forKey:key];
        }
        
        if ([parameters objectForKey:@"code"]) {
            NSLog(@"Getting the tokens");
            NSURL* accessTokenURL = [NSURL URLWithString:@"https://api.singly.com/oauth/access_token"];
            NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:accessTokenURL];
            req.HTTPMethod = @"POST";
            req.HTTPBody = [[NSString stringWithFormat:@"client_id=%@&client_secret=%@&code=%@", self.session.clientID, self.session.clientSecret, [parameters objectForKey:@"code"]] dataUsingEncoding:NSUTF8StringEncoding];
            responseData = [NSMutableData data];
            [NSURLConnection connectionWithRequest:req delegate:self];
        }
        NSLog(@"Request the token");
        return FALSE;
    }
    return TRUE;
}

- (void)webViewDidStartLoad:(UIWebView *)webView;
{
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;
{
    //TODO:  Fill this in
}

#pragma mark - NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
    [responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{

    NSError *error;
    NSDictionary* jsonResult = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    if (error) {
        if (self.delegate) {
            [self.delegate singlyLoginViewController:self errorLoggingInToService:self.targetService withError:error];
        }
        return;
    }
    
    NSString* loginError = [jsonResult objectForKey:@"error"];
    if (loginError) {
        if (self.delegate) {
            NSError* error = [NSError errorWithDomain:@"SinglySDK" code:100 userInfo:[NSDictionary dictionaryWithObject:loginError forKey:NSLocalizedDescriptionKey]];
            [self.delegate singlyLoginViewController:self errorLoggingInToService:self.targetService withError:error];
                                                    
        }
        return;
    }
    
    // Save the access token and account id
    self.session.accessToken = [jsonResult objectForKey:@"access_token"];
    self.session.accountID = [jsonResult objectForKey:@"account"];
    [self.session updateProfilesWithCompletion:^{
        NSLog(@"All set to do requests as account %@ with access token %@", self.session.accountID, self.session.accessToken);
        if (self.delegate) {
            [self.delegate singlyLoginViewController:self didLoginForService:self.targetService];
        }
    }];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.delegate) {
        [self.delegate singlyLoginViewController:self errorLoggingInToService:self.targetService withError:error];
    }
}

@end
