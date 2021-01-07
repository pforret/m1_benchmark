![bash_unit CI](https://github.com/pforret/m1_benchmark/workflows/bash_unit%20CI/badge.svg)
![Shellcheck CI](https://github.com/pforret/m1_benchmark/workflows/Shellcheck%20CI/badge.svg)
![GH Language](https://img.shields.io/github/languages/top/pforret/m1_benchmark)
![GH stars](https://img.shields.io/github/stars/pforret/m1_benchmark)
![GH tag](https://img.shields.io/github/v/tag/pforret/m1_benchmark)
![GH License](https://img.shields.io/github/license/pforret/m1_benchmark)
[![basher install](https://img.shields.io/badge/basher-install-white?logo=gnu-bash&style=flat)](https://basher.gitparade.com/package/)

# m1_benchmark

Some benchmarks of MacOS M1 (Apple Silicon)

## Installation

```
git clone https://github.com/pforret/m1_benchmark.git
cd m1_benchmark
./m1_benchmark run
```

## Usage

```
Program: m1_benchmark 0.0.1 by peter@forret.com
Updated: Jan  7 21:54:54 2021
Description: Some benchmarks of MacOS M1 (Apple Silicon)
Usage: m1_benchmark [-f] [-h] [-q] [-v] [-l <log_dir>] [-t <tmp_dir>] [-w <width>] <action>
Flags, options and parameters:
-f|--force       : [flag] do not ask for confirmation (always yes) [default: off]
-h|--help        : [flag] show usage [default: off]
-q|--quiet       : [flag] no output [default: off]
-v|--verbose     : [flag] output more [default: off]
-l|--log_dir <?> : [option] folder for log files   [default: $HOME/log/m1_benchmark]
-t|--tmp_dir <?> : [option] folder for temp files  [default: .tmp]
<action>         : [parameter] action to perform: run/list
```

## Acknowledgements

* script created with [bashew](https://github.com/pforret/bashew)

&copy; 2021 Peter Forret
