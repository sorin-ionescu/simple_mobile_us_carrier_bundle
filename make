#!/bin/bash
#===============================================================================
#   DESCRIPTION:  Makes carrier bundles.
#        AUTHOR:  Sorin Ionescu <sorin.ionescu@gmail.com>
#       VERSION:  1.0.12
#===============================================================================

export PATH=/usr/bin:/usr/libexec:$PATH
cd "$( dirname "$0" )"

root="$(pwd)"
src="${root}/src"
info_plist="${src}/Info.plist"
carrier_plist="${src}/carrier.plist"
version=$(git tag 2>/dev/null | sort -n -k2 -t. | tail -n 1)

if [[ -z "$version" ]]; then
    version='1.0.0'
fi

if [[ ! -e "$info_plist" ]]; then 
    echo ERROR: Info.plist not found.
    exit 1
fi

bundle="$(
    echo "$root" \
        | awk -F '/' '{ print $NF }' \
        | awk -F ' ' '{ OFS = "_" ; $NF = tolower($NF) ; print }')"
bundle_name="${bundle}.bundle"
bundle_path="Payload/${bundle_name}"
ipcc_name="${bundle}.ipcc"
ios_version="$(
    PlistBuddy -c 'Print :MinimumOSVersion' "$info_plist" \
        | cut -d '.' -f 1-2)"
package_name="$(
    echo "${bundle}_${ios_version}_ipcc_${version}.zip" \
        | tr '[A-Z' '[a-z]')"


echo Making: $ipcc_name

# Create or clean build dir.
mkdir -p build
cd build
rm -rf * 

# Copy files.
cp "${root}/README.txt" . 
ditto "$src" "${bundle_path}/"
find . -type f -name .DS_Store -delete

# Convert plists to binary.
find "$bundle_path" \
    -type f \( -name "*.plist" -o -name "*.strings" \) \
    -exec plutil \
    -convert binary1 "{}" \;

# Generate SIM symlinks to bundle.
PlistBuddy -c 'Print :SupportedSIMs' "${carrier_plist}" \
    | sed -e '1d' -e '$d' \
    | xargs -n1 -I"{}" ln -s "$bundle_name" "Payload/{}"

# Zip carrier bundle.
zip -9ryq "$ipcc_name" Payload/

# Zip package.
echo Packaging: $package_name
zip -9Dyq $package_name README.txt *.ipcc
find . ! -name '*.zip' | sed '/^\.\{1,2\}$/d' | xargs rm -rf

exit 0

