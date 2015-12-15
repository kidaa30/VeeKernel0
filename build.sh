#!/bin/bash
# Original Live by cybojenix <anthonydking@gmail.com>
# New Live/Menu by Caio Oliveira aka Caio99BR <caiooliveirafarias0@gmail.com>
# Colors by Aidas Lukošius aka aidasaidas75 <aidaslukosius75@yahoo.com>
# Toolchains by Suhail aka skyinfo <sh.skyinfo@gmail.com>
# Rashed for the base of zip making
# And the internet for filling in else where

# You need to download https://github.com/TeamVee/android_prebuilt_toolchains
# Clone in the same folder as the kernel to choose a toolchain and not specify a location

# Prepare output customization commands - Start

customcoloroutput() {
if [ "$coloroutput" == "ON" ]; then
	# Stock Color
	txtrst=$(tput sgr0)
	# Bold Colors
	txtbld=$(tput bold) # Bold
	bldred=${txtbld}$(tput setaf 1) # red
	bldgrn=${txtbld}$(tput setaf 2) # green
	bldyel=${txtbld}$(tput setaf 3) # yellow
	bldblu=${txtbld}$(tput setaf 4) # blue
	bldmag=${txtbld}$(tput setaf 5) # magenta
	bldcya=${txtbld}$(tput setaf 6) # cyan
	bldwhi=${txtbld}$(tput setaf 7) # white
	coloroutputzip="--color=auto"
fi
if [ "$coloroutput" == "OFF" ]; then
	unset txtbld bldred bldgrn bldyel bldblu bldmag bldcya bldwhi
	coloroutputzip="--color=never"
fi
}

setcustomcoloroutput() {
if [ "$coloroutput" == "ON" ]; then
	coloroutput="OFF"
else
	coloroutput="ON"
fi
}

setcustombuildoutput() {
if [ "$buildoutput" == "ON" ]; then
	buildoutput="OFF"
else
	buildoutput="ON"
fi
}

# Prepare output customization commands - End

# Clean - Start

cleanzip() {
rm -rf zip-creator/*.zip zip-creator/zImage zip-creator/system/lib/modules/*.ko
cleanzipcheck="Done"
unset zippackagecheck
}

cleankernel() {
make clean mrproper &> /dev/null | echo "Cleaning..."
cleankernelcheck="Done"
unset buildprocesscheck name variant namevariant maindevicecheck BUILDTIME
}

# Clean - End

# Main Process - Start

maindevice() {
echo "1) L3 II Single (E425/E430/E431)"
echo "2) L3 II Dual   (E435)"
unset errorchoice
read -p "Choice: " -n 1 -s choice
case "$choice" in
	1 ) defconfig="veekernel_vee3_defconfig"; name="L3II"; variant="Single";;
	2 ) defconfig="veekernel_vee3ds_defconfig"; name="L3II"; variant="Dual";;
	* ) echo "$choice - This option is not valid"; sleep .5; errorchoice="ON";;
esac
if ! [ "$errorchoice" == "ON" ]; then
	namevariant="$name-$variant"
	echo "$choice - $name $variant"; make $defconfig &> /dev/null | echo "Setting..."
	maindevicecheck="ON"
	unset cleankernelcheck
	zipfile="$customkernel-$name-$variant-$version.zip"
fi
}

manualtoolchain() {
echo ""
echo "Script says: Please specify a location"
echo "Script says: and the prefix of the chosen toolchain at the end"
echo "GCC 4.6 ex. ../arm-eabi-4.6/bin/arm-eabi-"
read -p "Place: " CROSS_COMPILE
ToolchainCompile=$CROSS_COMPILE
}

maintoolchain() {
if [ -f ../android_prebuilt_toolchains/aptess.sh ]; then
	. ../android_prebuilt_toolchains/aptess.sh
elif [ -d ../android_prebuilt_toolchains ]; then
	echo "You not have APTESS in Android Prebuilt Toolchain folder"
	echo "Check the folder or press "y" for manual specify location"
	read -p "Continue? (y/n): " -n 1 -s tps
	case "$tps" in
		y | Y) manualtoolchain ;;
		n | N) ;;
		*) echo "$tps - This option is not valid"; sleep .5 ;;
	esac
else
	echo "Script says: You don't have TeamVee Prebuilt Toolchains"
	manualtoolchain
fi
}

# Main Process - End

# Build Process - Start

buildprocess() {
START=$(date +"%s")
NR_CPUS=$(grep -c ^processor /proc/cpuinfo)
if [ "$NR_CPUS" -le "2" ]; then
	NR_CPUS="4"
fi
echo "${bldblu}Building $customkernel with $NR_CPUS jobs at once${txtrst}"
rm -rf arch/$ARCH/boot/zImage
if [ "$buildoutput" == "ON" ]; then
	make -j${NR_CPUS}
else
	make -j${NR_CPUS} &>/dev/null | loop
fi
END=$(date +"%s")
BUILDTIME=$(($END - $START))
if [ -f arch/$ARCH/boot/zImage ]; then
	buildprocesscheck="Done"
	unset cleankernelcheck
else
	buildprocesscheck="Something goes wrong"
fi
}

loop() {
LEND=$(date +"%s")
LBUILDTIME=$(($LEND - $START))
echo -ne "\r\033[K"
echo -ne "${bldgrn}Build Time: $(($LBUILDTIME / 60)) minutes and $(($LBUILDTIME % 60)) seconds.${txtrst}"
sleep 1
if ! [ -f arch/$ARCH/boot/zImage ]; then
	loop
fi
}

# Build Process - End

# Zip Process - Start

zippackage() {
# Variables
fileupdaterscript="zip-creator/META-INF/com/google/android/updater-script"
fileupdaterscripttemp="zip-creator/META-INF/com/google/android/updater-script-temp"
stockvariant="Single"

# Updater-script - Time
sed "s/Release/Release ${release} revision ${revision}/" $fileupdaterscript > $fileupdaterscripttemp
mv $fileupdaterscripttemp $fileupdaterscript


cp arch/$ARCH/boot/zImage zip-creator
find . -name *.ko | xargs cp -a --target-directory=zip-creator/system/lib/modules/ &> /dev/null

cd zip-creator
zip -r $zipfile * -x */.gitignore *.zip &> /dev/null
cd ..

# Updater-script - Time
sed "s/Release ${release} revision ${revision}/Release/" $fileupdaterscript > $fileupdaterscripttemp
mv $fileupdaterscripttemp $fileupdaterscript

zippackagecheck="Done"
unset cleanzipcheck
}

