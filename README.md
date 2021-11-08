# clock.sh

## usage

    Usage: clock.sh [COMMAND] [OPTIONS]...

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
        clock.sh in -p project1 -n working on CMS
        clock.sh out -p project1 -n but only got 1/2 through
        clock.sh view
      If the output is too large, you can use a program like less
        clock.sh view | less -S

## license

    clock.sh - A tool for keeping track of shifts worked on various projects

    Copyright (C) 2021  Luke Spademan

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
