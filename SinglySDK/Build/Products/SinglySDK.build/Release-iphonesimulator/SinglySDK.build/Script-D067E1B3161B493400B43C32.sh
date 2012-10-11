#!/bin/sh

if [ ! -e /usr/local/bin/appledoc ]; then
    echo "warning: Unable to generate documentation because AppleDoc is not installed. Please install AppleDoc by using Homebrew (e.g. brew install appledoc)."
    exit 0
fi

/usr/local/bin/appledoc \
  --project-name "${PROJECT_NAME}" \
  --project-company "Singly, Inc" \
  --company-id "com.singly" \
  --output "${PROJECT_DIR}/Documentation" \
  --docset-atom-filename "SinglySDK.atom" \
  --docset-feed-url "http://github.com/Singly/iOS-SDK/%DOCSETATOMFILENAME" \
  --docset-package-url "http://github.com/Singly/iOS-SDK/%DOCSETPACKAGEFILENAME" \
  --docset-fallback-url "http://github.com/Singly/iOS-SDK/" \
  --publish-docset \
  --logformat xcode \
  --keep-undocumented-objects \
  --keep-undocumented-members \
  --keep-intermediate-files \
  --no-repeat-first-par \
  --no-warn-invalid-crossref \
  --exit-threshold 2 \
  --ignore ".m" \
  --ignore "SinglySDKTests" \
  --index-desc "${PROJECT_DIR}/../README.md" \
  "${PROJECT_DIR}"

