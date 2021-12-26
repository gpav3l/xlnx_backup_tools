namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

cd $script_folder

source gen_config.tcl
source user_config.tcl
source backup_proj.tcl

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version $::env(vivadoVersion)
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts "RESTORE_INFO: "
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# Get list of file by pattern contain in set folder and it subfolders
################################################################
proc get_file_list { folder pattern } {
    set basedir [string trimright [file join [file normalize $folder] { }]]
    set fileList {}

    foreach fileName [glob -nocomplain -type {f r} -path $basedir $pattern] {
        lappend fileList $fileName
    }

    foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
        set subDirList [get_file_list $dirName $pattern]
        if { [llength $subDirList] > 0 } {
            foreach subDirFile $subDirList {
                lappend fileList $subDirFile
            }
        }
    }
    return $fileList
}

##################################################################
# Project PROCs
##################################################################
proc createProject { } {
    set cur_design [current_bd_design -quiet]
    set list_cells [get_bd_cells -quiet]
  
    close_project -quiet
    create_project $::env(projName) $::env(buildPath) -part $::env(partMark) -force
    
    if { $::env(boardPart) == 0 } {
        puts "RESTORE_INFO: Board not defined"
    } else {    
        set_property BOARD_PART $::env(boardPart) [current_project]
    }
    
    set_property  ip_repo_paths  $::env(ipRepoPath) [current_project]
    update_ip_catalog

    #set fileList [glob -nocomplain -directory $::env(xdcPath) *.xdc]
    set fileList [get_file_list $::env(xdcPath) *.xdc]
    if {[llength $fileList]} {
        add_files  -fileset constrs_1 -norecurse $fileList
    } else {
        puts "RESTORE_INFO: XDC file not found";
    }

    #set fileList [glob -nocomplain -directory $::env(hdlPath) *.v]
    set fileList [get_file_list $::env(hdlPath) *.v]
    if {[llength $fileList]} {
        add_files -norecurse $fileList
    } else {
        puts "RESTORE_INFO: HDL file not found";
    }

    #set fileList [glob -nocomplain -directory $::env(testPath) *.{v,sv}]
    set fileList [get_file_list $::env(testPath) *.{v,sv}]
    if {[llength $fileList]} {
        add_files -fileset sim_1 -norecurse $fileList
    } else {
        puts "RESTORE_INFO: HDL file not found";
    }

    #set fileList [glob -nocomplain -directory $::env(waveConfig) *.wcfg]
    set fileList [get_file_list $::env(waveConfig) *.wcfg]
    if {[llength $fileList]} {
        add_files -fileset sim_1 -norecurse $fileList
        set_property xsim.view $fileList [get_filesets sim_1]
    } else {
        puts "RESTORE_INFO: wcfg file not found";
    }

}

##################################################################
# MAIN FLOW
##################################################################

createProject 

# If exists restore block designes
puts "RESTORE_INFO: Try restore BDs";
set fileList [glob -nocomplain -directory $script_folder bd_des_*.tcl]
if {[llength $fileList]} {
    foreach tclGen $fileList {
        puts "RESTORE_INFO: Try execute $tclGen"
        source $tclGen
    }
} else {
    puts "RESTORE_INFO: BD restore tcl not found";
}

# If exists restore standalone IP cores
puts "RESTORE_INFO: Try restore IP cores";
if { [file exists "$script_folder/stand_alone_ip.tcl"] } {
    puts "RESTORE_INFO: Try execute $script_folder/stand_alone_ip.tcl"
    source [get_script_folder]/stand_alone_ip.tcl
} else {
    puts "RESTORE_INFO: Standalone IP not found";
}

# If defined, set top module
puts "RESTORE_INFO: Try restore top module";
if { $::env(topName) == 0 } {
    puts "RESTORE_INFO: Top module not defined"
} else {
    set_property top $::env(topName) [current_fileset]
}
