# Batch Image Processor using G'MIC

A script facilitating multithreaded processing of lots of images using the power of [G'MIC](https://gmic.eu/).

### Usage:
`gmicbp.sh [options] <input_dir> <output_dir> <cmd_file> [output_ext]`

For detailed help run the script without arguments.

### Notes:

* **cmd_file** should have one command at a line
* **cmd_file** can have *#comments*, empty lines and extra spaces
* input extension is case insensitive
* if **output_dir** does not exists it will be created
* if output file already exists it will be overwritten silently
* commands can be taken from the G'MIC plugin for GIMP (just press Ctrl+C)
* alternatively you can use the stand-alone version of G'MIC

### Tip:

To use the G'MIC filters from the "Testing" section you must update the filter definitions in the G'MIC plugin and then copy the latest update file to your home directory naming it `.gmic`:

`cp $(ls "$HOME/.config/gmic/"*.gmic | sort -n -r | head -n1) $HOME/.gmic`

Or in case you're using GIMP in a Flatpak:

`cp $(ls "$HOME/.var/app/org.gimp.GIMP/config/gmic"/*.gmic | sort -n -r | head -n1) $HOME/.gmic`
