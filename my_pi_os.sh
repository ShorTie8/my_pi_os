#!/bin/bash
# A simple script to make your own raspbian install images and/or sdcard's
# More info and newest @ http://www.raspberrypi.org/forums/viewtopic.php?f=66&t=104981&p=724704#p724704
#
# Brought to you by ShorTie	<idiot@dot.com> 

sdcard=/dev/sda  			# Leave blank or remark out to make image, determinism whether to make image or sdcard
#write_image_to_sdcard=yes	# Remark out or leave blank to not have image writen to sdcard_device at end of making an image
image_name=my_pi_os.img 	# For safty sakes, always provide a name Pleaze
image_size=1234  			# 888 is enough for a Basic install, 1234 is needed for a desktop install
#LDXE_desktop=yes 			# Install a basic LXDE Desktop
sdcard_device=/dev/sda  	# If making an image, it will write image to this device at the end of image creation if defined

release=wheezy
#release=jessie
#release=sid  				# Set rpi_version=rpi2 && debian_version=ftp
#release=testing 			# Set rpi_version=rpi2 && debian_version=ftp
#release=stretch 			# Set rpi_version=rpi2 && debian_version=ftp
							# nano -w  /usr/share/cdebootstrap/suites

bootloader=kernel 			# Use this to use the foundations bootloader/firmware and kernels
#bootloader=no-kernel  		# Use this to use a basic bootloader/firmware and Debian kernels

#rpi_version=rpi 			# If using "bootloader=no-kernel" use this for rpi's A and B's to get the right kernel
rpi_version=rpi2 			# If using "bootloader=no-kernel" use this for Model 2 rpi's to get the right kernel
#debian_version=ftp			# Use this for rpi2's to get sources from http://ftp.us.debian.org/debian
							# Must use 'rpi_version=rpi2' above also

hostname=pi
domain_name=
root_password=root     	# Define your own root password here
#high_current=yes  		# Use to enable the USB high current hack for B+ models and rpi2's, otherwize USB current is limited to 600ma

root_file_system=ext4	# Normally used
#root_file_system=btrfs	# Btrfs is a new copy on write (CoW) filesystem for Linux		https://btrfs.wiki.kernel.org/index.php/Main_Page
						#   aimed at implementing advanced features while focusing on fault tolerance, repair and easy administration.
#root_file_system=f2fs	# Flash-Friendly File System, http://en.wikipedia.org/wiki/F2FS
						#   made for sdcards, but adds a git adventure

#mkfs_ext4_options="^huge_file"	# Foundations/spindle options
mkfs_ext4_options="^has_journal -E stride=0,stripe-width=128 -b 4096"		# My own creation, Use at your own risk!!, thoughts on it would be nice though
#mkfs_ext4_options="^has_journal -E stride=2,stripe-width=256 -b 4096"		# http://docs.pikatech.com/display/DEV/Optimizing+File+System+Parameters+of+SD+card+for+use+on+WARP+V3
#mkfs_ext4_options="^has_journal -E stride=2,stripe-width=1024 -b 4096" 	# https://blogofterje.wordpress.com/2012/01/14/optimizing-fs-on-sd-card/
#If you have a flash drive, and performance is the goal, schedule a nightly fstrim cron job on the relevant partitions.  http://fenidik.blogspot.com/2010/03/ext4-disable-journal.html

dhcp=yes 				# Set to yes to use dhcp, remark out or leave blank to use static ip
address=192.168.32.145
netmask=255.255.255.0
broadcast=192.168.32.255
gateway=192.168.32.1


#timezone=US/Eastern			# You can define this here or remark out or leave blank to use current systems
#locales=en_US.UTF-8			# You can define this here or remark out or leave blank to use current systems
#default_locale=en_US.UTF-8		# You can define this here or remark out or leave blank to use current systems

#number_of_keys=104		# You can define this here or remark out or leave blank to use current systems
keyboard_layout=us		# must be defined if number_of_keys is defined
keyboard_variant=		# blank is normal
keyboard_options=		# blank is normal
backspace=guess			# guess is normal


