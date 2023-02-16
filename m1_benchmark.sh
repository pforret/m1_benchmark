#!/usr/bin/env bash
### ==============================================================================
### SO HOW DO YOU PROCEED WITH YOUR SCRIPT?
### 1. define the options/parameters and defaults you need in list_options()
### 2. define dependencies on other programs/scripts in list_dependencies()
### 3. implement the different actions in main() with helper functions
### 4. implement helper functions you defined in previous step
### ==============================================================================

### Created by Peter Forret ( pforret ) on 2021-01-07
### Based on https://github.com/pforret/bashew 1.12.1
script_version="0.0.1" # if there is a VERSION.md in this script's folder, it will take priority for version number
readonly script_author="peter@forret.com"
readonly script_created="2021-01-07"
readonly run_as_root=-1 # run_as_root: 0 = don't check anything / 1 = script MUST run as root / -1 = script MAY NOT run as root

list_options() {
  ### Change the next lines to reflect which flags/options/parameters you need
  ### flag:   switch a flag 'on' / no extra parameter
  ###     flag|<short>|<long>|<description>
  ###     e.g. "-v" or "--verbose" for verbose output / default is always 'off'
  ### option: set an option value / 1 extra parameter
  ###     option|<short>|<long>|<description>|<default>
  ###     e.g. "-e <extension>" or "--extension <extension>" for a file extension
  ### param:  comes after the options
  ###     param|<type>|<long>|<description>
  ###     <type> = 1 for single parameters - e.g. param|1|output expects 1 parameter <output>
  ###     <type> = ? for optional parameters - e.g. param|1|output expects 1 parameter <output>
  ###     <type> = n for list parameter    - e.g. param|n|inputs expects <input1> <input2> ... <input99>
  echo -n "
#commented lines will be filtered
flag|h|help|show usage
#flag|q|quiet|no output
flag|v|verbose|output more
#flag|f|force|do not ask for confirmation (always yes)
option|l|log_dir|folder for log files |$HOME/log/$script_prefix
option|t|tmp_dir|folder for temp files|.tmp
param|1|action|action to perform: run/list
" |
    grep -v '^#' |
    sort
}

list_dependencies() {
  ### Change the next lines to reflect which binaries(programs) or scripts are necessary to run this script
  # Example 1: a regular package that should be installed with apt/brew/yum/...
  #curl
  # Example 2: a program that should be installed with apt/brew/yum/... through a package with a different name
  #convert|imagemagick
  # Example 3: a package with its own package manager: basher (shell), go get (golang), cargo (Rust)...
  #progressbar|basher install pforret/progressbar
  echo -n "
gawk
ffmpeg
convert|imagemagick
primitive|go get -u github.com/fogleman/primitive
" |
    grep -v "^#" |
    sort
}

#####################################################################
## Put your main script here
#####################################################################

