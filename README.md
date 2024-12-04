# Description

This is template for Xilinx Vivado, Vitis and SDK projects. Contain folder for save source file and tcl scripts tjat allow create backup of project and restore it. Can be use with SVN or GIT.

Script allow save:

* all block designe in project
* IP core added to project not in block designe

Script allow restore:

* Project with associated board and device
* Add HDL, XDC and WCFG file into project
* Restore block designe and stand alone IP core include all user config

Script not restore:

* Prject settings for implementation, simulation and etc.

`backup_vivado` is main command that generate a few tcl:

- Tcl with board, device and project name info (gen_config.tcl) 
- Generate folder structure
- Copy HDL and XDC file from Vivado project into backup folder, with sort by hdl, xdc and tb folders
- One tcl for restore every blocke designe (template of name is bd_des_<designe_name>.tcl)
- tcl for restore IP core (name stand_alone_ip.tcl)

User allow change some config, by edit user_config.tcl file.

# Template structure

Template contain a few folder, help You sort source by it usage (folders name config over user_config.tcl)
For generate folder structure, source backup_vivado.tcl and call `gen_folder_structure <path_of_backup_folder>`. 
Also that folder will be generate automaticaly when You call backup_vivado process.

* core/ - Folder for save custom IP core
* hdl/ - Folder for save source (Verilog, System Verilog and VHDL) usage for synthesis
* hls/ - Sudbfolder with source to use in HLS for generate core
* sw_repo/ - subfolder with additional source library, added as repo in SDK or Vitis
* sw_srcs/ - Folder with application source, for Baremetall recomendate use symbol link to that folder or subfolder
* tb/ - Folder for save source (Verilog, System Verilog and VHDL) usage for simulation
* wcfg/ - Wafe form configuration file, used in simulation
* xdc/ - Folder for pinout description and other constraints

# Usage for backup

## For exists project

* Source backup_proj.tcl in Vivado after opening project with command `source -notrace <path_to>/backup_proj.tcl`
* Call `backup_vivado` for launch backup 
    
## For new project

* Create project, where You want
* Recomended create (or add existng file) to the folder of template, not into folder of project
* Source backup_proj.tcl in Vivado with opening project `source -notrace <path_to>/backup_proj.tcl`
* Call `backup_vivado` for launch backup 

# Howto restore

* Open Vivado
* Found tcl console input
* launch restore by input `source -notrace <path_to>/restore_vivado.tcl`

Also You can use restore to create new project, but it require manually edit get_config.tcl file.

# Example for bsp_init.tcl

```tcl
bsp config hypervisor_guest true

bsp setlib lwip211
bsp config lwip_dhcp true
bsp config dhcp_does_arp_check true
bsp config mem_size 524288
bsp config memp_n_pbuf 1024
bsp config memp_n_tcp_seg 1024
bsp config n_rx_descriptors 512
bsp config n_tx_descriptors 512
bsp config pbuf_pool_size 16384
bsp config tcp_snd_buf 65535
bsp config tcp_wnd 65535
```
