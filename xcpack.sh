#!/bin/sh
#Author: Bevis bevisssliu@gmail.com
#
yellowColor='\033[1;33m'
clearColor='\033[0m' # No Color


# 1. setup configs and add "xcrunBuild/" into your .gitignore
TARGET_NAME=xxxx # the project target name 
WORKSPACE_NAME=$TARGET_NAME # you need to change the default value if your workspace_name is different from the targe name you're going to use
BUILD_CONFIGURATION=Debug # the build configuration of current scheme

SPRINT_NUMBER=18 # put your name here
smbaUserName="username" # you can have your own
smbaPassword="password" # same as above
smbaDirectory="192.168.23.15/互联网产品中心/项目" # this's ours, you can set your own path
sharedProjectsDirectory="$smbaDirectory/${TARGET_NAME}" 
sharedBuildNumberFileName="${TARGET_NAME}_global_build_number" 

FIR_TOKEN=1a2s3d4f5g6h7j8k934df5g6h7j8m9 # it's easy to find in your fir account, replace it with yours 
FIR_SHORT_LINK=http://fir.im/5rt6 # you'll get this once you succeed in publishing your ipa in fir

mountedDirectory="/Volumes/$TARGET_NAME" # use "mount" to check the result
sharedBuildNumberPath="${mountedDirectory}/iOS/$sharedBuildNumberFileName" # custom your own path

Global_Build_Number=-1 # default value, don't change it
bundleVersion=0 # default value, don't change it
IPAPackage="" # default value, don't change it

notifyBuildProcessWithText(){
	text="$1"
	echo "${yellowColor} $text ${clearColor}"
	osascript -e "display notification \"$text\" with title \"xcbuild\" "
}

# 2. make sure that you are connected to smba server
connectToSmbaService(){
	#umount $mountedDirectory
	if [[ -d $mountedDirectory ]]; then
		echo "mountedDirectory: $mountedDirectory"
	else
		notifyBuildProcessWithText "We're connecting to smba service ..."
		osascript -e 'mount volume "smb://'${smbaUserName}':'${smbaPassword}'@'${sharedProjectsDirectory}'" '
		# osascript -e 'mount volume "smb://jianjie.xiao:xiaojianjie123@192.168.59.1/互联网产品中心/项目/GoldMaster/iOS/" '
		if [[ ! -d $mountedDirectory ]]; then
			notifyBuildProcessWithText "There's something wrong during connection,\n Please manually check it"
			exit
		fi
	fi

} 

# 3. read global build number from ${TARGET_NAME}_global_build_number file,
#    if there is no the file, we'll create it and write a new build number
getGlobalBuildNumber(){
	if [ ! -f  $sharedBuildNumberPath ]; then
	    # set a default value
	    echo "Global build number is unset"
	    echo "Please input a default value, like: 435"
	    read defaultBuildNumber
	    if [[ ! -d $sharedProjectsDirectory ]]; then
			notifyBuildProcessWithText "creating new sharedProjectsDirectory : \n$sharedProjectsDirectory"
			mkdir -p $sharedProjectsDirectory
		fi
	    echo $defaultBuildNumber > $sharedBuildNumberPath
	fi

	Global_Build_Number=`cat $sharedBuildNumberPath`
	# echo $Global_Build_Number > $sharedBuildNumberPath
	if [[ -n $Global_Build_Number ]]; then
		echo "previous Global_Build_Number: $Global_Build_Number"
	fi
}


# 4. increase targets' build number
increaseBuildNumber(){
	buildPlist="${TARGET_NAME}/Info.plist"
	todayBuildPlist="${TARGET_NAME}Today/Info.plist"
	#settingsPlist="Settings.bundle/Information.plist"
	# Get the existing buildVersion and buildNumber values from the buildPlist
	bundleVersion=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $buildPlist)
	# echo $bundleVersion
	buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $buildPlist)
	# echo $buildNumber

	buillNumber=$(($buildNumber > $Global_Build_Number ? $buildNumber : $Global_Build_Number))
	buildNumber=`expr $buildNumber + 1`
	Global_Build_Number=$buildNumber
	if [[ -f $sharedBuildNumberPath ]]; then
		echo $Global_Build_Number > $sharedBuildNumberPath
	fi
	# echo "new buildNumber: $buildNumber"
	
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" $buildPlist
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" $todayBuildPlist

	bundleVersion="$bundleVersion.$buildNumber"
	echo "full build version: "$bundleVersion

}