main() {
  debug "Program: $script_basename $script_version"
  debug "Created: $script_created"
  debug "Updated: $script_modified"
  debug "Run as : $USER@$HOSTNAME"

  require_binaries
  log_to_file "[$script_basename] $script_version started"

  action=$(lower_case "$action")
  case $action in
  check)
    #TIP: use «$script_prefix check» to check if this script is ready to execute (all necessary binaries/scripts exist)
    #TIP:> $script_prefix check
    echo -n "$char_succ Dependencies: "
    list_dependencies | cut -d'|' -f1 | sort | xargs
    ;;

  run)
    #TIP: use «$script_prefix run» to run all the benchmarks
    #TIP:> $script_prefix run

    input="$script_install_folder/sources/david-marcu-o0RZkkL072U-unsplash.jpg"
    architecture=$(arch)
    result_folder="$script_install_folder/results/$os_name-$os_version"
    [[ ! -d "$result_folder" ]] && mkdir -p "$result_folder"
    case "$os_kernel" in
    Darwin)
      machine_type=$(system_profiler SPHardwareDataType | awk -F: '/Model Identifier/ {gsub(" ",""); print $2}')
      machine_hardware=$(sysctl -n machdep.cpu.brand_string)
      ram_bytes=$(sysctl -n hw.memsize)
      cpu_count=$(sysctl -n hw.ncpu)
      gpu_type=$(system_profiler SPDisplaysDataType | grep Chipset | cut -d: -f2 | xargs)
      install_date=$(< /var/log/install.log awk 'NR == 1 {print $1}')
      ;;
    *)
      machine_type=$(uname -r | get_clean 1)
      machine_hardware="?"
      command -v lscpu &>/dev/null && machine_hardware=$(lshw 2>/dev/null | awk -F: '/product/ {gsub(" ",""); print $2}')
      ram_bytes="?"
      command -v free &>/dev/null && ram_bytes=$(free -b | awk '/Mem:/ {gsub(" ",""); print $2}')
      cpu_count="?"
      [[ -f /proc/cpuinfo ]] && cpu_count=$(< /proc/cpuinfo awk 'BEGIN {cores=0} /^processor/ {cores++;} END {print cores}')
      gpu_type="?"
      install_date="?"
      [[ -d "/var" ]] && install_date=$(find /var -maxdepth 1 -type d -exec stat -c %y {} \; | sort | head -1 | cut -d' ' -f1)
    esac

    ram_gib=$(( ram_bytes / 1073741824 ))
    unique=$(echo "$HOSTNAME $os_name $os_machine $architecture" | hash)
    output="$result_folder/$execution_day-$machine_type-$unique.md"
    debug "output: $output"
    declare -a indexes
    (
      echo "# $os_name $os_version $architecture"
      echo "* Script executed : $execution_day"
      echo "* Script version  : $script_version - $script_modified"
      echo "* Hardware details: $machine_type - $cpu_count CPUs - $ram_gib GiB RAM - $gpu_type GPU"
      echo "* CPU Details     : $machine_hardware"
      echo "* OS Details      : $os_name $os_version"
      echo "* OS Install date : $install_date"
      echo "* all indexes     : Apple Mac Mini M1 2020 8GB = 100%"

      # shellcheck disable=SC2154
      [[ -n $(command -v ffmpeg) ]] && benchmark_ffmpeg "$input" "$tmp_dir/xfade.mp4"
      [[ -n $(command -v primitive) ]] && benchmark_primitive "$input" "$tmp_dir/primitive.gif"

      echo " "
      echo "* Combined performance index: $(combine_results) %"
    ) | tee "$output"

    ;;

  list)
    #TIP: use «$script_prefix list» to show all results
    #TIP:> $script_prefix list input.txt output.pdf
  find "$script_install_folder/results" -type f -name \*.md \
  | sort \
  | while read -r result ; do
      echo "-----"
      echo "## $(basename "$result" .md)"
      < "$result" grep -i -e "Hardware details" -e "index:" -e "CPU details" -e "Max CPU" -e "OS Details"
    done
    ;;

  *)
    die "action [$action] not recognized"
    ;;
  esac
  log_to_file "[$script_basename] ended after $SECONDS secs"
  #TIP: >>> bash script created with «pforret/bashew»
  #TIP: >>> for developers, also check «pforret/setver»
}

#####################################################################
## Put your helper scripts here
#####################################################################

stopwatch(){
  if [[ $1 == "start" ]] ; then
    t_start=$(date '+%s')
    debug "* start benchmark $benchmark @ $SECONDS secs"
    if [[ "$os_kernel" == "Darwin" ]] ; then
      ( sleep 10 ; echo -n "* Max CPU: " ; top -F -l 5 -ncols 5 | awk "/$2/ {print \$3}" | sort -n | tail -1 )&
    else
      ( sleep 10 ; echo -n "* Max CPU: " ; top -n 5 -b | awk "/$2/ {print \$9}" | sort -n | tail -1 )&
    fi
  else
    t_stop=$(date '+%s')
    benchmark="$2"
    duration=$(( t_stop - t_start ))
    debug "* end benchmark @ $duration secs - benchmark = $2 secs"
    echo "* benchmark finished after: $duration secs"
    index=$(echo "$duration $benchmark" | awk '{printf("%.2f\n",100 * $2 / $1);}')
    echo "* performance index: $index %"
    # shellcheck disable=SC2031
    indexes+=("$index")
  fi
}

