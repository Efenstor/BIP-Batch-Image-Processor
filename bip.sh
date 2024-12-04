#!/bin/sh
# Copyleft Efenstor, 2024
version=2024.12-1

# Defaults
ncnn_path_default="$HOME/bin/ncnn-vulkan"

# Internal defines
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Ctrl+C trap
ctrlc() {
  printf "${YELLOW}Cancelled...${NC}\n"
  if [ "$pids" ]; then
    kill $pids
  fi
  exit 255
}

error() {
  printf "${RED}Error $err. Exiting...${NC}\n"
  if [ "$pids" ]; then
    kill $pids
  fi
  exit $err
}

wait_pids() {
  thr_free=0
  while [ $thr_free -eq 0 ]
  do
    pids_upd=
    thr_free=$threads
    for pid in $(echo $pids); do
      if ps -p $pid > /dev/null; then
        thr_free=$((thr_free-1))
        pids_upd="$pids_upd $pid"
      fi
    done
    sleep .2
  done
  pids="$pids_upd"
}

new_proc() {
  cmd_i=1
  cmd_tot=$(echo "$commands" | wc -l)

  echo "$commands" | while read cmd
  do

    # Set input
    if [ $cmd_i -eq 1 ]; then
      # First command: direct input
      in_f="$1"
    else
      # Not the first command: use tmp file
      in_f="$tmp_file"
    fi

    # Set output
    if [ $cmd_i -eq $cmd_tot ]; then
      # Last command: direct output
      out_f="$2"
    else
      # Not the last command: use tmp file
      # Create a new tmp file
      tmp_file=$(mktemp -p "$out_dir" --suffix=.png)
      out_f="$tmp_file"
    fi

    # Process commands
    case "$cmd" in

    :*)
      # NCNN-Vulkan
      echo "($cmd_i/$cmd_tot) NCNN-Vulkan command:"
      cmd="$(echo "$cmd -i \"$in_f\" -o \"$out_f\"" | cut -c 2-)"
      echo "$cmd"
      eval "$ncnn_path/$cmd"
      ;;

    *)
      # GMIC
      echo "($cmd_i/$cmd_tot) G'MIC command:"
      echo "$cmd"
      if [ "$out_ext_lc" = "jpg" ] && [ $cmd_i -eq $cmd_tot ]; then
        # Write as JPEG if the extension if .jpg and it's the last command
        gmic \"$in_f\" $cmd -o \"$out_f\",$jpeg_quality; err=$?
      else
        # Write as something else
        gmic \"$in_f\" $cmd -o \"$out_f\"; err=$?
      fi
      if [ $err -ne 0 ]; then return $err; fi
      ;;

    esac

    # If it's not the first command...
    if [ $cmd_i -gt 1 ]; then
      # ...then the input was a tmp file and we must remove it
      rm "$in_f"
    fi

    cmd_i=$(($cmd_i+1))
  done

  return 0
}

prepare_out_dir() {
  if [ ! -d "$out_dir" ]; then
    mkdir "$out_dir"
  elif [ "$out_dir" != "." ] && [ $(ls -A "$out_dir" | wc -l) -ne 0 ]; then
    read -p "Output dir already exists. Purge it? Y/n " ans
    if [ "$ans" != "n" ]; then
      echo "Purging the output dir..."
      rm -r "$out_dir"
      mkdir "$out_dir"
    fi
  fi
}

# Parse the named parameters
optstr="?he:q:t:g:d:n:r:"
threads=$(nproc --all)
in_ext="*"
out_ext="jpg"
jpeg_quality="95"
in_depth=1
ncnn_path="$ncnn_path_default"
repeat=0
while getopts $optstr opt
do
  case "$opt" in
    e) in_ext="$OPTARG" ;;
    q) jpeg_quality=$OPTARG ;;
    t) threads=$OPTARG ;;
    g) gmic_path="$OPTARG" ;;
    d) if [ $OPTARG -gt 0 ]; then
         in_depth=$OPTARG
       else
         in_depth=
       fi
       ;;
    n) ncnn_path="$OPTARG" ;;
    r) repeat=$OPTARG ;;
    :) echo "Missing argument for -$OPTARG" >&2
       exit 1
       ;;
  esac
done
shift $(expr $OPTIND - 1)

# Find gmic
if [ ! "$gmic_path" ]; then
  gmic_path="$(which gmic)"
  if [ ! "$gmic_path" ]; then
    printf "${RED}G'MIC not found. Please install it or specify the path with -g <str>${NC}\n"
    exit
  fi
fi

