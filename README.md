# BIP - Batch Image Processor for G'MIC and NCNN-Vulkan tools

A script facilitating multithreaded processing of lots of images using the power of **[G'MIC](https://gmic.eu/)** and various **NCNN-Vulkan** CLI tools, such as:

  * [waifu2x](https://github.com/nihui/waifu2x-ncnn-vulkan)
  * [RealSR](https://github.com/nihui/realsr-ncnn-vulkan)
  * [Real-CUGAN](https://github.com/nihui/realcugan-ncnn-vulkan)
  * [SRMD](https://github.com/nihui/srmd-ncnn-vulkan)
  * [GFPGAN](https://github.com/onuralpszr/GFPGAN-ncnn-vulkan)
  * [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan)
  * [SPAN](https://github.com/TNTwise/SPAN-ncnn-vulkan)

### Usage:

**bip.sh [options] <input\> <output\> <cmd_file\> [output_ext]**

```
input: directory (batch mode) or file (single-file mode)
output: directory (any mode) or file (single-file mode)
cmd_file: file containing G'MIC or NCNN-Vulkan commands
output_ext: output extension/format (default=jpg)

Options:
  -e <str>: input extension (default=*)
  -q <num>: output JPEG quality (default=95)
  -d <num>: input directory depth (default=1), -1 = infinite
  -t <num>: number of simultaneous processes (default=number of CPU cores)
  -n <str>: custom path to NCNN-Vulkan CLI tools
            (default=/home/olaf/bin/ncnn-vulkan)
  -g <str>: custom path to gmic
  -r <num>: in single-file mode repeat processing producing <num> variants
            from a single source (<output> must be a directory, files will have
            names 00000001.[output_ext], 00000002.[output_ext], etc.)

Example: ./bip.sh -e jpg . output cmd.txt png

NCNN-Vulkan command example:
  :waifu2x-ncnn-vulkan -n 2 -m models-upconv_7_photo
  Don't add -i and -o as those will be added automatically

Notes:
  - <cmd_file> should have one command at a line
  - <cmd_file> can have #comments, empty lines and extra spaces
  - <input> extension is case insensitive
  - if <output> directory does not exists it will be created
  - if <output> file already exists it will be overwritten silently
  - commands can be taken from the G'MIC plugin for GIMP (just press Ctrl+C)
  - alternatively you can use the stand-alone version of G'MIC
```

### Tip:

To use the G'MIC filters from the "Testing" section you must update the filter definitions in the G'MIC plugin and then copy the latest update file to your home directory naming it `.gmic`:

`cp $(ls "$HOME/.config/gmic/"*.gmic | sort -n -r | head -n1) $HOME/.gmic`

Or in case you're using GIMP in a Flatpak:

`cp $(ls "$HOME/.var/app/org.gimp.GIMP/config/gmic"/*.gmic | sort -n -r | head -n1) $HOME/.gmic`
