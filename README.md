# Batch Image Processor using G'MIC

A script facilitating multithreaded processing of lots of images using the power of [G'MIC](https://gmic.eu/).

### Usage:
`gmicbp.sh [options] <input_dir> <output_dir> <cmd_file> [output_ext]`

For detailed description of the arguments run the script without any arguments or with **-h**.

### Tip:

To use the G'MIC filters from the "Testing" section you must update the filter definitions in the G'MIC plugin and then copy the latest update file to your home directory naming it `.gmic`:

`cp $(ls "$HOME/.config/gmic/"*.gmic | sort -n -r | head -n1) $HOME/.gmic`

Or in case you're using GIMP in a Flatpak:

`cp $(ls "$HOME/.var/app/org.gimp.GIMP/config/gmic"/*.gmic | sort -n -r | head -n1) $HOME/.gmic`
