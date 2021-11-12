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
- Copy HDL and XDC file from Vivado project into backup folder, with sort by hdl, xdc and tb folders
- One tcl for restore every blocke designe (template of name is bd_des_<designe_name>.tcl)
- tcl for restore IP core (name stand_alone_ip.tcl)

User allow change some config, by edit user_config.tcl file.

# Template structure

Template contain a few folder, help You sort source by it usage

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