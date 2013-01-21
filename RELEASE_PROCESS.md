
# Singly SDK Release Process

1. **Increment Version Number** — The current version is tracked in
   `SinglyConstants.h` as the `kSinglySDKVersion` constant and is referenced
   throughout the project and build scripts. For minor releases, such as bug
   fixes, simply increment the maintenance number. Releases that change API or
   introduce new behavior should increment either the minor or major version,
   depending on the scope of the changes.

2. **Update the ChangeLog** — Be sure to add any significant user-facing changes
   to `CHANGELOG.md`.

3. **Perform Archive Build** — Set the scheme to "Framework" and build for iOS
   devices. This will create a new disk image on your desktop.

4. **Tag Release** — If all is succesful, tag the release in git and push the
   tag to GitHub. The tag should be formatted as "vX.X.X".
