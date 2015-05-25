#!/usr/bin/env bash

file_exists() { if [ -f $1 ]; then echo true; else echo false; fi }

dir_exists() { if [ -d $1 ]; then echo true; else echo false; fi }

file_count() { echo $(ls -1 $@ 2> /dev/null | wc -l); }