# stuff to have cdebootstrap to install or exclude, just use the ',' format
# Recommended to install dphys-swapfile here so swap file is not made during installation, but on 1st boot
include=dphys-swapfile
exclude=

# use 'xxxx_stuff' to add things after cdebootstrap install, use " " format like apt-get
rasp_stuff="libraspberrypi-bin libraspberrypi-dev libraspberrypi-doc"
basic_stuff="dbus fake-hwclock psmisc"
net_stuff="ssh ntp"

# if you need desktop apt's or more stuff, use 'more_stuff' like 'rasp_stuff's format to install them
#more_stuff="mlocate raspi-copies-and-fills raspi-config"
more_stuff="mlocate"

#********** END Configurization **************************************************************

# Pi check
echo "Checkin too see if being run on a Raspberry Pi"
if [ "cat /proc/cpuinfo | grep BCM" == "" ]; then
    echo "Ooops, this can only be run on a Raspberry Pi"
    exit 1
else
    echo "Cool, L00ks like a pi"
fi

# Check to see if my_raspbian.sh is being run as root
start_time=$(date)
echo -e "\nChecking for root .. "
if [ `id -u` != 0 ]; then
    echo "nop"
    echo -e "Ooops, my_raspbian.sh needs to be run as root !!\n"
    echo " Try 'sudo sh, ./my_raspbian.sh' as a user"
    exit 1
else
    echo "Yuppers .. :)~"
fi
echo " "


# Check for programs that are needed

echo "Checking for necessary programs..."
APS=""


echo -n "Checking for fuser ... "
if [ `which fuser` ]; then
    echo "ok"
else
    echo "nope"
    APS+="psmisc "
fi

echo -n "Checking for ioctl ... "
if [ -f /usr/include/linux/ioctl.h ]; then
    echo "ok"
else
    echo "nope"
    APS+="libc6-dev "
fi

echo -n "Checking for kpartx ... "
if [ `which kpartx` ]; then
    echo "ok"
else
    echo "nope"
    APS+="kpartx "
fi

echo -n "Checking for partprobe ... "
if [ `which partprobe` ]; then
    echo "ok"
else
    echo "nope"
    APS+="parted "
fi

echo -n "Checking for dosfstools ... "
if [ `which fsck.vfat` ]; then
    echo "ok"
else
    echo "nope"
    APS+="dosfstools "
fi

echo -n "Checking for cdebootstrap ... "
if [ `which cdebootstrap` ]; then
    echo "ok"
else
    echo "nope"
    APS+="cdebootstrap "
fi

if [ "$root_file_system" == "btrfs" ]; then
    modprobe btrfs
    echo -n "Checking for mkfs.btrfs ... "
    if [ `which mkfs.btrfs` ]; then
        echo "ok"
    else
        echo "nope"
        echo "Would you like to use the old apt-get version of btrfs-tools (0.19+20120328-7.1)"
        echo "  or the latest github version ??"
        echo "Type 'git' to use the github version"
        read resp
	    if [ "$resp" = "git" ]; then
            APS+="e2fslibs-dev libblkid-dev liblzo2-dev libacl1-dev asciidoc "
            github="git"
        else
            APS+="btrfs-tools "
            basic_stuff+=" btrfs-tools"
        fi
    fi
    insmod btrfs
fi

if [ "$root_file_system" == "f2fs" ]; then
    echo -n "Checking for uuid-dev ... "
    if [ -f /usr/include/uuid/uuid.h ]; then
        echo "ok"
    else
        echo "nope"
        APS+="uuid-dev "
    fi

    echo -n "Checking for pkg-config ... "
    if [ `which pkg-config` ]; then
        echo "ok"
    else
        echo "nope"
        APS+="pkg-config "
    fi

    echo -n "Checking for autoconf ... "
    if [ `which autoconf` ]; then
        echo "ok"
    else
        echo "nope"
        APS+="autoconf "
    fi

    echo -n "Checking for libtool ... "
    if [ `which libtool` ]; then
        echo "ok"
    else
        echo "nope"
        APS+="libtool "
    fi
fi