# 5. clean, build, archive and package
buildAndExportArchive(){
	root_path=$(pwd)
	echo "project root path : $root_path"
	buildDir=$root_path/xcrunBuild
	if [[ ! -d $buildDir ]]; then
		mkdir -p $buildDir
	fi
	ARCHIVE_PATH=$buildDir/${TARGET_NAME}.xcarchive
	logPath=$buildDir/buildLog
	echo $bundleVersion > $logPath
	xcpretty=`which xcpretty`
	# notifyBuildProcessWithText "Cleaning"
	# time xcodebuild -workspace ${WORKSPACE_NAME}.xcworkspace -scheme $TARGET_NAME clean | $xcpretty --color >> $logPath
	# notifyBuildProcessWithText "Building"
	# time xcodebuild -workspace ${WORKSPACE_NAME}.xcworkspace -scheme $TARGET_NAME | $xcpretty --color >> $logPath
	notifyBuildProcessWithText "Archiving"
	time xcodebuild archive -workspace ${WORKSPACE_NAME}.xcworkspace -scheme $TARGET_NAME -configuration $BUILD_CONFIGURATION -archivePath $ARCHIVE_PATH DEPLOYMENT_POSTPROCESSING=YES | $xcpretty --color >> $logPath
	notifyBuildProcessWithText "Exporting"
	time xcodebuild -exportArchive -archivePath $ARCHIVE_PATH -exportPath $buildDir -exportOptionsPlist exportOptions.plist >> $logPath

	nameOfIPA="${TARGET_NAME}${bundleVersion}.ipa"
	IPAPackage="xcrunBuild/$nameOfIPA"
	mv "xcrunBuild/${TARGET_NAME}.ipa" $IPAPackage #change the name of the new ipa

	if [[ ! -f $IPAPackage ]]; then
		notifyBuildProcessWithText "IPA file doesn't exit"
		exit
	else
	    open "xcrunBuild"
	fi
}

# 6. upload ipa file to smba server and fir
#smba
uploadToSmbaService(){
	
	bigVersion=${bundleVersion:0:3}
	shortBundleVersion=${bundleVersion:0:5}
	newVersionPath="V$bigVersion/${shortBundleVersion}测试环境/"
	smbPackageLoaction="${mountedDirectory}/iOS/$newVersionPath"
	if [[ ! -d $smbPackageLoaction ]]; then
	    notifyBuildProcessWithText "creating ${smbPackageLoaction}"
	    mkdir -p $smbPackageLoaction
	fi
	cp $IPAPackage $smbPackageLoaction

	if [ $? -eq 0 ]; then
		open $smbPackageLoaction
	    notifyBuildProcessWithText "${TARGET_NAME}.ipa has been copied to smba server successfully!"
	    absoluteIPAPath="${sharedProjectsDirectory}/${newVersionPath}$nameOfIPA"
	    # echo "smb://$absoluteIPAPath"
	    # notifyBuildProcessWithText "${smbPackageLoaction}$nameOfIPA"
	    
	    #make a installation announcement format
	    sprint="Sprint_${SPRINT_NUMBER} $BUILD_CONFIGURATION"
	    webLocation=$FIR_SHORT_LINK
		announcement="iOS $sprint \nbundleVersion: $bundleVersion \nWebInstall: $webLocation \nSmbaInstall: //$absoluteIPAPath"
		echo $announcement | pbcopy
		echo "========================== announcement format begin ======================"
		echo $announcement
		echo "========================== announcement format end   ======================"
	else
	    notifyBuildProcessWithText "Failed to copy .ipa file, Please check if still you're connecting smba server"
	fi
}

# fir
uploadToFir(){
	packageName='fir'
	packageLocation=`which $packageName`
	# echo $packageLocation
	# echo ${#packageLocation}
	if [[ $packageLocation = '$packageName not found' || ${#packageLocation} -eq 0 ]]; then
		notifyBuildProcessWithText "$packageName hasn't been installed yet"
		notifyBuildProcessWithText "please run sudo gem install fir-cli first"
	fi

	if [[ $1 = '-p' ]]; then
		#statements
		time fir publish -T $FIR_TOKEN $IPAPackage
	else
		notifyBuildProcessWithText "Input '-p' if you're going to publish ipa to fir"
	fi
}
smbaAccountIsValid(){
	if [[ (-n "$smbaUserName") && (-n "$smbaPassword") ]]; then
		return 0
	else
		return 1
	fi
}

start(){
	smbaAccountIsValid # 1
	local saiv=$? #saiv indicates smbaAccountIsValid
	if [[ $saiv -eq 0 ]]; then
		echo "smbaAccount is Valid"
		connectToSmbaService	# 2
		getGlobalBuildNumber	# 3
	else
		echo "smbaAccount is Invalid"
	fi
	increaseBuildNumber	#4
	buildAndExportArchive #5
	if [[ -f $IPAPackage ]]; then
		if [[ $saiv -eq 0 ]]; then
			uploadToSmbaService 
			# echo ""
		fi
		uploadToFir $1
	fi	
}

start $1
