#!/bin/bash

# clock.sh - A tool for keeping track of shifts worked on various projects
#
# Copyright (C) 2021  Luke Spademan
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

function usage {
  script=$(basename "${0}")
  cat << EOF
Usage: $script [COMMAND] [OPTIONS]...

A tool for keeping track of shifts worked on various projects

Commands
    help           view this help text
    in             clock in for a shift
    out            finish a shift
    view           show shifts worked

Options
    -h --help           view this help text
    -f --file           file to store data in
    -p --project        the project that the shift is for
    -d --date-format    output date format (passed to 'date')
    -t --time-format    output time format (passed to 'date')
    -n --notes          notes when clocking in and out

Examples
  An example workflow:
    $script in -p project1 -n working on CMS
    $script out -p project1 -n but only got 1/2 through
    $script view
  If the output is too large, you can use a program like less
    $script view | less -S

EOF
}

function prepend {
  header="$1"
  echo "$header"
  cat
}

function view {
  shiftsfile="$1"
  dateformat="$2"
  timeformat="$3"

  if ! test -f "$shiftsfile"; then
    echo "shiftsfile ($shiftsfile) doesn't exist"
    exit
  fi
  while IFS= read -r line; do
    in="$(echo $line | cut -d, -f 1)"
    date_fmt=$(date -d @${in} +"${dateformat}")
    in_fmt=$(date -d @${in} +"${timeformat}")

    line_cols=$(echo "${line}" | sed 's/[^,]//g' | wc -c)
    if [[ "$line_cols" == "3" ]]; then
      project="$(echo $line | cut -d, -f 2)"
      notes="$(echo $line | cut -d, -f 3)"
      echo "${date_fmt},${in_fmt},,,${project},${notes}"
    else
      out="$(echo $line | cut -d, -f 2)"
      out_fmt=$(date -d @${out} +"${timeformat}")
      elapsed=$(($out - $in))
      hours=$(($elapsed / 3600))
      if [[ "$hours" == "0" ]]; then
        mins=$(($elapsed / 60))
        dur_fmt="${mins}m"
      else
        dur_fmt="${hours}h"
      fi

      project="$(echo $line | cut -d, -f 3)"
      notes="$(echo $line | cut -d, -f 4)"

      echo "${date_fmt},${in_fmt},${out_fmt},${dur_fmt},${project},${notes}"
    fi

  done < $shiftsfile \
    | prepend 'DATE,IN,OUT,DURATION,PROJECT,NOTES' \
    | column -t -s ','
  }

function clock-in {
  shiftsfile="$1"
  project="$2"
  notes="$3"

  last_line_cols=$(grep ",${project}," ${shiftsfile} | tail -n 1 | sed 's/[^,]//g' | wc -c)
  if [[ "$last_line_cols" == "3" ]]; then
    >&2 echo "already clocked in for ${project}. maybe clock out?"
    exit
  fi
  echo "$(date +%s),${project},${notes}" >> "$shiftsfile"
}

function clock-out {
  shiftsfile="$1"
  project="$2"
  notes="$3"

  last_line=$(grep ",${project}," ${shiftsfile} | tail -n 1)
  last_line_cols=$(echo "${last_line}" | sed 's/[^,]//g' | wc -c)
  if [[ "$last_line_cols" != "3" ]]; then
    >&2 echo "not clocked in for ${project}. maybe clock in or choose a different project?"
    exit
  fi

  intime=$(echo "${last_line}" | cut -d, -f 1)
  project=$(echo "${last_line}" | cut -d, -f 2)
  prevnotes=$(echo "${last_line}" | cut -d, -f 3)
  if [[ -n "$prevnotes" ]]; then
    notes="${prevnotes} ${notes}"
  fi
  new_line="${intime},$(date +%s),${project},${notes}"
  sed -i "s/$last_line/$new_line/g" $shiftsfile
}


# =Argument Parsing=
# based on SO answer https://stackoverflow.com/a/14203146

POSITIONAL=()

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -d|--date-format)
      DATE_FORMAT="$2"
      shift
      shift
      ;;
    -t|--time-format)
      TIME_FORMAT="$2"
      shift
      shift
      ;;
    -n|--notes)
      NOTES="$2"
      shift
      shift
      ;;
    -f|--file)
      FILE="$2"
      shift
      shift
      ;;
    -p|--project)
      PROJECT="$2"
      shift
      shift
      ;;
    -h|--help)
      usage
      exit
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]}"
CMD=${POSITIONAL[0]}

if [ -z "$CLOCK_HOME" ]; then
  CLOCK_HOME="$HOME/.clock"
fi

mkdir -p "$CLOCK_HOME"

if [ -z "$DATE_FORMAT" ]; then
  DATE_FORMAT="%a %d %b %y"
fi
if [ -z "$TIME_FORMAT" ]; then
  TIME_FORMAT="%H:%M:%S"
fi
if [ -z "$FILE" ]; then
  FILE="$CLOCK_HOME/shifts.csv"
fi
if [ -z "$PROJECT" ]; then
  PROJECT="DEFAULT"
fi
if [ -z "$CMD" ]; then
  >&2 echo "Error: Missing argument COMMAND"
  >&2 usage
  exit
fi
case "$CMD" in
  "help")
    usage
    exit
    ;;
  "view")
    view "$FILE" "$DATE_FORMAT" "$TIME_FORMAT"
    ;;
  "in")
    clock-in "$FILE" "$PROJECT" "$NOTES"
    ;;
  "out")
    clock-out "$FILE" "$PROJECT" "$NOTES"
    ;;
  *)
    >&2 echo "Error: Unknown command '$CMD'"
    >&2 usage
    exit
    ;;
esac