benchmark_ffmpeg() {
  # $1 = start image
  # $2 = output

  benchmark="XFADE"
  echo " "
  echo "## BENCHMARK $benchmark"
  lowres="$tmp_dir/$benchmark.lowres.jpg"
  original_size=$(identify -format "%wx%h\n" "$1")
  debug "* prep $benchmark: $SECONDS"
  convert "$1" -resize 5% -modulate 100,1 -resize "$original_size!" "$lowres"
  length=5
  fps=10
  FFMPEG=$(command -v ffmpeg)
  echo "* task: generating a cross-fade video with ffmpeg: $length secs @ $fps fps"
  echo "* image dimensions: $original_size"
  echo "* program: $FFMPEG - $($FFMPEG -version | head -1)"
  stopwatch start ffmpeg
  "$FFMPEG" -loop 1 -i "$lowres" -loop 1 -i "$1" -r "$fps" -vcodec libx264 -pix_fmt yuv420p \
    -filter_complex "[1:v][0:v]blend=all_expr='A*(if(gte(T,$length),1,T/$length))+B*(1-(if(gte(T,$length),1,T/$length)))'" \
    -t $length -y "$2" 2> /dev/null
  output_kb=$(du -k "$2" | awk '{print $1}')
  echo "* output size: $output_kb KB"
  stopwatch stop 75
}

benchmark_primitive() {
  # $1 = input jpeg file
  # $2 = output gif file
  benchmark="PRIMITIVE"
  echo " "
  echo "## BENCHMARK $benchmark"
  shapes=1000
  width=1200
  PRIMITIVE=$(command -v primitive)
  echo "* task: generating a primitive sequence: width: $width px / $shapes shapes"
  echo "* program: $PRIMITIVE (fogleman/primitive)"
  stopwatch start primitive
  "$PRIMITIVE" -i "$1" -o "$2" -s "$width" -n "$shapes" -m 7 -bg FFFFFF
  output_kb=$(du -k "$2" | awk '{print $1}')
  echo "* output size: $output_kb KB"
  stopwatch stop 95
}

combine_results(){
  for i in "${indexes[@]}"; do
    echo "$i"
  done \
  | awk '
    BEGIN {product=1;terms=0}
    {product = product * $1 / 100; terms++;}
    END {invert=1/terms; product=product ** invert; print int(product * 100)}
    '
}
#####################################################################
################### DO NOT MODIFY BELOW THIS LINE ###################
#####################################################################

# set strict mode -  via http://redsymbol.net/articles/unofficial-bash-strict-mode/
# removed -e because it made basic [[ testing ]] difficult
set -uo pipefail
IFS=$'\n\t'
# shellcheck disable=SC2120
hash() {
  length=${1:-6}
  # shellcheck disable=SC2230
  if [[ -n $(command -v md5sum) ]]; then
    # regular linux
    md5sum | cut -c1-"$length"
  else
    # macos
    md5 | cut -c1-"$length"
  fi
}

