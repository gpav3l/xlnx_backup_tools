source user_config.tcl

set curPath [pwd]
createbsp -name firmware_bsp -hwproject $::env(design_name)_wrapper_hw_platform_0 -proc ps7_cortexa9_0
createbsp -name fsbl_bsp -hwproject $::env(design_name)_wrapper_hw_platform_0 -proc ps7_cortexa9_0

#Add library to bsp
# setlib -bsp firmware_bsp -lib lwip211
setlib -bsp fsbl_bsp -lib xilffs

#Config lwip
# configbsp -bsp firmware_bsp mem_size "524288"
# configbsp -bsp firmware_bsp dhcp_does_arp_check "false"
# configbsp -bsp firmware_bsp lwip_dhcp "false"
# configbsp -bsp firmware_bsp memp_n_pbuf "1024"
# configbsp -bsp firmware_bsp n_rx_descriptors "512"
# configbsp -bsp firmware_bsp n_tx_descriptors "512"
# configbsp -bsp firmware_bsp pbuf_pool_size "8192"
# configbsp -bsp firmware_bsp tcp_queue_ooseq "0"
# configbsp -bsp firmware_bsp lwip_tcp "false"

#Regenerate bsp
regenbsp  -bsp firmware_bsp  
regenbsp  -bsp fsbl_bsp  

#Create applications
createapp -name firmware -app {Empty Application} -proc ps7_cortexa9_0 -hwproject $::env(design_name)_wrapper_hw_platform_0 -os standalone -bsp firmware_bsp
createapp -name fsbl -app {Zynq FSBL} -proc ps7_cortexa9_0 -hwproject $::env(design_name)_wrapper_hw_platform_0 -os standalone -bsp fsbl_bsp

#Create symbol link for source folder
exec rm -r ./$::env(buildPath)/$::env(projName).sdk/firmware/src
file link -symbolic $curPath/$::env(buildPath)/$::env(projName).sdk/firmware/src $curPath/sw_srcs

projects -clean
projects -build