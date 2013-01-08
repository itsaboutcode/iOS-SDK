
# Singly SDK ChangeLog

## 1.1.0 — Not Released

* Auth tokens for services are now available in the `profiles` property on
  `SinglySession`.

* The simplified profile is now fetched in places of the profiles endpoint and
  is accessible with the `profile` property on `SinglySession`.

* Added support for syncing device contacts with the Singly API with the
  `syncDeviceContacts` method on `SinglySession`.

* Service icons in the login picker are now bundled with the framework and
  includes Retina versions of each.

* Avatar images for friends that are loaded and displayed in the friends picker
  are now cached.

* Updated the friends picker to be an indexed view with on-demand loading of
  friends.

* Placeholder images in the login and friend picker view controllers are no
  longer cleared if the image failed to load.

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
