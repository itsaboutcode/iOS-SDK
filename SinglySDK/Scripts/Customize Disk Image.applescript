--
-- Customize Disk Image
--
-- This script will customize our distribution disk image with a custom
-- background, positioning and icons.
--

tell application "Finder"
	tell disk "Singly iOS SDK"
		open
		
		tell container window
			set bounds to {200, 100, 800, 580}
			set toolbar visible to false
			set statusbar visible to false
			set current view to icon view
		end tell
		
		-- Adjust Icon & Text Sizes
		set icon size of the icon view options of container window to 72
		set text size of the icon view options of container window to 12
		
		-- Set Background Image
		set background picture of the icon view options of container window to file ".background:Disk Image Background.tiff"
		
		-- Update Icon Positions
		set arrangement of the icon view options of container window to not arranged
		set position of item "Get Started.html" of container window to {120, 364}
		set position of item "SinglySDK.framework" of container window to {323, 364}
		set position of item "SinglySDK.bundle" of container window to {478, 364}
		
		update without registering applications
		delay 3
		close
		eject
	end tell
end tell