# Help
if [ $# -lt 3 ]; then
  printf "
${YELLOW}Batch Image Processor for G'MIC and NCNN-Vulkan tools${NC}
Version $version, Copyleft Efenstor
\n${GREEN}Usage:${NC} bip.sh [options] <input> <output> <cmd_file> [output_ext]
\n${CYAN}input:${NC} directory (batch mode) or file (single-file mode)
${CYAN}output:${NC} directory (any mode) or file (single-file mode)
${CYAN}cmd_file:${NC} file containing G'MIC or NCNN-Vulkan commands
${CYAN}output_ext:${NC} output extension/format (default=jpg)
\n${CYAN}Options:${NC}
  -e <str>: input extension (default=*)
  -q <num>: output JPEG quality (default=95)
  -d <num>: input directory depth (default=1), -1 = infinite
  -t <num>: number of simultaneous processes (default=number of CPU cores)
  -n <str>: custom path to NCNN-Vulkan CLI tools
            (default=$ncnn_path_default)
  -g <str>: custom path to gmic
  -r <num>: in single-file mode repeat processing producing <num> variants
            from a single source (<output> must be a directory, files will have
            names 00000001.[output_ext], 00000002.[output_ext], etc.)
\n${CYAN}Example:${NC} ./bip.sh -e jpg . output cmd.txt png
\n${CYAN}NCNN-Vulkan command example:${NC}
  :waifu2x-ncnn-vulkan -n 2 -m models-upconv_7_photo
  Don't add -i and -o as those will be added automatically
\n${CYAN}Notes:${NC}
  - <cmd_file> should have one command at a line
  - <cmd_file> can have #comments, empty lines and extra spaces
  - <input> extension is case insensitive
  - if <output> directory does not exists it will be created
  - if <output> file already exists it will be overwritten silently
  - commands can be taken from the G'MIC plugin for GIMP (just press Ctrl+C)
  - alternatively you can use the stand-alone version of G'MIC
\n"
  exit
fi

# Preliminary checks
if [ ! -e "$1" ]; then
  echo "Input directory or file does not exist. Exiting..."
  exit
fi
if [ ! -e "$3" ]; then
  echo "Command file does not exist. Exiting..."
  exit
fi

printf "${GREEN}Preparing...${NC}\n"

# Detect mode and set parameters
if [ "$4" ]; then
  out_ext="$4"
fi
if [ -d "$1" ]; then
  # Directory source
  printf "${YELLOW}MODE: batch${NC}\n"
  mode=batch
  in_dir="$1"
  out_dir="$2"
  prepare_out_dir
else
  # File source
  printf "${YELLOW}MODE: single-file${NC}\n"
  mode=sf
  in_file="$1"
  bn=$(basename "$in_file")
  n="${bn%.*}"
  out_e="${2##*.}"
  if [ "$out_e" = "$2" ]; then out_e=; fi
  if [ -d "$2" ] || [ ! "$out_e" ]; then
    # Out is dir name
    if [ $repeat -eq 0 ]; then
      # Single-file mode
      out_file="$2"/"$n.$out_ext"
      out_dir=$(dirname "$out_file")
    else
      # Single-file+repeat mode
      out_dir="$2"
      prepare_out_dir
    fi
  else
    # Out is file name
    out_file="$2"
    out_ext="${out_file##*.}"
    out_dir=$(dirname "$out_file")
    repeat=0  # Disable repeat mode unconditionally
  fi
fi
cmd_file="$3"
out_ext_lc=$(echo "$out_ext" | tr [:upper:] [:lower:])
if [ $mode = sf ]; then
  echo "Input file: $in_file"
  if [ $repeat -eq 0 ]; then
    echo "Output file: $out_file"
  fi
else
  echo "Input dir: $in_dir"
fi
echo "Output dir: $out_dir"
echo "Output extension: $out_ext"
echo "Command file: $cmd_file"

# Prepare commands
prv_cmd_type=none
while read -r cmd
do

  # Remove extra spaces
  cmd=$(echo "$cmd" | sed "s/^ *//;s/ *$//")
  if [ ! "$cmd" ] || [ $(echo "$cmd" | cut -c1) = "#" ]; then
    # Empty line or a comment
    continue
  fi

  # Command type
  case "$cmd" in
    :*) cmd_type=ncnn ;;
    *) cmd_type=gmic ;;
  esac
  if [ $cmd_type != gmic ] || [ $cmd_type != $prv_cmd_type ]; then
    # Non-G'MIC command or first G'MIC command
    if [ ! "$commands" ]; then
      commands="$cmd"
    else
      commands="$commands\n$cmd"
    fi
  else
    # Append a G'MIC command
    commands="$commands $cmd"
  fi
  prv_cmd_type=$cmd_type

done < "$cmd_file"

# Processing
printf "${GREEN}Processing...${NC}\n"
trap "ctrlc" INT
if [ $mode = batch ] || [ $repeat -gt 0 ] ; then

  # Batch/repeat mode
  if [ $repeat -eq 0 ]; then
    # Make the source file list
    files=$(find "$in_dir" ${in_depth:+-maxdepth $in_depth} -type f -iname "*.$in_ext" | sort -n -f)
  fi

  # Process
  i=0
  while [ -n "$files" ] || [ $i -lt $repeat ]
  do

    # Wait for threads to free up and update the pids list
    wait_pids
    printf "${CYAN}Threads free:${NC} ${YELLOW}$thr_free/$threads${NC}\n"

    # Run new threads
    if [ $repeat -eq 0 ]; then
      # Batch mode
      while [ $thr_free -gt 0 ] && [ -n "$files" ]
      do
        f=$(echo "$files" | head -n 1)
        f_basename=$(basename "$f")
        of="$out_dir"/"${f_basename%.*}.$out_ext"
        new_proc "$f" "$of" & pids="$pids $!"; err=$?
        if [ $err -ne 0 ]; then
          error
        fi
        thr_free=$((thr_free-1))
        files=$(echo "$files" | tail -n +2)
      done
    else
      # Single file+repeat mode
      while [ $thr_free -gt 0 ] && [ $i -lt $repeat ]
      do
        f=$(printf "%08d" $(($i+1)) )
        of="$out_dir"/"$f.$out_ext"
        new_proc "$in_file" "$of" & pids="$pids $!"; err=$?
        if [ $err -ne 0 ]; then
          error
        fi
        thr_free=$((thr_free-1))
        i=$(($i+1))
      done
    fi

  done

  # Wait for all remaining threads to finish
  tfprev=$thr_free
  while [ -n "$pids" ]
  do
    wait_pids
    if [ $thr_free -ne $tfprev ]; then
      printf "${CYAN}Threads free:${NC} ${YELLOW}$thr_free/$threads${NC}\n"
      tfprev=$thr_free
    fi
  done

else

  # Single-file mode
  new_proc "$in_file" "$out_file"; err=$?
  if [ $err -ne 0 ]; then
    error
  fi

fi

# Done
printf "${GREEN}Done!${NC}\n"

