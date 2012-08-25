# Singly SDK #

A simple iOS SDK for accessing Singly.

## Getting Started ##

The first thing you should do is [register an application](https://singly.com/apps) at Singly.  In your
application settings you need to get your client id and client secret.  We'll need
to put this into our new program for logging in.

Now that we're ready we can either start a new iOS application or use an existing one.
In order to use the SDK make sure that you setup your header search path to point to the
`SinglySDK` directory and that your project includes the libSinglySDK.a library.

To start using the SDK we'll first need a `SinglySession` object.  You'll probably
want to maintain this in your AppDelegate or root view controller.  You'll also need to
assign a delegate to it that implements the `SinglySessionDelegate` protocol.

```objective-c
SinglySession* session = [[SinglySession alloc] init];
session.delegate = self;
```

The `SinglySession` has two other properties:
* `accessToken` - Your Singly access token.  You should not need to access this unless
  you really need to do something that does not fit into the current SDK.
* `accountID` - Your Singly account ID.

Both of these are saved between runs in the `NSUserDefaults` and should be setup using
a `SinglyLoginViewController`.  To see if the session was stored and immediately 
usable, without loggin in again.  We can use the `checkReadyWithCompletionHandler:`.

```objective-c
[session checkReadyWithCompletionHandler:^(BOOL ready){
    if(!ready) {
        // We're not logged in and we should use SinglyLoginViewController to connect
    } else {
        // We're all set and can start making requests
    }
}];
```

If the session is not ready, or needs to connect a different service, the 
`SinglyLoginViewController` gives you a consistent and simple way to connect to
any of the services that Singly supports.  This is a fully standard
`UIViewController` with the extra bits needed to do the Singly auth.  When it
finishes or errors it uses the `SinglySessionDelegate` to fire the correct events.

```objective-c
SinglyLoginViewController* loginVC = [[SinglyLogInViewController alloc] initWithSession:session_ forService:kSinglyServiceFacebook];
loginVC.clientID = @"<client id here>";
loginVC.clientSecret = @"<client secret here>";
[self presentModalViewController:loginVC animated:YES];
```

The service that you define can be any string of the services that Singly supports,
but we have these defined as constants for you in the SinglySDK.h.

An example implementation of the `SinglySessionDelegate` is:

```objective-c
#pragma mark - SinglySessionDelegate
-(void)singlySession:(SinglySession *)session didLogInForService:(NSString *)service;
{
    [self dismissModalViewControllerAnimated:YES];
    loginVC = nil;
    
    // We're ready to rock!  Go do something amazing!
}
-(void)singlySession:(SinglySession *)session errorLoggingInToService:(NSString *)service withError:(NSError *)error;
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [self dismissModalViewControllerAnimated:YES];
    loginVC = nil;
}
```

Once we have a valid session we can start making API requests.  We can make
GET, POST or any method requests using the `SinglyAPIRequest`.  The request is only
a description of the request that we are going to make, to actually execute the 
request we use our session and one of the `requestAPI:` methods.  An example
that requests the profiles list and is using blocks to handle the result is:

```objective-c
[session requestAPI:[SinglyAPIRequest apiRequestForEndpoint:@"profiles" withParameters:nil] withCompletionHandler:^(NSError *error, id json) {
    NSLog(@"The profiles result is: %@", json);
}];
```

That's the basics and enough to get rolling!

