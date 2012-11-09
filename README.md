
# Singly iOS SDK

A simple SDK for accessing Singly from iOS apps.

**The Singly SDK is currently in active development** and as such should be
considered alpha quality at this stage. We are very interested in feedback
from the community about the direction you would like to see us take with it.
Please follow with us as we push towards our
[1.0 milestone](https://github.com/Singly/iOS-SDK/issues?milestone=4&state=open).

## Getting Started

The first thing you will need is a Client ID and a Client Secret for your
application from Singly. If you have not done so already, add your application
by [signing in to Singly](https://singly.com/apps). Your Client ID and Client
Secret can be found on the application settings page for your application.

Once you have your Client ID and Client Secret, we can either start a new iOS
application or use an existing one.

### Linking to the Singly SDK

### Opening a Session to Singly

To start using the Singly SDK in your project, you will first need to
initialize the `SinglySession`. You'll probably want to do this in your
application delegate right after the application has finished launching, such
as in the `application:didFinishLaunchingWithOptions:launchOptions` method.

```objective-c
SinglySession *session = [SinglySession sharedSession];
session.clientID = CLIENT_ID;
session.clientSecret = CLIENT_SECRET;

[session startSessionWithCompletionHandler:^(BOOL ready) {
    if (ready) {
        // The session is ready to go!
    } else {
        // You will need to auth with a service...
    }
}];
```

The `SinglySession` has two other properties:

  * `accessToken` - Your Singly Access Token. You should not need to access
    this unless you really need to do something that does not fit into the
    current Singly SDK.
  * `accountID` - Your Singly Account ID.

Both of these are saved between runs in the `NSUserDefaults` and should be
setup using `SinglyService` or a `SinglyLoginViewController` instance.

### Using the Singly Login View Controller

```objective-c
SinglyLoginViewController *loginViewController = [[SinglyLogInViewController alloc]
    initWithSession:[SinglySession sharedSession]
         forService:kSinglyServiceFacebook];

[self presentModalViewController:loginViewController animated:YES];
```

The service that you define can be any string of the services that Singly supports,
but we have these defined as constants for you in the SinglyConstants.h.

An example implementation of the `SinglySessionDelegate` is:

```objective-c
- (void)singlySession:(SinglySession *)session didLogInForService:(NSString *)service
{
    [self dismissModalViewControllerAnimated:YES];

    // We're ready to rock!  Go do something amazing!
}

- (void)singlySession:(SinglySession *)session errorLoggingInToService:(NSString *)service withError:(NSError *)error
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [self dismissModalViewControllerAnimated:YES];
}
```

### Using the Singly Login Picker

If you wish to login multiple services, or offer multiple services for login,
then you can use the `SinglyLoginPickerViewController`.

```
SinglyLoginPickerViewController *pickerViewController = [[SinglyLoginPickerViewController alloc]
    initWithSession:[SinglySession sharedSession]];
[self presentModalViewController:pickerViewController animated:YES];
```

### Making API Requests

Once we have a valid session we can start making API requests.  We can make
GET, POST or any method requests using the `SinglyAPIRequest`.  The request is
only a description of the request that we are going to make, to actually
execute the request we use our session and one of the `requestAPI:` methods.
An example that requests the profiles list and is using blocks to handle the
result is:

```objective-c
[[SinglySession sharedSession] requestAPI:[SinglyAPIRequest apiRequestForEndpoint:@"profiles" withParameters:nil] withCompletionHandler:^(NSError *error, id json) {
    NSLog(@"The profiles result is: %@", json);
}];
```

That's the basics and enough to get rolling!

## Building the Example App

Singly SDK ships with an example app that illustrates all of the capabilities
of the SDK.

### Configure the Example App

Before you can build and run the example app, you will need to provide your
Client ID and Client Secret in `SinglyConfiguration.h`.

### Enable Native Facebook Authorization (optional)

See the instructions below (under "Native Facebook Authorization") to enable
testing of the Facebook application fallback attempt.

### Build and Run!

Once you have things configured, simply build and run the project in the
Simulator.

If you wish to run the example on your iPhone or iPad, you will need to
configure the project with provisioning appropriate to your device and Apple
developer account, which is beyond the scope of this document.

## SDK Documentation

After you've cloned the project, you will find generated documentation in
the `SinglySDK/Documentation` folder. This documentation is automatically
regenerated with each successful build of the framework in Xcode, provided
you have (appledoc)[http://gentlebytes.com/appledoc/] installed.

## Native Facebook Authorization

Singly SDK interfaces directly with the device to support authorization on
iOS 6+ and will attempt to fallback to the installed Facebook application and
then the built-in Singly web-based authorization. In order for the Facebook
application fallback to work, you will need to perform the following steps:

### Register your app to handle Facebook URLs

You must add the following to your Info.plist, replacing the 0's with your
actual Facebook App ID:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fb000000000000000</string>
        </array>
    </dict>
</array>
```

### Configure your app delegate to handle launches by URL

When native integration is not possible, we fall back to launching the
Facebook app (if installed) in order to complete the auth workflow. In order
for this to happen, you will need your application delegate to implement the
following method in order for the round-trip process to complete:

```objective-c
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  return [[SinglySession sharedSession] handleOpenURL:url];
}
```

## Need Help?

We are available to answer your questions, help you work through integration
issues and look into possible bugs with our service and SDKs.

  * **Found a bug?**
    If you think you have come across a bug in the SDK, please take a moment
    to [file an issue](https://github.com/singly/ios-sdk/issues), providing as
    much information about the issue as possible.

  * **Join us on HipChat.**
    For questions or just to say hi and show off what you're building, feel
    free to join us on our [Support HipChat](https://support.singly.com) and
    have a word with us!

## License

The Singly SDK is licensed under the terms of the BSD License. Please see the
[LICENSE](http://github.com/singly/ios-sdk/blob/master/LICENSE) file for more
information.
