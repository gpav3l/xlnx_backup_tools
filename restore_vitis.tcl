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


################################################################
# Get list of software projects
################################################################
proc get_proj_list { searchFolder }  {
    set basedir [string trimright [file join [file normalize $searchFolder/$::env(swSrcs)] { }]]
    set projList {}
    foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
        lappend projList [lindex [split $dirName '/'] end]
    }
    return $projList
}

# Add domains for all projects
platform create -name $::env(topName)_hw_plarform -hw $::env(buildPath)/$::env(topName).xsa
foreach projName [get_proj_list $script_folder] {
    set projDir $script_folder/$::env(swSrcs)/$projName/

    domain create -name dom_$projName -os standalone -proc {ps7_cortexa9_0}
    if { [file exists $projDir/bsp_init.tcl] } {
        source $projDir/bsp_init.tcl
    }
}

platform generate

# Add application projects
foreach projName [get_proj_list $script_folder] {
    set projDir $script_folder/$::env(swSrcs)/$projName/
    app create -name $projName -platform $::env(topName)_hw_plarform -domain dom_$projName -template {Empty Application}
    app config -name $projName libraries m

    exec rm -r [getws]/$projName/src
    file link -symbolic [getws]/$projName/src $projDir/sw_srcs
}