if [ "$APS" != "" ]; then
    echo "Ooops, Applications need .. :(~"
    echo $APS
    echo ""
    echo "Would you like me to get them for you ?? (y/n): "
    echo "Default is yes"
	read resp
	if [ "$resp" = "" ] || [ "$resp" = "y" ] || [ "$resp" = "yes" ]; then
        apt-get update
        apt-get -y install $APS
    else
        echo "Needed Application not installed"
        echo "Exiting .. :(~"
        exit 1
    fi
else
    echo "No applications needed .. :)~"
fi   
echo ""

if [ "$root_file_system" == "f2fs" ]; then
    echo -n "Checking for f2fs ... "
    if [ `which mkfs.f2fs` ]; then
        echo "ok"
    else
        echo "nope"
        echo "Going on a github adventure .. ;/~"
        git clone git://git.kernel.org/pub/scm/linux/kernel/git/jaegeuk/f2fs-tools.git 
        cd f2fs-tools
        autoreconf -fi
        ./configure && make && make install
        cd ..
        github="git"
    fi
echo ""
fi


if [ "$root_file_system" == "btrfs" ]; then
    echo -n "Checking for btrfs ... "
    if [ `which mkfs.btrfs` ]; then
        echo "ok"
    else
        echo "nope"
        echo "Going on a github adventure .. ;/~"
        git clone https://github.com/kdave/btrfs-progs.git 
        cd btrfs-progs
        ./autogen.sh
        ./configure && make && make install
        cd ..
    fi
echo ""
fi

fail () {
    echo -e "\n\nOh no's, sumfin went wrong\n"
    echo "Cleaning up my mess .. :(~"
    umount sdcard/proc
    umount sdcard/sys
    umount sdcard/dev/pts
    fuser -av sdcard
    fuser -kv sdcard
    umount sdcard/boot
    fuser -k sdcard
    umount sdcard
    kpartx -dv $image_name
    rm -rf sdcard
    rm $image_name
    exit 1
}

if [ "$sdcard" != "" ]; then
    echo "Installing raspbian to $sdcard"
    if ! (cat /proc/partitions | grep sd); then
        echo "Oops, no usb device ($sdcard) found"
        echo "Creating image instead"
        # Create image file
        echo "Creating a zero-filled file $image_name $image_size mega blocks big"
        dd if=/dev/zero of=$image_name  bs=1M  count="$image_size" iflag=fullblock
        thingy=$image_name
    else
        if (cat /etc/mtab | grep "$sdcard"); then
            unmount_version=$(umount --version | grep 2 | cut -d "." -f2)
            echo -n "unmount_version "; echo $unmount_version
            if [ "$unmount_version" -lt 25 ]; then
                echo "old"
                echo "unmounting $sdcard"
                umount -v $(fgrep "$sdcard" /etc/mtab  | cut -f 2 -d ' ')
            else
                echo "new"
                echo "unmounting $sdcard"
                umount -vA $sdcard
            fi
        else
            echo "$sdcard not mounted"
        fi
        thingy=$sdcard
    fi
else
    # Create image file
    echo "Creating a zero-filled file $image_name $image_size mega blocks big"
    dd if=/dev/zero of=$image_name  bs=1M  count="$image_size" iflag=fullblock
    thingy=$image_name
fi

# Create partitions
echo -e "\n\nCreating partitions\n"
fdisk_version=$(fdisk -v | grep 2 | cut -d "." -f2)
echo -n "fdisk_version "; echo $fdisk_version
if [ "$fdisk_version" -lt 25 ]; then
echo "old"
fdisk $thingy <<EOF
o
n



+40M
a
1
t
6
n




w
EOF

else
echo "new"
fdisk $thingy <<EOF
o
n



+40M
a
t
6
n




w
EOF

fi

if [ "$thingy" == "$sdcard" ]; then
    echo -n "\n\nPartprobing $thingy\n"
    partprobe $thingy
    echo ""
    echo -e "\n\nSetting up boot and root for $sdcard\n"
    bootpart="$sdcard"1
    rootpart="$sdcard"2
    echo -n "Boot partition is "
    echo $bootpart
    echo -n "Root partition is "
    echo $rootpart
