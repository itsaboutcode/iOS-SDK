
# Singly SDK

A simple SDK for accessing Singly from iOS apps.

The Singly SDK is currently **in active development** and as such should be
considered alpha quality. We are very interested in feedback from the community
about the direction you would like to see us take with it. Please follow with us
as we push towards our [1.0 milestone](https://github.com/Singly/iOS-SDK/issues?milestone=4&state=open).

--------------------------------------------------------------------------------

## Getting Started

The first thing you will need is a client id and client secret for your
application. If you have not done so already, [sign in](https://singly.com/apps)
to Singly and add your application. Your client id and secret can be found on
the [application settings](https://singly.com/apps) page for your application.

Now that we're ready we can either start a new iOS application or use an existing one.
In order to use the SDK make sure that you setup your header search path to point to the
`SinglySDK` directory and that your project includes the libSinglySDK.a library.

To start using the SDK we'll first need a `SinglySession` object.  You'll probably
want to maintain this in your AppDelegate or root view controller.  You'll also need to
assign a delegate to it that implements the `SinglySessionDelegate` protocol.  You will
also assign the client id and secret you generated while signing up for Singly.

```objective-c
SinglySession* session = [[SinglySession alloc] init];
session.clientID = @"<client id here>";
session.clientSecret = @"<client secret here>";
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
[self presentModalViewController:loginVC animated:YES];
```

The service that you define can be any string of the services that Singly supports,
but we have these defined as constants for you in the SinglySDK.h.

An example implementation of the `SinglySessionDelegate` is:

```objective-c
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

If you wish to login multiple services, or offer multiple services for login, then you
can use the `SinglyLoginPickerViewController`.  All you need to do is set all of th
services that you wish to allow connections to.

```
SinglyLoginPickerViewController* controller = [[SinglyLoginPickerViewController alloc] initWithSession:session];
controller.services = [NSArray arrayWithObjects:kSinglyServiceFacebook, kSinglyServiceTwitter, nil];
[self presentModalViewController:controller animated:YES];
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

--------------------------------------------------------------------------------

## Example App

--------------------------------------------------------------------------------

## Other View Controllers

A few helpful view controllers exist to make life easier and get apps built faster.

* `SinglyLoginViewPickerController`

    As discussed above this is a view controller to give a list of available services
    for the user to login to.

* `SinglyFriendPickerViewController`

   A view of a users contacts that allows them to pick one.

* `SinglySharingViewController`

    A view to post a status message out to a network.

More docs to come for these.

--------------------------------------------------------------------------------

## Native Facebook Authorization

Singly SDK wraps the Facebook SDK and supports native authorization (on iOS 6+)
along with fallbacks to both the Facebook app and traditional web-based
authentication. Although we abstract the Facebook SDK away, there are still a
few steps you must take to ensure support for native authorization:

 * Configure your app to respond to Facebook URLs.

--------------------------------------------------------------------------------

## License

The Singly SDK is licensed under the terms of the BSD License. Please see the
LICENSE file for more information.

