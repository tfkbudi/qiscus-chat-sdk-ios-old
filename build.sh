#!/bin/sh
# Note: this file is originally based upon
# https://gkbrown.org/2017/10/11/creating-a-universal-framework-in-xcode-9/
# Since it includes simulator slices as well, these will need to be
# stripped out prior to the apps being submitted to the app store

WORKSPACE=QiscusCore
FRAMEWORK=QiscusCore
BUILD=build
FRAMEWORK_NAME_WITH_EXT=$FRAMEWORK.framework
DSYM_NAME_WITH_EXT=$FRAMEWORK_NAME_WITH_EXT.dSYM

IOS_ARCHIVE_DIR=Release-iphoneos-archive
IOS_ARCHIVE_FRAMEWORK_PATH=$BUILD/$IOS_ARCHIVE_DIR/Products/Library/Frameworks/$FRAMEWORK_NAME_WITH_EXT
IOS_ARCHIVE_DSYM_PATH=$BUILD/$IOS_ARCHIVE_DIR/dSYMs
IOS_SIM_DIR=Release-iphonesimulator
IOS_UNIVERSAL_DIR=Release-universal-iOS

echo "\033[37m Bismillahirrahmanirrahim. \033[0m\n"
echo "\033[31m Cleaning up after old builds \033[0m\n"
rm -Rf $BUILD

echo "\033[37m Installing dependencies"
if ! [ -x "$(command -v xcpretty)" ]; then
  echo " Installing xcpretty....."
  gem install xcpretty
fi

# iOS
echo " Installing cocoapods \033[0m\n"
pod install

echo "\033[32m BUILDING FOR iOS \033[0m\n"

echo "\033[26m ▹ Building for simulator (Release) \033[0m\n"
xcodebuild build -workspace $WORKSPACE.xcworkspace -scheme $FRAMEWORK -sdk iphonesimulator SYMROOT=$BUILD OTHER_CFLAGS="-fembed-bitcode" BITCODE_GENERATION_MODE=bitcode | xcpretty

echo "\033[32m ▹ Building for device (Archive) \033[0m\n"
xcodebuild archive -workspace $WORKSPACE.xcworkspace -scheme $FRAMEWORK -sdk iphoneos -archivePath $BUILD/Release-iphoneos.xcarchive OTHER_CFLAGS="-fembed-bitcode" BITCODE_GENERATION_MODE=bitcode | xcpretty


echo "\033[32m Copying... \n framework files \033[0m\n"
mv $BUILD/Release-iphoneos.xcarchive $BUILD/$IOS_ARCHIVE_DIR
echo "\033[32m Create Universal directory \033[0m\n"
mkdir -p $BUILD/$IOS_UNIVERSAL_DIR
echo "\033[32m Create Universal frameworks \033[0m\n"
cp -RL $IOS_ARCHIVE_FRAMEWORK_PATH $BUILD/$IOS_UNIVERSAL_DIR/$FRAMEWORK_NAME_WITH_EXT
echo "\033[32m Create Universal dSYMs \033[0m\n"
cp -RL $IOS_ARCHIVE_DSYM_PATH/$DSYM_NAME_WITH_EXT $BUILD/$IOS_UNIVERSAL_DIR/$DSYM_NAME_WITH_EXT

cp -RL $BUILD/$IOS_SIM_DIR/$FRAMEWORK_NAME_WITH_EXT/Modules/$FRAMEWORK.swiftmodule/* $BUILD/$IOS_UNIVERSAL_DIR/$FRAMEWORK_NAME_WITH_EXT/Modules/$FRAMEWORK.swiftmodule
echo "### lipo'ing the iOS frameworks together into universal framework"
lipo -create $IOS_ARCHIVE_FRAMEWORK_PATH/$FRAMEWORK $BUILD/$IOS_SIM_DIR/$FRAMEWORK_NAME_WITH_EXT/$FRAMEWORK -output $BUILD/$IOS_UNIVERSAL_DIR/$FRAMEWORK_NAME_WITH_EXT/$FRAMEWORK
echo "### lipo'ing the iOS dSYMs together into a universal dSYM"
DSYM_PATH=$DSYM_NAME_WITH_EXT/Contents/Resources/DWARF/$FRAMEWORK
lipo -create $IOS_ARCHIVE_DSYM_PATH/$DSYM_PATH $BUILD/$IOS_SIM_DIR/$DSYM_PATH  -output $BUILD/$IOS_UNIVERSAL_DIR/$DSYM_PATH


# Rename and zip
echo "### Copying iOS files into zip directory"
ZIP_DIR=$BUILD/zip
mkdir $ZIP_DIR
cp -RL LICENSE $ZIP_DIR
mkdir $ZIP_DIR/iOS
cp -RL $BUILD/$IOS_UNIVERSAL_DIR/$FRAMEWORK_NAME_WITH_EXT $ZIP_DIR/iOS/$FRAMEWORK_NAME_WITH_EXT
cp -RL $BUILD/$IOS_UNIVERSAL_DIR/$DSYM_NAME_WITH_EXT $ZIP_DIR/iOS/$DSYM_NAME_WITH_EXT
cd $ZIP_DIR
zip -r QiscusCore.zip LICENSE iOS/$FRAMEWORK_NAME_WITH_EXT iOS/$DSYM_NAME_WITH_EXT
echo "### Zipped resulting frameworks and dSYMs to $ZIP_DIR/QiscusCore.zip"