else
    # Set up drive mapper
    echo -e "\n\nSetting up kpartx drive mapper for $image_name and define loopback devices for boot & root\n"
    loop_device=$(kpartx -av $image_name | grep p2 | cut -d" " -f8 | awk '{print$1}')
    echo -n "Loop device is "
    echo $loop_device
    echo -n "\n\nPartprobing $thingy\n"
    partprobe $loop_device
    echo ""
    bootpart=$(echo $loop_device | grep dev | cut -d"/" -f3 | awk '{print$1}')p1
    bootpart=/dev/mapper/$bootpart
    rootpart=$(echo $loop_device | grep dev | cut -d"/" -f3 | awk '{print$1}')p2
    rootpart=/dev/mapper/$rootpart
    echo -n "Boot partition is "
    echo $bootpart
    echo -n "Root partition is "
    echo $rootpart
fi

# Format partitions
echo -e "\nFormating partitions\n"
mkdosfs -n BOOT $bootpart
echo " "


if [ "$root_file_system" == "f2fs" ]; then
    mkfs.f2fs -l Raspbian $rootpart && sync
fi

if [ "$root_file_system" == "btrfs" ]; then
    mkfs.btrfs -L Raspbian $rootpart && sync
fi

if [ "$root_file_system" == "ext4" ]; then
    echo "mkfs.ext4 -O $mkfs_ext4_options  -L Raspbian $rootpart"
    echo "y" | mkfs.ext4 -O $mkfs_ext4_options  -L Raspbian $rootpart && sync
    echo " "
fi

if [ "$debian_version" == "ftp" ] && [ "$rpi_version" == "rpi2" ]; then
    http=http://ftp.us.debian.org/debian
else
    http=http://mirrordirector.raspbian.org/raspbian/
fi

echo ""
fdisk -l $thingy
echo ""

# debootstrap is a tool which will install a Debian base system into a subdirectory of another
echo "Setting up for cdebootstrap"
echo -e "mkdir sdcard, mount sdcard as /, cdebootstraping $rootpart, mount /boot as $bootpart and mount /proc,/sys & /dev/pts\n\n"
mkdir -v sdcard
echo -n "Mounting "
mount -v -t $root_file_system -o sync $rootpart sdcard
echo " "
include="--include=kbd,locales,keyboard-configuration,console-setup,$include"
exclude="--exclude=$exclude"
echo -n "cdebootstrap's line  "
echo "cdebootstrap --arch armhf ${release} sdcard $http ${include} $exclude"
echo " "

if [ "$release" == "stretch" ]; then
    cdebootstrap --arch armhf ${release} sdcard ${include} $exclude --allow-unauthenticated && sync || fail
else
    cdebootstrap --arch armhf ${release} sdcard $http ${include} $exclude --allow-unauthenticated && sync || fail
fi

echo -e "\nMount new chroot system\n"
mount -v -t vfat -o sync $bootpart sdcard/boot
mount -v proc sdcard/proc -t proc
mount -v sysfs sdcard/sys -t sysfs
mount -v --bind /dev/pts sdcard/dev/pts

# Adjust a few things
echo -e "\n\nCopy, adjust and reconfigure\n"
echo "Setting up the root password... "
echo root:$root_password | chroot sdcard chpasswd
echo ""

echo "Getting gpg.key's"; echo ""
chroot sdcard wget http://archive.raspberrypi.org/debian/raspberrypi.gpg.key
chroot sdcard apt-key add raspberrypi.gpg.key
rm -v sdcard/raspberrypi.gpg.key; echo ""
chroot sdcard wget http://mirrordirector.raspbian.org/raspbian.public.key
chroot sdcard apt-key add raspbian.public.key
rm -v sdcard/raspbian.public.key; echo ""
chroot sdcard apt-key list


echo -e "\nAdjusting /etc/apt/sources.list for Release $release  Bootloader $bootloader  rPi_version $rpi_version  debian_version $debian_version\n"

if [ "$release" == "sid" ] || [ "$release" == "testing" ]; then
    echo -e "Resetting to release to jessie for the rest of script, sid and testing have served there porpuse\n\n"
    release=jessie
fi

