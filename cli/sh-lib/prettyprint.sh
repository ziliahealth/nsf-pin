#!/usr/bin/env bash

_get_title_lenght() {
  title="$1"
  printf "%s" "$title" | wc -m
}


_print_title_char_under() {
  title="$1"
  char_under="$2"
  printf -- "\n"
  printf -- "%s\n" "${title}"

  for _ in $(seq 1 "$(_get_title_lenght "$title")"); do
    printf -- "%s" "$char_under"
  done
  printf -- "\n\n"
}


print_title_lvl1() {
  _print_title_char_under "$1" "="
}


print_title_lvl2() {
  _print_title_char_under "$1" "-"
}


_print_title_chars_each_side() {
  title="$1"
  chars_each_side="$2"
  printf -- "\n"
  printf -- "%s %s %s\n" "${chars_each_side}" "${title}" "${chars_each_side}"
  printf -- "\n"
}


print_title_lvl3() {
  _print_title_chars_each_side "$1" "###"
}


print_cmd_args() {
  printf "%q\n" "$@" | paste -s -d' '
}
