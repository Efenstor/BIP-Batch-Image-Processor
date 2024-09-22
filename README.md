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