if [ "$bootloader" == "kernel" ]; then
    rasp_stuff+=" raspberrypi-bootloader"
    if [ "$debian_version" == "ftp" ] && [ "$rpi_version" == "rpi2" ]; then
        sed -i sdcard/etc/apt/sources.list -e "s/main/main contrib non-free/"
        echo "deb http://archive.raspberrypi.org/debian/ wheezy main" >> sdcard/etc/apt/sources.list
    else
        sed -i sdcard/etc/apt/sources.list -e "s/main/main contrib non-free firmware/"
        echo "deb http://archive.raspberrypi.org/debian/ wheezy main" >> sdcard/etc/apt/sources.list
    fi
else
    rasp_stuff+=" raspberrypi-bootloader-nokernel linux-image-$rpi_version-rpfv hardlink"
    echo -n "Creating preference for libraspberrypi-bin... "
    echo "# This sets the preference for the kernel version lower so the no-kernel are used" > sdcard/etc/apt/preferences.d/02VideoCore.pref
    echo "Package: libraspberrypi-bin libraspberrypi0 libraspberrypi-dev libraspberrypi-doc"  >> sdcard/etc/apt/preferences.d/02VideoCore.pref
    echo "Pin: release o=Raspbian,n=$release"  >> sdcard/etc/apt/preferences.d/02VideoCore.pref
    echo "Pin-Priority: 700"  >> sdcard/etc/apt/preferences.d/02VideoCore.pref
    if [ "$debian_version" == "ftp" ] && [ "$rpi_version" == "rpi2" ]; then
        sed -i sdcard/etc/apt/sources.list -e "s/main/main contrib non-free/"
        echo "deb http://mirrordirector.raspbian.org/raspbian $release main firmware" >> sdcard/etc/apt/sources.list
        sed -i sdcard/etc/apt/preferences.d/02VideoCore.pref -e "s/700/49/"
    else
        sed -i sdcard/etc/apt/sources.list -e "s/main/main contrib non-free firmware/"
        echo "deb http://archive.raspberrypi.org/debian wheezy main" >> sdcard/etc/apt/sources.list
    fi
fi


if [ "$debian_version" == "ftp" ] && [ "$rpi_version" == "rpi2" ]; then
    firm=$(fgrep "raspb" sdcard/etc/apt/sources.list | cut -f 2 -d ' ')
    echo "Setting up a distro pin for $firm"; echo ""
    echo "# This sets the priority of $firm low so ftp.debian files is used" > sdcard/etc/apt/preferences.d/01repo.pref
    echo "Package: *"  >> sdcard/etc/apt/preferences.d/01repo.pref
    echo "Pin: release n=$firm"  >> sdcard/etc/apt/preferences.d/01repo.pref
    echo "Pin-Priority: 50"  >> sdcard/etc/apt/preferences.d/01repo.pref
fi


