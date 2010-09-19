#!/bin/bash
#===============================================================================
#   DESCRIPTION:  Makes carrier bundles.
#        AUTHOR:  Sorin Ionescu <sorin.ionescu@gmail.com>
#       VERSION:  1.0.10
#===============================================================================

export PATH=/usr/bin:/usr/libexec:$PATH
cd "$( dirname "$0" )"

directory_root="$(pwd)"
src='../src'
info_file="${src}/Info.plist"
carrier_file="${src}/carrier.plist"
version=`git tag 2>/dev/null | sort -n -k3 -t. | tail -n 1`
test -z "$version" && version='1.0.0'

mkdir -p build
cd build

test ! -e "$info_file" && {
    echo ERROR: Info.plist not found.
    exit 1
}

ipcc_package_prefix_name="$(echo "$directory_root" | awk 'BEGIN {FS = "/" }; {print $NF}' | tr '[A-Z]' '[a-z]' | sed 's/ /_/g')"
ipcc_package_prefix_os="ios$(PlistBuddy -c 'Print :MinimumOSVersion' "$info_file" | cut -d'.' -f1)"
ipcc_package_prefix="${ipcc_package_prefix_name}_${ipcc_package_prefix_os}"
ipcc_package_name="${ipcc_package_prefix_name}_${ipcc_package_prefix_os}_${version}.ipcc.zip"
ipcc_name="${ipcc_package_prefix_name}.ipcc"
bundle_name="${ipcc_package_prefix_name}.bundle"
bundle_path="Payload/${bundle_name}"

echo Making carrier bundle $ipcc_name
rm -rf * 
mkdir -p "$bundle_path"
ditto "$src" "$bundle_path"
find "$bundle_path" -type f \( -name "*.plist" -o -name "*.strings" \) -exec plutil -convert binary1 "{}" \;
PlistBuddy -c 'Print :SupportedSIMs' "${carrier_file}" | sed -e '1d' -e '$d' | xargs -n1 -I"{}" ln -s "$bundle_name" "Payload/{}"
zip -9ryq "$ipcc_name" Payload/ 
echo Making package $ipcc_package_name
zip -9Dyq $ipcc_package_name ../README.txt *.ipcc
find . ! -name '*.zip' | sed '/^\.\{1,2\}$/d' | xargs rm -rf
exit 0

