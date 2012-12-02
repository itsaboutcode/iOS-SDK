//
//  SinglyLoginViewController.m
//  SinglySDK
//
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "UIViewController+Modal.h"

#import "SinglyConstants.h"
#import "SinglyLoginViewController.h"
#import "SinglyLoginViewController+Internal.h"
#import "SinglyService+Internal.h"

@implementation SinglyLoginViewController

- (id)initWithServiceIdentifier:(NSString *)serviceIdentifier
{
    self = [super init];
    if (self)
    {
        _serviceIdentifier = [SinglyService normalizeServiceIdentifier:serviceIdentifier];
    }
    return self;
}

- (void)setServiceIdentifier:(NSString *)serviceIdentifier
{
    _serviceIdentifier = [SinglyService normalizeServiceIdentifier:serviceIdentifier];
}

#pragma mark - View Callbacks

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.isModal)
    {
        self.webView.frame = CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height - 44);
        self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:self.serviceIdentifier];
        navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
        self.navigationBar.items = @[navigationItem];

        //
        // Set the tint color of our navigation bar to match the tint of the
        // view controller's navigation bar that is responsible for presenting
        // us modally.
        //
        if ([self.presentingViewController respondsToSelector:@selector(navigationBar)])
        {
            UIColor *presentingTintColor = ((UINavigationController *)self.presentingViewController).navigationBar.tintColor;
            self.navigationBar.tintColor = presentingTintColor;
        }

        [self.view addSubview:self.navigationBar];
    }
    else
    {
        if (self.navigationBar)
        {
            [self.navigationBar removeFromSuperview];
            self.navigationBar = nil;
        }
    }

    NSString *urlStr = [kSinglyAuthenticateURL stringByAppendingFormat:@"?redirect_uri=fb%@://authorize&service=%@&client_id=%@",
                        SinglySession.sharedSession.clientID, self.serviceIdentifier, SinglySession.sharedSession.clientID];

    if (SinglySession.sharedSession.accountID)
        urlStr = [urlStr stringByAppendingFormat:@"&account=%@", SinglySession.sharedSession.accountID];
    else
        urlStr = [urlStr stringByAppendingString:@"&account=false"];

    if (self.scopes)
    {
        NSString *scopes = [self.scopes componentsJoinedByString:@","];
        urlStr = [urlStr stringByAppendingFormat:@"&scope=%@", scopes];
    }

    if (self.flags)
        urlStr = [urlStr stringByAppendingFormat:@"&flag=%@", self.flags];

    NSLog(@"[SinglySDK:SinglyLoginViewController] Going to URL: %@", urlStr);

    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
}

#pragma mark - Web View Delegates

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.scheme isEqualToString:[NSString stringWithFormat:@"fb%@", SinglySession.sharedSession.clientID]] && [request.URL.host isEqualToString:@"authorize"])
    {

        self.pendingLoginView = [[UIView alloc] initWithFrame:self.view.bounds];
        self.pendingLoginView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        
        self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityView.frame = CGRectMake(140, 180, self.activityView.bounds.size.width, self.activityView.bounds.size.height);
        [self.pendingLoginView addSubview:self.activityView];
        [self.activityView startAnimating];
        
        [self.view addSubview:self.pendingLoginView];
        [self.view bringSubviewToFront:self.pendingLoginView];
        
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
            NSURL* accessTokenURL = [NSURL URLWithString:kSinglyAccessTokenURL];
            NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:accessTokenURL];
            req.HTTPMethod = @"POST";
            req.HTTPBody = [[NSString stringWithFormat:@"client_id=%@&client_secret=%@&code=%@", SinglySession.sharedSession.clientID, SinglySession.sharedSession.clientSecret, [parameters objectForKey:@"code"]] dataUsingEncoding:NSUTF8StringEncoding];
            self.responseData = [NSMutableData data];
            [NSURLConnection connectionWithRequest:req delegate:self];
        }
        NSLog(@"Request the token");
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{

}

#pragma mark - URL Connection Delegates

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{

    NSError *error;
    NSDictionary *jsonResult = [NSJSONSerialization JSONObjectWithData:self.responseData options:kNilOptions error:&error];
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(singlyLoginViewController:didLoginForService:)])
            [self.delegate singlyLoginViewController:self errorLoggingInToService:self.serviceIdentifier withError:error];
        return;
    }
    
    NSString *loginError = [jsonResult objectForKey:@"error"];
    if (loginError)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(singlyLoginViewController:errorLoggingInToService:withError:)])
        {
            NSError* error = [NSError errorWithDomain:@"SinglySDK" code:100 userInfo:[NSDictionary dictionaryWithObject:loginError forKey:NSLocalizedDescriptionKey]];
            [self.delegate singlyLoginViewController:self errorLoggingInToService:self.serviceIdentifier withError:error];
        }
        return;
    }

    // Save the access token and account id
    SinglySession.sharedSession.accessToken = [jsonResult objectForKey:@"access_token"];
    SinglySession.sharedSession.accountID = [jsonResult objectForKey:@"account"];
    [SinglySession.sharedSession updateProfilesWithCompletion:^(BOOL success)
    {
        NSLog(@"All set to do requests as account %@ with access token %@", SinglySession.sharedSession.accountID, SinglySession.sharedSession.accessToken);
        if (self.delegate && [self.delegate respondsToSelector:@selector(singlyLoginViewController:didLoginForService:)])
            [self.delegate singlyLoginViewController:self didLoginForService:self.serviceIdentifier];
    }];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(singlyLoginViewController:errorLoggingInToService:withError:)])
        [self.delegate singlyLoginViewController:self errorLoggingInToService:self.serviceIdentifier withError:error];
}

#pragma mark -

- (void)dismiss
{
  [self dismissModalViewControllerAnimated:YES];
}

@end