echo "Contents of /etc/apt/sources.list"
cat sdcard/etc/apt/sources.list
echo "Contents of /etc/apt/preferences.d/"
cat sdcard/etc/apt/preferences.d/*; echo ""


echo "Changing timezone too..."
if [ "$timezone" == "" ]; then 
    cp -v /etc/timezone sdcard/etc/timezone
else
    echo "$timezone" > sdcard/etc/timezone
fi
cat sdcard/etc/timezone; echo ""

echo "Adjusting locales too..."
if [ "$locales" == "" ]; then 
    cp -v /etc/locale.gen sdcard/etc/locale.gen
else
    sed -i "s/^# \($locales .*\)/\1/" sdcard/etc/locale.gen
fi
grep -v '^#' sdcard/etc/locale.gen; echo ""

echo "Adjusting default local too..."
if [ "$default_locale" == "" ]; then 
    default_locale=$(fgrep "=" /etc/default/locale | cut -f 2 -d '=')
fi
echo $default_locale; echo ""

echo "Setting up keyboard"
if [ "$number_of_keys" == "" ]; then 
    cp -v /etc/default/keyboard sdcard/etc/default/keyboard
else
    # setting up keyboard package
    echo "Adjusting  keyboard to $number_of_keys $keyboard_layout... "
    # adjust variables
    xkbmodel=XKBMODEL='"'$number_of_keys'"'
    xkblayout=XKBLAYOUT='"'$keyboard_layout'"'
    xkbvariant=XKBVARIANT='"'$keyboard_variant'"'
    xkboptions=XKBOPTIONS='"'$keyboard_options'"'
    backspace=BACKSPACE='"'$backspace'"'

    # make keyboard file
    cat <<EOF > sdcard/etc/default/keyboard
# KEYBOARD CONFIGURATION FILE

$xkbmodel
$xkblayout
$xkbvariant
$xkboptions

$backspace

EOF
fi
echo ""; cat sdcard/etc/default/keyboard; echo ""
# end keyboard


echo "Creating cmdline.txt";echo ""
echo "dwc_otg.lpm_enable=0 console=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait" > sdcard/boot/cmdline.txt


echo "Creating config.txt"; echo ""
cat <<EOF > sdcard/boot/config.txt
# For more options and information see 
# http://www.raspberrypi.org/documentation/configuration/config-txt.md
# Some settings may impact device functionality. See link above for details

# uncomment if you get no picture on HDMI for a default "safe" mode
#hdmi_safe=1

# uncomment this if your display has a black border of unused pixels visible
# and your display can output without overscan
#disable_overscan=1

# uncomment the following to adjust overscan. Use positive numbers if console
# goes off screen, and negative if there is too much border
#overscan_left=16
#overscan_right=16
#overscan_top=16
#overscan_bottom=16

# uncomment to force a console size. By default it will be display's size minus
# overscan.
#framebuffer_width=1280
#framebuffer_height=720

# uncomment if hdmi display is not detected and composite is being output
#hdmi_force_hotplug=1

# uncomment to force a specific HDMI mode (this will force VGA)
#hdmi_group=1
#hdmi_mode=1

# uncomment to force a HDMI mode rather than DVI. This can make audio work in
# DMT (computer monitor) modes
#hdmi_drive=2

# uncomment to increase signal to HDMI, if you have interference, blanking, or
# no display
#config_hdmi_boost=4

# uncomment for composite PAL
#sdtv_mode=2

#uncomment to overclock the arm. 700 MHz is the default.
#arm_freq=800

EOF

if [ "$high_current" == "yes" ]; then
    echo "" >> sdcard/boot/config.txt
    echo "# Enables max USB current" >> sdcard/boot/config.txt
    echo "safe_mode_gpio=4" >> sdcard/boot/config.txt
    echo "max_usb_current=1" >> sdcard/boot/config.txt
fi


echo "Adding Raspberry Pi tweaks to sysctl.conf"; echo ""
echo "" >> sdcard/etc/sysctl.conf
echo "# http://www.raspberrypi.org/forums/viewtopic.php?p=104096#p104096" >> sdcard/etc/sysctl.conf
echo "# rpi tweaks" >> sdcard/etc/sysctl.conf
echo "vm.swappiness = 1" >> sdcard/etc/sysctl.conf
echo "vm.min_free_kbytes = 8192" >> sdcard/etc/sysctl.conf
echo "vm.vfs_cache_pressure = 50" >> sdcard/etc/sysctl.conf
echo "vm.dirty_writeback_centisecs = 1500" >> sdcard/etc/sysctl.conf
echo "vm.dirty_ratio = 20" >> sdcard/etc/sysctl.conf
echo "vm.dirty_background_ratio = 10" >> sdcard/etc/sysctl.conf


echo "Adjust hosts and hostname"; echo ""
echo $hostname > sdcard/etc/hostname
echo "127.0.1.1 $domain_name $hostname" >> sdcard/etc/hosts

echo "CONF_SWAPSIZE=100" > sdcard/etc/dphys-swapfile
sed -i sdcard/etc/default/rcS -e "s/^#FSCKFIX=no/FSCKFIX=yes/"
sed -i sdcard/lib/udev/rules.d/75-persistent-net-generator.rules -e 's/KERNEL\!="eth\*|ath\*|wlan\*\[0-9\]/KERNEL\!="ath\*/'
chroot sdcard dpkg-divert --add --local /lib/udev/rules.d/75-persistent-net-generator.rules


