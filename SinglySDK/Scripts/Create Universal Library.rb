#
# Create Universal Library
#
# This script will create universal binary versions of the active products.
#

sdk_platform = ENV['SDK_NAME'][/[A-Za-z]+/] \
  or raise "Could not find platform name from SDK_NAME: #{ENV['SDK_NAME']}"

sdk_version = ENV['SDK_NAME'][/[0-9]+.*$/] \
  or raise "Could not find SDK version from SDK_NAME: #{ENV['SDK_NAME']}"

other_platform = (sdk_platform == "iphoneos" ? "iphonesimulator" : "iphoneos")

# Determine the built product paths
built_products_path = ENV['BUILT_PRODUCTS_DIR']
product_name = ENV['FULL_PRODUCT_NAME']
executable_name = ENV['EXECUTABLE_PATH']
other_built_products_path = built_products_path.sub(/#{sdk_platform}$/, other_platform)
universal_products_path = "#{ENV['BUILD_ROOT']}/#{ENV['CONFIGURATION']}-universal"

# Build the other platform
puts "Building for the #{other_platform} platform ..."
`xcodebuild -project "#{ENV['PROJECT_FILE_PATH']}" -target "#{ENV['TARGET_NAME']}" -configuration "#{ENV['CONFIGURATION']}" -sdk #{other_platform}#{sdk_version} BUILD_DIR="#{ENV['BUILD_DIR']}" OBJROOT="#{ENV['OBJROOT']}" BUILD_ROOT="#{ENV['BUILD_ROOT']}" SYMROOT="#{ENV['SYMROOT']}" #{ENV['ACTION']}`

# Determine architectures of built products
build_architectures = ENV['ARCHS'].split
current_product_architectures = `xcrun -sdk iphoneos lipo -info #{built_products_path}/#{executable_name} | sed -n 's/.*: //p'`.split
other_product_architectures = `xcrun -sdk iphoneos lipo -info #{other_built_products_path}/#{executable_name} | sed -n 's/.*: //p'`.split

# Remove stale architectures from current product
(current_product_architectures - build_architectures).each do |stale_architecture|
  puts "Removing architecture '#{stale_architecture}' from the built product for the '#{sdk_platform}' platform ..."
  `xcrun -sdk iphoneos lipo #{built_products_path}/#{executable_name} -remove #{stale_architecture} -output #{built_products_path}/#{executable_name}`
end

# Remove stale architectures from other product
build_architectures.each do |stale_architecture|
  next unless other_product_architectures.include? stale_architecture
  puts "Removing architecture '#{stale_architecture}' from the built product for the '#{other_platform}' platform ..."
  `xcrun -sdk iphoneos lipo #{other_built_products_path}/#{executable_name} -remove #{stale_architecture} -output #{other_built_products_path}/#{executable_name}`
end

# Recombine built products into the universal product path
puts "Combining built products into a universal binary ..."
`mkdir -p "#{universal_products_path}"`
`cp -R "#{built_products_path}/#{product_name}" "#{universal_products_path}"`
`xcrun -sdk iphoneos lipo -create "#{built_products_path}/#{executable_name}" "#{other_built_products_path}/#{executable_name}" -output "#{universal_products_path}/#{executable_name}"`
unless File.exists? "#{universal_products_path}/#{executable_name}"
  puts "error: There was a problem while building the universal binary!"
  exit
end

# Replace built products with the new fat binary
`cp -R "#{universal_products_path}/#{product_name}" "#{built_products_path}"`
`cp -R "#{universal_products_path}/#{product_name}" "#{other_built_products_path}"`
puts "Replaced built products for all platforms with the fat binary"
