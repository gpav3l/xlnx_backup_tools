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
set env(appName) app1

platform create -name $::env(topName)_hw_plarform -hw $::env(buildPath)/$::env(topName).xsa
domain create -name dom_standalone -os standalone -proc {psu_cortexa53_0}

platform generate

app create -name $::env(appName) -platform $::env(topName)_hw_plarform -domain dom_standalone -template {Empty Application}
app config -name $::env(appName) libraries m

exec rm -r [getws]/$::env(appName)/src
file link -symbolic [getws]/$::env(appName)/src $script_folder/sw_srcs

app build -name $::env(appName)
