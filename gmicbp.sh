#!/bin/sh
# Copyleft Efenstor, 2024
version=2024.09-1

# Internal defines
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Ctrl+C trap
ctrlc() {
  kill $pids
  printf "${YELLOW}Cancelled...${NC}\n"
  exit 255
}

error() {
  printf "${RED}Error $err. Exiting...${NC}\n"
  kill $pids
  exit $err
}

wait_pids() {
  thr_free=0
  while [ $thr_free -eq 0 ]:
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

# Parse the named parameters
optstr="?he:q:t:g:d:"
threads=$(nproc --all)
in_ext="*"
out_ext="jpg"
jpeg_quality="95"
in_depth=1
while getopts $optstr opt; do
  case "$opt" in
    e) in_ext=$OPTARG ;;
    q) jpeg_quality=$OPTARG ;;
    t) threads=$OPTARG ;;
    g) gmic_path=$OPTARG ;;
    d) if [ $OPTARG -gt 0 ]; then
         in_depth=$OPTARG
       else
         in_depth=
       fi
       ;;
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
${YELLOW}Batch Image Processor using G'MIC${NC}
Version $version, Copyleft Efenstor
\n${GREEN}Usage:${NC} gmicbp.sh [options] <input_dir> <output_dir> <cmd_file> [output_ext]
\n${CYAN}cmd_file:${NC} file containing G'MIC commands
${CYAN}output_ext:${NC} output extension/format (default=jpg)
\n${CYAN}Options:${NC}
  -e <str>: input extension (default=*)
  -q <num>: output JPEG quality (default=95)
  -d <num>: input directory depth (default=1), -1 = infinite
  -t <num>: number of simultaneous processes (default=number of CPU cores)
  -g <str>: custom path to gmic
\n${CYAN}Example:${NC} ./gmic_batch_proc.sh -e jpg . output cmd.txt png
\n${CYAN}Notes:${NC}
  - cmd_file should have one command at a line
  - cmd_file can have #comments, empty lines and extra spaces
  - input extension is case insensitive
  - if output_dir does not exists it will be created
  - if output file already exists it will be overwritten silently
  - commands can be taken from the G'MIC plugin for GIMP (just press Ctrl+C)
  - alternatively you can use the stand-alone version of G'MIC
\n"
  exit
fi

# Parameters
in_dir="$1"
out_dir="$2"
cmd_file="$3"
if [ "$4" ]; then
  out_ext="$4"
fi
out_ext_lc=$(echo "$out_ext" | tr [:upper:] [:lower:])

# Prepare directories
if [ ! -d "$in_dir" ]; then
  echo "Input dir does not exist. Exiting..."
  exit
fi
if [ ! -d "$out_dir" ]; then
  mkdir "$out_dir"
else
  read -p "Output dir already exists. Purge it? Y/n " ans
  if [ "$ans" != "n" ]; then
    echo "Purging the output dir..."
    rm -r "$out_dir"
    mkdir "$out_dir"
  fi
fi

# Prepare commands
while read -r cmd; do
  # Remove extra spaces
  cmd=$(echo "$cmd" | sed "s/^ *//;s/ *$//")
  if [ ! "$cmd" ] || [ $(echo "$cmd" | cut -c1) = "#" ]; then
    # Empty line or a comment
    continue
  fi
  if [ ! "$gmic_commands" ]; then
    # First command
    gmic_commands="$cmd"
  else
    # Following commands
    gmic_commands="$gmic_commands $cmd"
  fi
done < "$cmd_file"

# Main multi-threaded processing
printf "${GREEN}Processing...${NC}\n"
files=$(find "$in_dir" ${in_depth:+-maxdepth $in_depth} -type f -iname "*.$in_ext" | sort -n -f)
trap "ctrlc" INT
while [ -n "$files" ]; do

  # Wait for threads to free up and update the pids list
  wait_pids
  printf "${CYAN}Threads free:${NC} ${YELLOW}$thr_free/$threads${NC}\n"

  # Run new threads
  while [ $thr_free -gt 0 ] && [ -n "$files" ]; do
    f=$(echo "$files" | head -n 1)
    f_basename=$(basename "$f")
    of="$out_dir"/"${f_basename%.*}.$out_ext"
    if [ "$out_ext_lc" = "jpg" ]; then
      gmic "$f" $gmic_commands -o "$of",$jpeg_quality & err=$?; pids="$pids $!"
    else
      gmic "$f" $gmic_commands -o "$of" & err=$?; pids="$pids $!"
    fi
    if [ $err -ne 0 ]; then
      error
    fi
    thr_free=$((thr_free-1))
    files=$(echo "$files" | tail -n +2)
  done

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

# Done
printf "${GREEN}Done!${NC}\n"