# Setup fstab
echo -e "\nSetting up fstab\n"
cat <<EOF > sdcard/etc/fstab
#<file system>  <dir>          <type>   <options>       <dump>  <pass>
proc            /proc           proc    defaults          0       0
/dev/mmcblk0p1  /boot           vfat    defaults          0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime  0       1
# a swapfile is not a swap partition, so no using swapon|off from here on, use  dphys-swapfile swap[on|off]  for that
EOF

if [ "$root_file_system" == "btrfs" ]; then
    echo -e "\nmodify fstab & cmdline.txt for btrfs use\n"
    echo " "
    sed -i -e 's/ext4    defaults,noatime  0       1/btrfs    defaults         0       1/' sdcard/etc/fstab
    sed -i -e 's/ext4/btrfs/' sdcard/boot/cmdline.txt
    echo "btrfs" >> sdcard/etc/initramfs-tools/modules
    if [ "$github" == "git" ]; then
        our_path=$(echo $PWD)
        our_path+="/sdcard"
        echo -n "our_path  "
        echo $our_path
        cd btrfs-progs
        make install DESTDIR=$our_path
        cd ..
        basic_stuff+=" e2fslibs libc6 libc6.1 libcomerr2 libgcc1 libuuid1 zlib1g"
    fi
    
fi


