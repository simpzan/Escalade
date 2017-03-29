#!/usr/bin/env sh

set -e
set -v

project=${PWD##*/}
app=$project.app
zip=$project.zip
archive=$project.xcarchive
appcast=$project.rss
InfoPlist=$app/Contents/Info.plist
PlistBuddy=/usr/libexec/PlistBuddy

buildApp() {
    echo "building $app..."
    rm -rf $archive
    xcodebuild archive -workspace ../$project.xcworkspace -scheme $project-macOS -archivePath $archive
    rm -rf $app
    xcodebuild -exportArchive -exportFormat app -archivePath $archive -exportPath $app
}
zipApp() {
    echo "zipping $app..."
    rm -rf $zip
    ditto -c -k --sequesterRsrc --keepParent $app $zip
}
signZip() {
    echo "signing the $zip..."
    openssl dgst -sha1 -binary < $zip | openssl dgst -dss1 -sign ../../dsa_priv.pem | tee signature | openssl enc -base64
    openssl dgst -sha1 -binary < $zip | openssl dgst -dss1 -verify ../../dsa_pub.pem -signature signature
}
uploadZip() {
    local tag=$1
    echo "uploading $zip $tag..."
    github-release release --user simpzan --repo $project --tag $tag --name $tag --description $tag
    github-release upload --user simpzan --repo $project --tag $tag --name $zip --file $zip
}
generateAppcast() {
    echo "generating appcast..."
    node ../Scripts/appcast.js $project.app ../Changelog.md appcast.xml
}
uploadAppcast() {
    local tag=$1
    echo "uploading appcast $tag..."
    rm -rf $appcast
    git clone --depth=1 --branch=gh-pages https://github.com/simpzan/$project.git $appcast
    cd $appcast
    cp -rf ../appcast.xml ../../README.md .
    git add .
    git -c user.name="Release.sh" commit -m "$tag"
    git push origin gh-pages
    cd ..
}


mkdir -p out
cd out

buildApp
zipApp
signZip

release=`$PlistBuddy -c "Print CFBundleShortVersionString" $InfoPlist`
build=`$PlistBuddy -c "Print CFBundleVersion" $InfoPlist`
tag=$release.$build

uploadZip $tag
generateAppcast
uploadAppcast $tag

cd ..

