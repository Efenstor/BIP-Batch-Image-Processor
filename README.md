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
`bip.sh [options] <input> <output> <cmd_file> [output_ext]`

For detailed description of the arguments run the script without any arguments or with **-h**.

### Tip:

To use the G'MIC filters from the "Testing" section you must update the filter definitions in the G'MIC plugin and then copy the latest update file to your home directory naming it `.gmic`:

`cp $(ls "$HOME/.config/gmic/"*.gmic | sort -n -r | head -n1) $HOME/.gmic`

Or in case you're using GIMP in a Flatpak:

`cp $(ls "$HOME/.var/app/org.gimp.GIMP/config/gmic"/*.gmic | sort -n -r | head -n1) $HOME/.gmic`
