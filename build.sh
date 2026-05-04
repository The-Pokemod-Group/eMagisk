#!/usr/bin/env sh
OLDPWD="$PWD"
DIRNAME=$(dirname "$0")

cd "$DIRNAME"

ver=$(sed -n "s|^versionCode=||p" module.prop)
currentVersion=$(sed -n "s|^version=v||p" module.prop)
name=$(sed -n "s|^name=||p" module.prop | sed "s| |-|g")

format_version() {
    code="$1"
    major=${code%"${code#?}"}
    rest=${code#?}
    minor=${rest%"${rest#?}"}
    patch=${rest#??}
    if [ "$patch" = "00" ]; then
        printf '%s.%s' "$major" "$minor"
    else
        printf '%s.%s.%s' "$major" "$minor" "$patch"
    fi
}

if [ .$1 == .github ]; then
    newVerCode="$ver"
    newVersion="$currentVersion"
else
    newVerCode=$((ver + 1))
    newVersion=$(format_version "$newVerCode")
fi
zipfile="$name-$newVersion.zip"

if [ .$1 != .github ]; then
    sed --in-place "s|^versionCode=$ver|versionCode=$newVerCode|;s|^version=v.*|version=v$newVersion|" module.prop
fi
rm -f "$zipfile"
zip -r "$zipfile" META-INF common custom system install.sh module.prop
# echo "$newVerCode" >../Deploy/version
echo "Made $zipfile ($newVerCode)"

cd "$OLDPWD"
