#!/usr/bin/env bash

root_folder=$(cd .. && pwd) # tests/.. is root folder
# shellcheck disable=SC2012
root_script=$(ls -S "$root_folder"/*.sh | head -1)

test_script_should_show_option_verbose() {
  # script without parameters should give usage info
  assert_equals 1 "$("$root_script" 2>&1 | grep -c "verbose")"
}