if [ "$root_file_system" == "f2fs" ]; then
    echo -e "\nCopy f2fs over and modify fstab & cmdline.txt for f2fs use\n"
    if [ "$github" == "git" ]; then
        our_path=$(echo $PWD)
        our_path+="/sdcard"
        echo -n "our_path  "
        echo $our_path
        cd f2fs-tools
        make install DESTDIR=$our_path
        cd ..
    else
        cp -v /sbin/*f2fs* sdcard/sbin/
        cp -v /usr/lib/libf2fs* sdcard/usr/lib/; echo " "
        rm -v sdcard/usr/lib/libf2fs.so.0
        ln -v -s sdcard/usr/lib/libf2fs.so.0.0.0 sdcard/usr/lib/libf2fs.so.0
    fi
    basic_stuff+=" libuuid1"
    echo " "
    sed -i -e 's/ext4    defaults,noatime  0       1/f2fs    defaults          0       0/' sdcard/etc/fstab
    sed -i -e 's/ext4/f2fs/' sdcard/boot/cmdline.txt
fi

cat sdcard/etc/fstab && sync; echo " "

chroot sdcard dpkg-reconfigure -f noninteractive locales
echo " "
chroot sdcard locale-gen LANG="$default_locale"
echo " "
chroot sdcard dpkg-reconfigure -f noninteractive tzdata
echo " "
chroot sdcard dpkg-reconfigure -f noninteractive keyboard-configuration
echo " "
chroot sdcard dpkg-reconfigure -f noninteractive console-setup

echo "Done Coping, adjusting and reconfiguring"

echo -e "Setting up networking\n\n"

cat <<EOF > sdcard/etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
EOF

if [ "$dhcp" == "yes" ]; then
    echo "iface eth0 inet dhcp" >> sdcard/etc/network/interfaces
else
    echo "iface eth0 inet static" >> sdcard/etc/network/interfaces
    echo "    address	$address" >> sdcard/etc/network/interfaces
    echo "    netmask	$netmask" >> sdcard/etc/network/interfaces
    echo "    broadcast	$broadcast" >> sdcard/etc/network/interfaces
    echo "    gateway	$gateway" >> sdcard/etc/network/interfaces
fi

cat <<EOF > sdcard/etc/modprobe.d/ipv6.conf
# Don't load ipv6 by default
alias net-pf-10 off
#alias ipv6 off
EOF

echo "hostname "
cat sdcard/etc/hostname
echo " "
echo "resolv.conf "
cat sdcard/etc/resolv.conf
echo " "
echo "hosts"
cat sdcard/etc/hosts
echo " "
echo "network/interfaces"
cat sdcard/etc/network/interfaces
echo " "
echo "modprobe.d/ipv6.conf"
cat sdcard/etc/modprobe.d/ipv6.conf
echo " "

# end Networking

# Update and install raspberrypi-bootloader
echo -e "\n\nUpdate install and install raspberrypi-bootloader and other stuff\n"
echo -e "apt-get update\n\n"
chroot sdcard apt-get update || fail
echo -e "\n\napt-get  -y upgrade\n\n"
chroot sdcard apt-get -y upgrade || fail
echo -e "\n\napt-get -y dist-upgrade\n\n"
chroot sdcard apt-get -y dist-upgrade || fail
chroot sdcard apt-get clean
echo -e "\n\napt-get -y install $rasp_stuff\n\n"
chroot sdcard apt-get -y install $rasp_stuff || fail
chroot sdcard apt-get clean


if [ "$bootloader" == "no-kernel" ]; then
    kernel=$(ls sdcard/boot | fgrep vmlinuz | cut -f 2 -d '/')
    echo "kernel=$kernel" >> sdcard/boot/config.txt
    initrd=$(ls sdcard/boot | fgrep initrd | cut -f 2 -d '/')
    echo "initramfs $initrd followkernel" >> sdcard/boot/config.txt
fi


if [ "$basic_stuff" != "" ]; then
    echo -e "\n\nBasic_stuff apt-get -y install $basic_stuff\n\n"
    chroot sdcard apt-get -y install $basic_stuff || fail
    chroot sdcard apt-get clean
fi

if [ "$net_stuff" != "" ]; then
    echo -e "\n\nNet_stuff apt-get -y install $net_stuff\n\n"
    chroot sdcard apt-get -y install $net_stuff || fail
    chroot sdcard apt-get clean
fi

if [ "$LDXE_desktop" != "" ]; then
    echo -e "\n\nInstall LXDE Desktop\n\n"
    chroot sdcard apt-get -y install xserver-xorg-video-fbdev xserver-xorg xinit lxde lxtask menu-xdg gksu --no-install-recommends || fail
    echo -e "\n\nInstall lightdm\n\n"
    chroot sdcard apt-get -y install lightdm xfonts-100dpi xfonts-75dpi xfonts-scalable policykit-1
    echo -e "\n\nSetting autologin\n\n"
    sed -i 's/#autologin-user=/autologin-user='$root_password'/' sdcard/etc/lightdm/lightdm.conf
    chroot sdcard apt-get clean
fi

chroot sdcard apt-get autoremove -y
echo -e "\n\nOk, Done with raspberrypi-bootloader and other stuff\n\n"

if [ `chroot sdcard which ssh` ] ; then
    echo "ssh found, checking $release to allow ssh root login"
    # openssh-server in jessie doesn't allow root to login using password anymore
    # this hack does allow it (until a proper solution is implemented)
    if [ "$release" != "wheezy" ]; then
        if ( grep 'PermitRootLogin without-password' sdcard/etc/ssh/sshd_config ); then
            echo -n "Allowing root to log into $release with password... "
            sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' sdcard/etc/ssh/sshd_config || fail
            echo "OK"
        fi
    fi
fi


if [ "$more_stuff" != "" ]; then
    echo -e "\nInstalling more stuff, $more_stuff\n"
    chroot sdcard apt-get -y install $more_stuff
    chroot sdcard apt-get clean
fi
echo ""


#**********************************************************************************
# Add even more 'chroot root apt-get's here if you want

#**********************************************************************************


sync
du -ch sdcard | grep total
echo " "

echo " "
echo "Unmounting mount points"
fuser -av sdcard
fuser -kv sdcard
umount sdcard/proc
umount sdcard/sys
umount sdcard/dev/pts
umount -v sdcard/boot
umount -v sdcard
kpartx -dv $image_name
fuser -av sdcard
rm -rf sdcard
echo " "

echo $start_time
echo $(date)
echo " "

if [ "$sdcard" == "" ] && [ "$write_image_to_sdcard" != "" ]; then
    echo "Writing image to sdcard"
    umount -v $(fgrep "$sdcard_device" /etc/mtab  | cut -f 2 -d ' ')
    dd if=$image_name of=$sdcard_device bs=1M && sync
fi
echo " "


echo -e "\n\nOkie Dokie, We Done\n"
echo "Yall Have A Great Day now ShorTie"
exit 0
