my_pi_os

A Raspberry Pi operating system maker

This is a highly configurable Minimal Operating System maker using your Pi for the Pi.

Because the Pi is Arm based, other test boxes are not supported.

It is a Net-Install of the OS pulling files from either mirrordirector.raspbian.org,
	or for rpi2's it can use ftp.us.debian.org for the packages.

1. Choose your build method
	1. Make a Image file.
	2. Make a Image file then write it to a sdcard at the end.
	3. Or just use make up a sdcard. If you choose this but no /dev/sdx if found it will make an image.

2. Choose if you want the LDXE_desktop

3. Choose the distribution for the Operating system
    a. wheezy
    b. jessie
    c. sid
    d. testing
    e. stretch

4. Pick weather you want to use the foundations bootloader/kernels or the no-kernel-bootloader/Debian kernels.
    For the no-kernel-bootloader option you must define the version of pi to get the correct kernel.

5. For rpi2 users you can choose to use ftp.debian for files, bootloader options are still valid, but rpi2 must be defined to work.

6. Define hostname, domain_name and root_password.

7. Pick your root file system ext4, btrfs or f2fs. ext4 has 4 different format options.
    For btrfs, you can choose apt-get or github tools if mkfs.btrfs is not found.
    For both btrfs and f2fs github tools, install is done to both the system and image/sdcard.

8. Either use dhcp or assign a static ip.

9. Define your timezone, locales and keyboard, or rem out or leave blank to use currect profiles from your pi.

10. List packages you want cdebootstrap to include or exclude, becarefull because dependencies are not checked.
     The only package I recommend including here is dphys-swapfile.
      The reason being is of you do it during any of the xxxx_stuff's it will make the default 2 times RAM size.
      Which is kind of big for the Raspberry Pi.
      We set the size to 100mb later and it will be created on first boot.

11. Lastly define the stuff you want apt-get to install, recommended way so dependencies are installed.
    For clearity this is broken down into 4 options, like the following example.
    
      1. rasp_stuff="libraspberrypi-bin libraspberrypi-dev libraspberrypi-doc"
      2. basic_stuff="dbus fake-hwclock psmisc"
      3. net_stuff="ssh ntp"
      4. more_stuff="mlocate raspi-copies-and-fills raspi-config"













