#### Version v3.2.20.6 - 2024/02/10
------------------------------
* patch 6 to v3.2.20 with reverted PR362 ("relax CPU clock and voltage constraints to provide higher performance, lower power and still prevent system freeze")
* The stability of the OpenVario has obviously dropped significantly since the PR362 - there were significantly more freezes on several systems!

#### Version v3.2.20.5 - 2024/01/23
------------------------------
##### OpenVarioNG with upgrade function:
* complete upgrade possible via USB stick without any additional manually interactions (like removing SD card, saving the old data, restoring the data folder, setting device feature like SSH, rortation, brightness...)
* this is the 5th patch of this release (with some solved bugs in the older ones)
* Important Bugfix serial debug port ttyS1

* Binaries OpenSoar:  https://opensoar.de/releases/v7.40.20.2
* Images  OpenVario: https://opensoar.de/releases/v7.40.20.2/3.2.20.5/ 

#### Version v3.2.20.4 - 2023/12/22
------------------------------
- single test version only for Blaubart
- restore bootloader image after recovery start to previous system
  (new bootloader necessary for a 'good' starting of ov-recover.itb, old
   bootloader necessary for breaking upgrade and restarting old system)
- rework UPGRADE_TYPE 3 (old image type -> new one)

##### known bugs:
- ATTENTION: Debug Port is moved from ttyS0 to ttyS1 since v3.2.20.0: don't use this buggy versions! Starting point should be v3.2.20.5 (which have the Debug port back to ttyS0)! 

#### Version v3.2.20.3 - 2023/12/18
------------------------------
- next overhaul of all upgrade functionality (part 4)
- bugfix creating data partition in ov-menu

#### Version v3.2.20.2 - 2023/12/17
------------------------------
- update opensoar (7.41.20.2)
- next overhaul of all upgrade functionality (part 3)

#### Version v3.2.20.1 - 2023/12/02
------------------------------
- 1st version with upgrade functionality
- update opensoar (7.40.20.1)
- update xcsoar (7.40)
- next major overhaul of all upgrade functionality (part 2)
- config.uEnv: selecting main application (OpenSoar or xcsoar)
- recover_data/upgrade.cfg: config file for the upgrade, renamed after upgrade
  to recover_data/_upgrade.cfg
- link OpenSoar: https://opensoar.de/releases/v7.40.20.1/ 

##### known bugs:
- downgrade to and from old image type (and between) not really ready
  there are a lot of issues in

#### Version v3.2.20.0 - 2023/11/10
------------------------------
- 1st version with upgrade functionality
- Download version removed on server!
- rename repository to 'OpenVario' and meta-layer from 'meta-ov' to 
  'meta-openvario' (like previous repositories)
- major overhaul of all upgrade functionality
- change sd card (mmcblk0) layout:
  * 2 MB Bootsector  (0 .. 2MB)
  * 40 MB Partition 1 (boot) (2..42MB)
  * 470 MB Partition 2 (ov-system) (42MB .. 512MB)
  * ~700 MB Gap (reserved for older images to avoid the next data partition)
    (512 .. 1.2GB)
  * 2.5GB (and more) Partition 3 (data) (start at 1.2GB up to 'end of sd card')
- change machine names to make it shorter and more unique:

|  old machine name     |   | MACHINE    |      Short Name  |
|-----------------------|---|-----|----------|
|  openvario-7-CH070      | -> | ov-ch70    |  **CH70**  |
|  openvario-57-lvds      | -> | ov-ch57    |  **CH57** |
|  openvario-7-PQ070      | -> | ov-pq70    |  **PQ70** |
|  openvario-43-rgb       | -> | ov-am43    |  **AM43** |
|  openvario-7-AM070-DS2  | -> | ov-am70s   |  **AM70s** |
|  openvario-7-CH070-DS2  | -> | ov-ch70s   |  **CH70s** |
|  openvario-57-lvds-DS2  | -> | ov-ch57s   |  **CH57s** |

- add a 2nd start option for start recovery: /home/root/ov-recovery.itb
- using TARGET 'OPENVARIO_CB2' for compiling OpenSoar

##### known bugs:
- downgrade to and from old image type (and between) not really ready
  there are a lot of issues in

Version v3.0.1-19 - 2023/08/17
------------------------------
* update only opensoar and xcsoar (7.39)

Version v3.0.1-18 - 2023/08/17
------------------------------
* update only opensoar and xcsoar (7.38)

Version v3.0.1-17 - 2023/08/16
------------------------------
* update only opensoar and xcsoar (7.37)

Version v3.0.1-16 - 2023/08/16
------------------------------
* merged PR360 (Linux Update 6.3.8, bitbake 2.0, openembedded, ..)

Version v3.0.1-15 - 2023/08/16
------------------------------

Version v3.0.1-14 - 2023/08/16
------------------------------

Version v3.0.1-13 - 2023/08/16
------------------------------

Version v3.0.1-12 - 2023/08/16
------------------------------

Version v3.0.1-11 - 2023/08/16 
------------------------------

Version v3.0.1-10 - never released 
------------------------------

Version v3.0.1-9 - 2023/03/24
------------------------------
* autostart OpenSoar in ovshell
* OpenSoar v7.28.05 (with Becker driver inside!)

Version v3.0.1-8  2023/02/16
------------------------------
* FL and pressure height not really set (everytime ~0)
* OpenSoar v7.28.05

Version v3.0.1-7 2023/02/05
------------------------------
 
* 1st OV release with OpenSoar
    * You can switch bitween XCSoar and OpenSoar in the shell menu
    * default is OpenSoar
