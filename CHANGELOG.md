
# Singly SDK ChangeLog

## 1.1.3 — **Not Yet Released**

* Updated project settings for Xcode 4.6 and fixed additional code warnings that
  it exposed.

## 1.1.2 — January 25th, 2013

* Fixed a GCD memory management issue that was causing compilation failures for
  applications that are targeted for iOS 6.

* Modernized some deprecated calls for iOS 6.

## 1.1.1 — January 23rd, 2013

* Fixed an issue where delegate methods were not being called after successful
  (or failed) logins attempts with the login view controller.

## 1.1.0 — January 17th, 2013

* The method `startSessionWithCompletionHandler:` on `SinglySession` is now
  deprecated. Please use `startSessionWithCompletion:` instead.

* You may now disconnect from services by calling `disconnect` or
  `disconnectWithCompletion:` on instances SinglyService. This was previously
  only possible through the use of `SinglyLoginPickerViewController`.

* Auth tokens for services are now available in the `profiles` property on
  `SinglySession`.

* The simplified profile is now fetched in place of the profiles endpoint and
  is accessible with the `profile` property on `SinglySession`.

* Device contacts may now be synced with the Singly API by calling the
  `syncDeviceContacts` method on `SinglySession`.

* Service icons are now bundled with the framework for performance.

* Avatar images for friends in the friends picker are now cached.

* The friends picker is now an indexed table view with on-demand loading of
  friends as you scroll through the list.

* Placeholder images in the login and friend pickers are no longer cleared if
  the image fails to load.

## 1.0.3 — December 17th, 2012

* Fixed an issue that caused a crash in the SDK when returning from the native
  Facebook app after authorization completed.

## 1.0.2 — December 7th, 2012

* Fixed a runtime issue with iOS 5.x caused by accessing an undefined symbol in
  the Accounts framework.

## 1.0.1 — December 5th, 2012

* Added support for Cocoapods.

* Improved error reporting in the example app when a network is not available.

* Fixed some issues that were a result of profile notifications not being posted
  on the correct thread.

## 1.0.0 — December 3rd, 2012

* Initial release with a focus on authentication and API requests.
