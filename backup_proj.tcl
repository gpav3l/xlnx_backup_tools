set env(backup_path) [file dirname [file normalize [info script]]]

cd $::env(backup_path)
source gen_config.tcl
source user_config.tcl

###########################################
# Create folder structure
###########################################    
proc gen_folder_structure { outPath } {
    file mkdir "$outPath/$::env(ipRepoPath)"
    file mkdir "$outPath/$::env(hdlPath)"
    file mkdir "$outPath/$::env(xdcPath)"
    file mkdir "$outPath/$::env(testPath)"
    file mkdir "$outPath/$::env(waveConfig)"
    file mkdir "$outPath/$::env(hlsSrcs)"
    file mkdir "$outPath/$::env(swSrcs)"
    file mkdir "$outPath/$::env(swRepos)"
}

################################################
# Process to check and copy files
################################################
proc copy_files { inpFileList destPath excludePattern } {
    foreach filename $inpFileList {
        set isCopy true
               
        foreach mask $excludePattern {
            if [ regexp $mask $filename ] {
                set isCopy false
                break
            }
        }
        
        if { $isCopy } {
            if ![ regexp [file normalize $destPath] [file dirname [file normalize $filename]] ] {
                    file copy -force [file normalize $filename] $destPath 
            }
        }
    }    
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

###########################################
# Check is tcl file of backup folder exists
###########################################
proc check_tcls { outPath } {
    set isFound 0
    puts $outPath
    
    if { [file exists "$outPath/restore_vivado.tcl"] } {
        puts "BCKUP_INFO: restore_vivado.tcl is found"
    } else {
        puts "BCKUP_INFO: restore_vivado.tcl is not found"
        set isFound 1
    }
    
    # Create all necesary folder if it not exist
    gen_folder_structure $outPath
    
    return $isFound
}

###########################################
# Generate config.tcl
###########################################
proc gen_config { outPath } {
    set f [open "$outPath/gen_config.tcl" w]
    
    set projName [get_property NAME [get_projects]]
    puts $f "set env(projName) $projName" 
    
    set temp [get_property BOARD_PART [get_projects]]
    if { $temp ne "" } {
        puts $f "set env(boardPart) $temp" 
    } else {
        puts $f "set env(boardPart) 0" 
    }
    
    set temp [get_property PART [get_projects]]
    puts $f "set env(partMark) $temp" 
    
    set temp [version -short]
    puts $f "set env(vivadoVersion) $temp" 
    
    set temp [get_property TOP [get_filesets sources_1]]
    if { $temp ne "" } {
        puts $f "set env(topName) $temp" 
    } else {
        puts $f "set env(topName) 0" 
    }
    
        
    close $f
}

###########################################
# Generate tcl for every block designes of project
###########################################
proc gen_bd_tcl { outPath } {
    set prj_path [get_property DIRECTORY [current_project]]
    foreach bd_item [ get_files *.bd ] {
        set proc_descr 0
        open_bd_design $bd_item
        set bd_name [current_bd_design]
        write_bd_tcl -force $prj_path/bd_des_$bd_name.tcl
                
        set fout [open "$outPath/bd_des_$bd_name.tcl" w]
        set fin [open "$prj_path/bd_des_$bd_name.tcl" r]
        set content [read $fin]
        
        # Write out only part of describe build of block designe
        foreach line [split $content \n] {
            if [ regexp {^# DESIGN PROCs} $line ] {
                set proc_descr 1
            }
            
            if { $proc_descr == 1 } {
                if [ regexp {^# MAIN FLOW} $line ] {
                    set proc_descr 0
                } else {
                    puts $fout $line
                }
            }
        }
        close $fin 
        
        puts $fout "create_bd_design $bd_name"
        puts $fout "current_bd_design $bd_name"
        puts $fout "create_root_design \"\""
        puts $fout "regenerate_bd_layout"
        puts $fout "make_wrapper -files \[get_files \$::env(buildPath)/\$::env(projName).srcs/sources_1/bd/$bd_name/$bd_name.bd\] -top"
        puts $fout "add_files -norecurse \$::env(buildPath)/\$::env(projName).srcs/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v"
        
        close $fout
        close_bd_design $bd_name
    }
}

###########################################
# Get IP out of BD
###########################################
proc gen_alone_ip_tcl { outPath } {
    set fout [open "$outPath/stand_alone_ip.tcl" w]
    foreach ipItem [get_ips -exclude_bd_ips] { 
        puts "BCKUP_INFO: Add IP $ipItem: \n";
        
        set prop [list_property [get_ips $ipItem] -regexp {^IPDEF$}]
        lassign [split [get_property $prop [get_ips $ipItem]] :] vendor library name version
        puts $fout "create_ip -name $name -vendor $vendor -library $library -version $version -module_name $ipItem"
        
        puts $fout "set_property -dict \[list \\"
        foreach prop [list_property [get_ips $ipItem] -regexp {^CONFIG\.\w+$}] {
            if {[get_property $prop\.value_src [get_ips $ipItem]] != "DEFAULT"} {
                #puts "$prop = [get_property $prop [get_ips $ipItem]] ([get_property $prop\.value_src [get_ips $ipItem]])"
                puts $fout "\t$prop {[get_property $prop [get_ips $ipItem]]} \\"
            }
        }
        puts $fout "] \[get_ips $ipItem\]\n"
        
    }
    close $fout
    puts "Search in $outPath"
    if { [file size "$outPath/stand_alone_ip.tcl"] == 0 } {
        file delete "$outPath/stand_alone_ip.tcl"
    }
    
}

################################################
# Check HDL, WCFG and XDC file and copy it to backup folder
################################################
proc check_sources { outPath } {
        
    puts "Waveform configs"
    foreach fset [get_filesets -filter { FILESET_TYPE == SimulationSrcs }] {
        copy_files [get_files -of_objects [get_filesets $fset]] "$outPath/$::env(waveConfig)" "/bd/ \.xci$ \.v$ \.vs$ \.vhdl$"
    }
    
    puts "Simaulation sources"
    foreach fset [get_filesets -filter { FILESET_TYPE == SimulationSrcs }] {
        copy_files [get_files -of_objects [get_filesets $fset]] "$outPath/$::env(testPath)" "/bd/ \.xci$ \.wcfg$"
    }
        
    puts "Constraints sources"
    foreach fset [get_filesets -filter { FILESET_TYPE == Constrs }] {
        copy_files [get_files -of_objects [get_filesets $fset]] "$outPath/$::env(xdcPath)" "/bd/"
    }
       
    puts "Designe sources"
    foreach fset [get_filesets -filter { FILESET_TYPE == DesignSrcs }] {
        copy_files [get_files -of_objects [get_filesets $fset]] "$outPath/$::env(hdlPath)" "\.xci$ /bd/"
    }
}

################################################
# Main function call for backup current project
################################################
proc backup_vivado { } {
   
   set outPath $::env(backup_path)
   
    if { [check_tcls $outPath] != 0 } {
        puts "BCKUP_ERROR: Wrong backup folder, exit"
        return 1
    }
    
    puts "BCKUP_INFO: Check and copy sources"
    check_sources $outPath
    
    puts "BCKUP_INFO: Generate config tcl"
    gen_config $outPath
    
    puts "BCKUP_INFO: Generate BD tcl's"
    gen_bd_tcl $outPath
    
    puts "BCKUP_INFO: Generate IP tcl's"
    gen_alone_ip_tcl $outPath
    
    puts "BCKUP_INFO: Finish backup project"
    
}


