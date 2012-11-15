#!/usr/bin/env ruby
#
# Create Disk Image
#
# This script will create a customized disk image for distribution of the
# framework.
#
# You must have the "markdown" gem installed on your system for this script
# to function: If you do not have it, type "sudo gem install markdown" to
# install it.
#

require "fileutils"
require "find"
require "rubygems"
require "tempfile"
require "tmpdir"
require "markdown"

name           = "Singly iOS SDK"
source_path    = ENV["SRCROOT"]
workspace_path = File.dirname(ENV["WORKSPACE_PATH"])
archive_path   = ENV["ARCHIVE_PATH"]
image_path     = "#{Tempfile.new('dmg').path}.dmg"

Dir.mktmpdir do |temp_path|

  # Stage the README to Disk Image
  markup = Markdown.new(File.read("#{workspace_path}/README.md"))
  File.open "#{temp_path}/Get Started.html", "w" do |file|
    file.write "<style>#{File.read("#{source_path}/SinglySDK/Resources/Get Started Stylesheet.css")}</style>"
    file.write markup.to_html
  end
  puts `SetFile -a E "#{temp_path}/Get Started.html"`

  # Stage the Framework and Bundle to Disk Image
  FileUtils.cp_r "#{archive_path}/Products/Library/Bundles/SinglySDK.bundle", temp_path
  FileUtils.cp_r "#{archive_path}/Products/Library/Frameworks/SinglySDK.framework", temp_path

  # Set Custom Icon on Framework Folder (TODO Move this to a build phase)
  puts `Rez -append "#{source_path}/SinglySDK/Resources/Icons/Singly Folder Icon.rsrc" -o "#{temp_path}/SinglySDK.framework/Icon\r"`
  puts `SetFile -a C "#{temp_path}/SinglySDK.framework"`

  # Stage Background to Disk Image
  FileUtils.mkdir "#{temp_path}/.background"
  FileUtils.cp "#{source_path}/SinglySDK/Resources/Images/Disk Image Background.tiff", "#{temp_path}/.background"

  # Remove Existing Image
  if File.exist? image_path
    puts `SetFile -a l "#{image_path}"`
    FileUtils.rm image_path
  end

  # Create Disk Image
  puts `hdiutil create -format UDRW -srcfolder "#{temp_path}" -volname "#{name}" "#{image_path}"`

  # Attach Disk Image
  puts `hdiutil attach "#{image_path}" -noautoopen -quiet`

  # Bless the Disk Image
  puts `bless --folder "/Volumes/#{name}" --openfolder "/Volumes/#{name}"`

  # Customize Disk Image
  puts `osascript "#{source_path}/Scripts/Customize Disk Image.applescript"`
  sleep 10

  # Compress Disk Image
  puts `hdiutil convert "#{image_path}" -format UDZO -imagekey zlib-level=9 -o "#{File.expand_path("~/Desktop")}/#{name}.dmg"`

end
