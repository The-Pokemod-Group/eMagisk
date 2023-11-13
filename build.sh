#!/usr/bin/env bash
OLDPWD="$PWD"
DIRNAME=$(dirname "$0")

cd "$DIRNAME"

ver=$(sed -n "s|^versionCode=||p" module.prop)
name=$(sed -n "s|^name=||p" module.prop | sed "s| |-|g")
newVerCode="$ver"
newVersion=$(echo $newVerCode | \sed 's|\(.\)\(.\)\(.\)|\1\.\2\.\3|')

sed --in-place "s|^versionCode=$ver|versionCode=$newVerCode|;s|^version=v.*|version=v$newVersion|" module.prop
rm "$name-$newVersion".zip
zip -r "$name-$newVersion".zip . -x ".git/*" "LICENSE" "build.sh" ".gitignore" "*.zip"
# echo "$newVerCode" >../Deploy/version
echo "Made $name-$newVersion ($newVerCode)"

cd "$OLDPWD"