# Zip Process - End

# ADB - Start

adbcopy() {
echo "Script says: You want to copy to Internal or External Card?"
echo "i) For Internal"
echo "e) For External"
read -p "Choice: " -n 1 -s adbcoping
case "$adbcoping" in
	i ) echo "Coping to Internal Card..."; adb shell rm -rf /storage/sdcard0/$zipfile &> /dev/null; adb push zip-creator/$zipfile /storage/sdcard0/$zipfile &> /dev/null; adbcopycheck="Done";;
	e ) echo "Coping to External Card..."; adb shell rm -rf /storage/sdcard1/$zipfile &> /dev/null; adb push zip-creator/$zipfile /storage/sdcard1/$zipfile &> /dev/null; adbcopycheck="Done";;
	* ) echo "$adbcoping - This option is not valid"; sleep .5;;
esac
}

# ADB - End

# Misc - Start

buildtimemisc() {
if ! [ "$BUILDTIME" == "" ]; then
	echo "${bldgrn}Build Time: $(($BUILDTIME / 60)) minutes and $(($BUILDTIME % 60)) seconds.${txtrst}"
fi
}

zippackagemisc() {
echo "${bldyel}Zip Saved to zip-creator/$zipfile${txtrst}"
}

# Misc - End

# Menu - Start