force=0
help=0
verbose=0
#to enable verbose even before option parsing
[[ $# -gt 0 ]] && [[ $1 == "-v" ]] && verbose=1
quiet=0
#to enable quiet even before option parsing
[[ $# -gt 0 ]] && [[ $1 == "-q" ]] && quiet=1

initialise_output() {
  [[ "${BASH_SOURCE[0]:-}" != "${0}" ]] && sourced=1 || sourced=0
  [[ -t 1 ]] && piped=0 || piped=1 # detect if output is piped
  if [[ $piped -eq 0 ]]; then
    col_reset="\033[0m"
    col_red="\033[1;31m"
    col_grn="\033[1;32m"
    col_ylw="\033[1;33m"
  else
    col_reset=""
    col_red=""
    col_grn=""
    col_ylw=""
  fi

  [[ $(echo -e '\xe2\x82\xac') == '€' ]] && unicode=1 || unicode=0 # detect if unicode is supported
  if [[ $unicode -gt 0 ]]; then
    char_succ="✔"
    char_fail="✖"
    char_alrt="➨"
    char_wait="…"
  else
    char_succ="OK "
    char_fail="!! "
    char_alrt="?? "
    char_wait="..."
  fi
  error_prefix="${col_red}>${col_reset}"

  local columns
  columns=$(tput cols 2>/dev/null || echo 80)
  wprogress=$((columns - 5))
  declare -r wprogress
}

out() { ((quiet)) || printf '%b\n' "$*"; }
debug() { ((verbose)) && out "${col_ylw}# $* ${col_reset}" >&2; }
die() {
  out "${col_red}${char_fail} $script_basename${col_reset}: $*" >&2
  tput bel
  safe_exit
}
alert() { out "${col_red}${char_alrt}${col_reset}: $*" >&2; } # print error and continue
success() { out "${col_grn}${char_succ}${col_reset}  $*"; }
announce() {
  out "${col_grn}${char_wait}${col_reset}  $*"
  sleep 1
}

progress() {
  ((quiet)) || (
    if is_set "${piped:-0}"; then
      out "$*" >&2
    else
      printf "... %-${wprogress}b\r" "$*                                             " >&2
    fi
  )
}

log_to_file() { [[ -n ${log_file:-} ]] && echo "$(date '+%H:%M:%S') | $*" >>"$log_file"; }

lower_case() { echo "$*" | awk '{print tolower($0)}'; }
upper_case() { echo "$*" | awk '{print toupper($0)}'; }

slugify() {
  # shellcheck disable=SC2020

  lower_case "$*" |
    tr \
      'àáâäæãåāçćčèéêëēėęîïííīįìłñńôöòóœøōõßśšûüùúūÿžźż' \
      'aaaaaaaaccceeeeeeeiiiiiiilnnoooooooosssuuuuuyzzz' |
    awk '{
    gsub(/[^0-9a-z ]/,"");
    gsub(/^\s+/,"");
    gsub(/^s+$/,"");
    gsub(" ","-");
    print;
    }' |
    cut -c1-50
}

confirm() {
  # $1 = question
  is_set $force && return 0
  read -r -p "$1 [y/N] " -n 1
  echo " "
  [[ $REPLY =~ ^[Yy]$ ]]
}

ask() {
  # $1 = variable name
  # $2 = question
  # $3 = default value
  # not using read -i because that doesn't work on MacOS
  local ANSWER
  read -r -p "$2 ($3) > " ANSWER
  if [[ -z "$ANSWER" ]]; then
    eval "$1=\"$3\""
  else
    eval "$1=\"$ANSWER\""
  fi
}

trap "die \"ERROR \$? after \$SECONDS seconds \n\
\${error_prefix} last command : '\$BASH_COMMAND' \" \
\$(< \$script_install_path awk -v lineno=\$LINENO \
'NR == lineno {print \"\${error_prefix} from line \" lineno \" : \" \$0}')" INT TERM EXIT
# cf https://askubuntu.com/questions/513932/what-is-the-bash-command-variable-good-for

safe_exit() {
  [[ -n "${tmp_file:-}" ]] && [[ -f "$tmp_file" ]] && rm "$tmp_file"
  trap - INT TERM EXIT
  debug "$script_basename finished after $SECONDS seconds"
  exit 0
}

is_set() { [[ "$1" -gt 0 ]]; }
is_empty() { [[ -z "$1" ]]; }
is_not_empty() { [[ -n "$1" ]]; }

is_file() { [[ -f "$1" ]]; }
is_dir() { [[ -d "$1" ]]; }

show_usage() {
  out "Program: ${col_grn}$script_basename $script_version${col_reset} by ${col_ylw}$script_author${col_reset}"
  out "Updated: ${col_grn}$script_modified${col_reset}"
  out "Description: Some benchmarks of MacOS M1 (Apple Silicon)"
  echo -n "Usage: $script_basename"
  list_options |
    awk '
  BEGIN { FS="|"; OFS=" "; oneline="" ; fulltext="Flags, options and parameters:"}
  $1 ~ /flag/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [flag] %s [default: off]",$2,$3,$4) ;
    oneline  = oneline " [-" $2 "]"
    }
  $1 ~ /option/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [option] %s",$2,$3 " <?>",$4) ;
    if($5!=""){fulltext = fulltext "  [default: " $5 "]"; }
    oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /secret/  {
    fulltext = fulltext sprintf("\n    -%1s|--%s <%s>: [secr] %s",$2,$3,"?",$4) ;
      oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /param/ {
    if($2 == "1"){
          fulltext = fulltext sprintf("\n    %-17s: [parameter] %s","<"$3">",$4);
          oneline  = oneline " <" $3 ">"
     }
     if($2 == "?"){
          fulltext = fulltext sprintf("\n    %-17s: [parameter] %s (optional)","<"$3">",$4);
          oneline  = oneline " <" $3 "?>"
     }
     if($2 == "n"){
          fulltext = fulltext sprintf("\n    %-17s: [parameters] %s (1 or more)","<"$3">",$4);
          oneline  = oneline " <" $3 " …>"
     }
    }
    END {print oneline; print fulltext}
  '
}

show_tips() {
  ((sourced)) && return 0
  grep <"${BASH_SOURCE[0]}" -v "\$0" |
    awk "
  /TIP: / {\$1=\"\"; gsub(/«/,\"$col_grn\"); gsub(/»/,\"$col_reset\"); print \"*\" \$0}
  /TIP:> / {\$1=\"\"; print \" $col_ylw\" \$0 \"$col_reset\"}
  " |
    awk \
      -v script_basename="$script_basename" \
      -v script_prefix="$script_prefix" \
      '{
    gsub(/\$script_basename/,script_basename);
    gsub(/\$script_prefix/,script_prefix);
    print ;
    }'
}

init_options() {
  local init_command
  init_command=$(list_options |
    awk '
    BEGIN { FS="|"; OFS=" ";}
    $1 ~ /flag/   && $5 == "" {print $3 "=0; "}
    $1 ~ /flag/   && $5 != "" {print $3 "=\"" $5 "\"; "}
    $1 ~ /option/ && $5 == "" {print $3 "=\"\"; "}
    $1 ~ /option/ && $5 != "" {print $3 "=\"" $5 "\"; "}
    ')
  if [[ -n "$init_command" ]]; then
    eval "$init_command"
  fi
}

require_binaries() {
  debug "Running: $os_name ($os_version)"
  [[ -n "${ZSH_VERSION:-}" ]] && debug "Running: zsh $ZSH_VERSION"
  [[ -n "${BASH_VERSION:-}" ]] && debug "Running: bash $BASH_VERSION"
  local required_binary
  local install_instructions

  while read -r line; do
    required_binary=$(echo "$line" | cut -d'|' -f1)
    [[ -z "$required_binary" ]] && continue
    # shellcheck disable=SC2230
    debug "Check for existence of [$required_binary]"
    [[ -n $(command -v "$required_binary") ]] && continue
    required_package=$(echo "$line" | cut -d'|' -f2)
    if [[ $(echo "$required_package" | wc -w) -gt 1 ]]; then
      # example: setver|basher install setver
      install_instructions="$required_package"
    else
      [[ -z "$required_package" ]] && required_package="$required_binary"
      if [[ -n "$install_package" ]]; then
        install_instructions="$install_package $required_package"
      else
        install_instructions="(install $required_package with your package manager)"
      fi
    fi
    alert "$script_basename needs [$required_binary] but it cannot be found"
    alert "1) install package  : $install_instructions"
    alert "2) check path       : export PATH=\"[path of your binary]:\$PATH\""
    die "Missing program/script [$required_binary]"
  done < <(list_dependencies)
}

folder_prep() {
  if [[ -n "$1" ]]; then
    local folder="$1"
    local max_days=${2:-365}
    if [[ ! -d "$folder" ]]; then
      debug "Create folder : [$folder]"
      mkdir -p "$folder"
    else
      debug "Cleanup folder: [$folder] - delete files older than $max_days day(s)"
      find "$folder" -mtime "+$max_days" -type f -exec rm {} \;
    fi
  fi
}

expects_single_params() {
  list_options | grep 'param|1|' >/dev/null
}
expects_optional_params() {
  list_options | grep 'param|?|' >/dev/null
}
expects_multi_param() {
  list_options | grep 'param|n|' >/dev/null
}

count_words() {
  wc -w |
    awk '{ gsub(/ /,""); print}'
}

parse_options() {
  if [[ $# -eq 0 ]]; then
    show_usage >&2
    safe_exit
  fi

  ## first process all the -x --xxxx flags and options
  while true; do
    # flag <flag> is saved as $flag = 0/1
    # option <option> is saved as $option
    if [[ $# -eq 0 ]]; then
      ## all parameters processed
      break
    fi
    if [[ ! $1 == -?* ]]; then
      ## all flags/options processed
      break
    fi
    local save_option
    save_option=$(list_options |
      awk -v opt="$1" '
        BEGIN { FS="|"; OFS=" ";}
        $1 ~ /flag/   &&  "-"$2 == opt {print $3"=1"}
        $1 ~ /flag/   && "--"$3 == opt {print $3"=1"}
        $1 ~ /option/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /option/ && "--"$3 == opt {print $3"=$2; shift"}
        $1 ~ /secret/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /secret/ && "--"$3 == opt {print $3"=$2; shift"}
        ')
    if [[ -n "$save_option" ]]; then
      if echo "$save_option" | grep shift >>/dev/null; then
        local save_var
        save_var=$(echo "$save_option" | cut -d= -f1)
        debug "Found  : ${save_var}=$2"
      else
        debug "Found  : $save_option"
      fi
      eval "$save_option"
    else
      die "cannot interpret option [$1]"
    fi
    shift
  done

  ((help)) && (
    echo "### USAGE"
    show_usage
    echo ""
    echo "### TIPS & EXAMPLES"
    show_tips
    safe_exit
  )

  ## then run through the given parameters
  if expects_single_params; then
    single_params=$(list_options | grep 'param|1|' | cut -d'|' -f3)
    list_singles=$(echo "$single_params" | xargs)
    single_count=$(echo "$single_params" | count_words)
    debug "Expect : $single_count single parameter(s): $list_singles"
    [[ $# -eq 0 ]] && die "need the parameter(s) [$list_singles]"

    for param in $single_params; do
      [[ $# -eq 0 ]] && die "need parameter [$param]"
      [[ -z "$1" ]] && die "need parameter [$param]"
      debug "Assign : $param=$1"
      eval "$param=\"$1\""
      shift
    done
  else
    debug "No single params to process"
    single_params=""
    single_count=0
  fi

  if expects_optional_params; then
    optional_params=$(list_options | grep 'param|?|' | cut -d'|' -f3)
    optional_count=$(echo "$optional_params" | count_words)
    debug "Expect : $optional_count optional parameter(s): $(echo "$optional_params" | xargs)"

    for param in $optional_params; do
      debug "Assign : $param=${1:-}"
      eval "$param=\"${1:-}\""
      shift
    done
  else
    debug "No optional params to process"
    optional_params=""
    optional_count=0
  fi

  if expects_multi_param; then
    #debug "Process: multi param"
    multi_count=$(list_options | grep -c 'param|n|')
    multi_param=$(list_options | grep 'param|n|' | cut -d'|' -f3)
    debug "Expect : $multi_count multi parameter: $multi_param"
    ((multi_count > 1)) && die "cannot have >1 'multi' parameter: [$multi_param]"
    ((multi_count > 0)) && [[ $# -eq 0 ]] && die "need the (multi) parameter [$multi_param]"
    # save the rest of the params in the multi param
    if [[ -n "$*" ]]; then
      debug "Assign : $multi_param=$*"
      eval "$multi_param=( $* )"
    fi
  else
    multi_count=0
    multi_param=""
    [[ $# -gt 0 ]] && die "cannot interpret extra parameters"
  fi
}

recursive_readlink() {
  [[ ! -L "$1" ]] && echo "$1" && return 0
  local file_folder
  local link_folder
  local link_name
  file_folder="$(dirname "$1")"
  # resolve relative to absolute path
  [[ "$file_folder" != /* ]] && link_folder="$(cd -P "$file_folder" &>/dev/null && pwd)"
  local symlink
  symlink=$(readlink "$1")
  link_folder=$(dirname "$symlink")
  link_name=$(basename "$symlink")
  [[ -z "$link_folder" ]] && link_folder="$file_folder"
  [[ "$link_folder" == \.* ]] && link_folder="$(cd -P "$file_folder" && cd -P "$link_folder" &>/dev/null && pwd)"
  debug "Symbolic ln: $1 -> [$symlink]"
  recursive_readlink "$link_folder/$link_name"
}

get_clean(){
    cut -d: -f"$1" \
  | awk '{gsub(/[\s\t]/,""); print}'
}

lookup_script_data() {
  script_prefix=$(basename "${BASH_SOURCE[0]}" .sh)
  script_basename=$(basename "${BASH_SOURCE[0]}")
  execution_day=$(date "+%Y-%m-%d")

  script_install_path="${BASH_SOURCE[0]}"
  debug "Script path: $script_install_path"
  script_install_path=$(recursive_readlink "$script_install_path")
  debug "Actual path: $script_install_path"
  script_install_folder="$(dirname "$script_install_path")"
  if [[ -f "$script_install_path" ]]; then
    script_hash=$(hash <"$script_install_path" 8)
    script_lines=$(awk <"$script_install_path" 'END {print NR}')
  else
    # can happen when script is sourced by e.g. bash_unit
    script_hash="?"
    script_lines="?"
  fi

  # get shell/operating system/versions
  shell_brand="sh"
  shell_version="?"
  [[ -n "${ZSH_VERSION:-}" ]] && shell_brand="zsh" && shell_version="$ZSH_VERSION"
  [[ -n "${BASH_VERSION:-}" ]] && shell_brand="bash" && shell_version="$BASH_VERSION"
  [[ -n "${FISH_VERSION:-}" ]] && shell_brand="fish" && shell_version="$FISH_VERSION"
  [[ -n "${KSH_VERSION:-}" ]] && shell_brand="ksh" && shell_version="$KSH_VERSION"
  debug "Shell type : $shell_brand - version $shell_version"

  os_kernel=$(uname -s)
  os_version=$(uname -r) # 20.2.0
  os_machine=$(uname -m) # arm64
  install_package=""
  case "$os_kernel" in
  CYGWIN* | MSYS* | MINGW*)
    debug "Detected Windows"
    os_name="Windows"
    ;;
  Darwin)
    debug "Detected MacOS"
    os_name=$(sw_vers -productName)       # macOS
    os_version=$(sw_vers -productVersion) # 11.1
    install_package="brew install"
    ;;
  Linux | GNU*)
    debug "Detected Linux"
    if [[ $(command -v lsb_release) ]]; then
      # 'normal' Linux distributions
      os_name=$(lsb_release -i    | get_clean 2) # Ubuntu
      os_version=$(lsb_release -r | get_clean 2) # 20.04
    else
      # Synology, QNAP,
      os_name="Linux"
    fi
    [[ -f /proc/info ]] && grep -i -q microsoft < /proc/info && os_name="$os_name (WSL)"

    [[ -x /bin/apt-cyg ]] && install_package="apt-cyg install"     # Cygwin
    [[ -x /bin/dpkg ]] && install_package="dpkg -i"                # Synology
    [[ -x /opt/bin/ipkg ]] && install_package="ipkg install"       # Synology
    [[ -x /usr/sbin/pkg ]] && install_package="pkg install"        # BSD
    [[ -x /usr/bin/pacman ]] && install_package="pacman -S"        # Arch Linux
    [[ -x /usr/bin/zypper ]] && install_package="zypper install"   # Suse Linux
    [[ -x /usr/bin/emerge ]] && install_package="emerge"           # Gentoo
    [[ -x /usr/bin/yum ]] && install_package="yum install"         # RedHat RHEL/CentOS/Fedora
    [[ -x /usr/bin/apk ]] && install_package="apk add"             # Alpine
    [[ -x /usr/bin/apt-get ]] && install_package="apt-get install" # Debian
    [[ -x /usr/bin/apt ]] && install_package="apt install"         # Ubuntu
    ;;

  esac
  debug "System OS  : $os_name ($os_kernel) $os_version on $os_machine"
  debug "Package mgt: $install_package"

  # get last modified date of this script
  script_modified="??"
  [[ "$os_kernel" == "Linux" ]]  && script_modified=$(stat -c %y "$script_install_path" 2>/dev/null | cut -c1-16) # generic linux
  [[ "$os_kernel" == "Darwin" ]] && script_modified=$(stat -f "%Sm" "$script_install_path" 2>/dev/null)           # for MacOS

  debug "Last modif : $script_modified"
  debug "Script ID  : $script_lines lines / md5: $script_hash"

  # if run inside a git repo, detect for which remote repo it is
  if git status &>/dev/null; then
    git_repo_remote=$(git remote -v | awk '/(fetch)/ {print $2}')
    debug "git remote : $git_repo_remote"
    git_repo_root=$(git rev-parse --show-toplevel)
    debug "git folder : $git_repo_root"
  else
    readonly git_repo_root=""
    readonly git_repo_remote=""
  fi

  # get script version from VERSION.md file - which is automatically updated by pforret/setver
  [[ -f "$script_install_folder/VERSION.md" ]] && script_version=$(cat "$script_install_folder/VERSION.md")
  # get script version from git tag file - which is automatically updated by pforret/setver
  [[ -n "$git_repo_root" ]] && [[ -n "$(git tag &>/dev/null)" ]] && script_version=$(git tag --sort=version:refname | tail -1)
}

prep_log_and_temp_dir() {
  tmp_file=""
  log_file=""
  if [[ -n "${tmp_dir:-}" ]]; then
    folder_prep "$tmp_dir" 1
    tmp_file=$(mktemp "$tmp_dir/$execution_day.XXXXXX")
    debug "tmp_file: $tmp_file"
    # you can use this temporary file in your program
    # it will be deleted automatically if the program ends without problems
  fi
  if [[ -n "${log_dir:-}" ]]; then
    folder_prep "$log_dir" 7
    log_file=$log_dir/$script_prefix.$execution_day.log
    debug "log_file: $log_file"
  fi
}

import_env_if_any() {
  env_files=("$script_install_folder/.env" "$script_install_folder/$script_prefix.env" "./.env" "./$script_prefix.env")

  for env_file in "${env_files[@]}"; do
    if [[ -f "$env_file" ]]; then
      debug "Read config from [$env_file]"
      # shellcheck disable=SC1090
      source "$env_file"
    fi
  done
}

[[ ${run_as_root} == 1 ]]  && [[ ${UID} -ne 0 ]] && die "user is ${USER}, MUST be root to run [$script_basename]"
[[ ${run_as_root} == -1 ]] && [[ ${UID} -eq 0 ]] && die "user is ${USER}, CANNOT be root to run [${script_basename}]"

initialise_output  # output settings
lookup_script_data # find installation folder
init_options       # set default values for flags & options
import_env_if_any  # overwrite with .env if any

if [[ $sourced -eq 0 ]]; then
  parse_options "$@"    # overwrite with specified options if any
  prep_log_and_temp_dir # clean up debug and temp folder
  main                  # run main program./m1
  safe_exit             # exit and clean up
else
  # just disable the trap, don't execute main
  trap - INT TERM EXIT
fi