buildsh() {
kernelversion=`cat Makefile | grep VERSION | cut -c 11- | head -1`
kernelpatchlevel=`cat Makefile | grep PATCHLEVEL | cut -c 14- | head -1`
kernelsublevel=`cat Makefile | grep SUBLEVEL | cut -c 12- | head -1`
kernelname=`cat Makefile | grep NAME | cut -c 8- | head -1`
clear
echo "Simple Linux Kernel Build Script ($(date +%d"/"%m"/"%Y))"
echo "$customkernel $version $kernelversion.$kernelpatchlevel.$kernelsublevel - $kernelname"
echo
echo "-${bldred}Clean:${txtrst}-"
echo "1) Last Zip Package (${bldred}$cleanzipcheck${txtrst})"
echo "2) Kernel (${bldred}$cleankernelcheck${txtrst})"
echo "-${bldgrn}Main Process:${txtrst}-"
echo "3) Device Choice (${bldgrn}$namevariant${txtrst})"
echo "4) Toolchain Choice (${bldgrn}$ToolchainCompile${txtrst})"
echo "-${bldyel}Build Process:${txtrst}-"
if [ "$maindevicecheck" == "" ]; then
	echo "Use "3" first."
else
	if [ "$CROSS_COMPILE" == "" ]; then
		echo "Use "4" first."
	else
		echo "5) Build $customkernel (${bldyel}$buildprocesscheck${txtrst})"
	fi
fi
if ! [ "$maindevicecheck" == "" ]; then
	if [ -f arch/$ARCH/boot/zImage ]; then
		echo "6) Build Zip Package (${bldyel}$zippackagecheck${txtrst})"
	fi
fi
echo "-${bldblu}Test Menu:${txtrst}-"
if [ -f zip-creator/$zipfile ]; then echo "7) Copy to device - Via Adb"; fi
echo "8) Reboot device to recovery"
echo "-${bldmag}Status:${txtrst}-"
buildtimemisc
if [[ "$maindevicecheck" == "" || "$CROSS_COMPILE" == "" ]]; then
	if [ -f arch/$ARCH/boot/zImage ]; then
		echo "${bldblu}You have old Kernel build!${txtrst}"
		buildprocesscheck="Old build"
	fi
fi
if [ -f zip-creator/$zipfile ]; then
	zippackagemisc
elif [ `ls zip-creator/*.zip 2>/dev/null | wc -l` -ge 2 ]; then
	echo "${bldblu}You have old Zips Saved on zip-creator folder!${txtrst}"
	ls zip-creator/*.zip ${coloroutputzip}
elif [ `ls zip-creator/*.zip 2>/dev/null | wc -l` -ge 1 ]; then
	echo "${bldblu}You have old Zip Saved on zip-creator folder!${txtrst}"
	ls zip-creator/*.zip ${coloroutputzip}
fi
echo "-${bldcya}Menu:${txtrst}-"
if [ "$coloroutput" == "ON" ]; then
echo "c) Color (${bldcya}$coloroutput${txtrst})"
else
echo "c) Color ($coloroutput)"
fi
if [ "$buildoutput" == "ON" ]; then
echo "o) View Build Output (${bldcya}$buildoutput${txtrst})"
else
echo "o) View Build Output ($buildoutput)"
fi
echo "g) Git Gui | k) GitK | s) Git Push | l) Git Pull"

echo "q) Quit"
read -n 1 -p "${txtbld}Choice: ${txtrst}" -s x
case $x in
	1) echo "$x - Cleaning Zips"; cleanzip; buildsh;;
	2) echo "$x - Cleaning $customkernel"; cleankernel; buildsh;;
	3) echo "$x - Device choice"; maindevice; buildsh;;
	4) echo "$x - Toolchain choice"; maintoolchain; buildsh;;
	5) if [ -f .config ]; then
		echo "$x - Building $customkernel"; buildprocess; zippackage; buildsh
	else
		echo "$x - This option is not valid"; sleep .5; buildsh
	fi;;
	6) if [ -f arch/$ARCH/boot/zImage ]; then
		echo "$x - Ziping $customkernel"; zippackage; buildsh
	else
		echo "$x - This option is not valid"; sleep .5; buildsh
	fi;;
	7) if [ -f zip-creator/$zipfile ]; then
		echo "$x - Coping $customkernel"; adbcopy; buildsh
	else
		echo "$x - This option is not valid"; sleep .5; buildsh
	fi;;
	8) echo "$x - Rebooting to Recovery..."; adb reboot recovery; buildsh;;
	c) setcustomcoloroutput; customcoloroutput; buildsh;;
	o) setcustombuildoutput; buildsh;;
	q) echo "Ok, Bye!"; unset zippackagecheck;;
	g) echo "Opening Git Gui"; git gui; buildsh;;
	k) echo "Opening GitK"; gitk; buildsh;;
	s) echo "Pushing to local repo"; git push; buildsh;;
	l) echo "Pulling to local repo"; git pull; buildsh;;
	*) echo "$x - This option is not valid"; sleep .5; buildsh;;
esac
}

# Menu - End

# The core of script is here!

if [ -e build.sh ]; then
	customkernel=VeeKernel0
	export ARCH=arm
	release=0
	revision=1
	version=R${release}r${revision}
	zipfile="$customkernel-$name-$variant-$version.zip"

	if [ -f zip-creator/*.zip ]; then
		unset cleanzipcheck
	else
		cleanzipcheck="Done"
	fi

	if [ -f .config ]; then
		unset cleankernelcheck
	else
		cleankernelcheck="Done"
	fi

	if [ "$coloroutput" == "" ]; then
		coloroutput="ON"
	fi

	if [ "$buildoutput" == "" ]; then
		buildoutput="ON"
	fi

	customcoloroutput

	if [[ "$1" = "--help" || "$1" = "-h" ]]; then
		echo "Simple Linux Kernel Build Script"
		echo "Use: . build.sh [OPTION]"
		echo
		echo "  -l, --live           use this for fast building without menu"
		echo "  -C, --clean          use this for fast cleaning (Zip/Kernel)"
		echo
		echo "This is an open source script, feel free to use, edit and share it."
		echo "By default this have a menu to interactive with kernel building."
		echo "And for complete usage download:"
		echo "https://github.com/TeamVee/android_prebuilt_toolchains"
		echo "to same folder of kernel for fast toolchain select."
	elif [[ "$1" = "--live" || "$1" = "-l" ]]; then
		echo "--Choose a Device--"
		maindevice
		echo "--Choose a Toolchain--"
		maintoolchain; buildprocess; buildtimemisc; zippackage; zippackagemisc
	elif [[ "$1" = "--clean" || "$1" = "-C" ]]; then
		cleanzip; cleankernel
	else
		buildsh
	fi
else
	echo
	echo "Ensure you run this file from the SAME folder as where it was,"
	echo "otherwise the script will have problems running the commands."
	echo "After you 'cd' to the correct folder, start the build script"
	echo "with the ./build.sh command, NOT with any other command!"
	echo; sleep 1
fi
