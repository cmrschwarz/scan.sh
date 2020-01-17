#!/bin/bash
set -Eeuo pipefail
pdf=true
dirname=""
outpath=""
filename=""
while [ $# -gt 0 ]; do
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        cat << ________EOF
scan.sh [-h/--help] [-png] [-p output_path] [-d output_dir] [-f file_name]
    -h --help           print this help and exit
    -f file_name        override the filename (%d for page number)
    -d output_dir       place output in output_dir
    -p output_path      set the full output path overriding file and dir (%d for page number)
    -png                create list of png images instead of single pdf
    
________EOF
        exit 0
    elif [ "$1" = "-png" ]; then
        pdf=false
    elif [ "$1" = "-f" ]; then
        if [ "$#" -eq 1 ]; then
            echo "output_file expected after -f" >&2
            exit -1
        fi
        filename="$2"
        shift
    elif [ "$1" = "-d" ]; then
        if [ "$#" -eq 1 ]; then
            echo "output_dir expected after -d" >&2
            exit -1
        fi
        dirname="$2"
        shift
    elif [ "$1" = "-o" ]; then
        if [ "$#" -eq 1 ]; then
            echo "output_path expected after -o" >&2
            exit -1
        fi
        outpath="$2"
        shift
    fi
    shift
done
find_free_filename() {
    dir=$1
    file=$2
    ext=$3
    nr=1
    filename="$file.$ext"
}

if [ "$outpath" = "" ]; then
    if [ "$dirname" = "" ]; then
        dirname="$(pwd -P)"
    fi
    if [ "$filename" = "" ]; then
        filename=$(date +"%Y%m%d_%H%M")
        if $pdf; then
            if [ -f "$dirname/$filename.pdf" ]; then
                nr=1
                while [ -f "$dirname/$filename""_$nr.pdf" ]; do
                    ((nr++))
                done
                filename="$filename""_$nr.pdf"
            else
                filename="$filename.pdf"
            fi
        else
            filename="$filename_%d.png"
        fi
    fi
    outpath="$dirname/$filename"
fi
scanimage_cmd='scanimage -B --progress --mode "Color" --source "ADF Duplex" --resolution 300 -d "canon_dr:libusb:001:005" --format png --swcrop=yes --swskip 1 --rollerdeskew=yes --buffermode=yes'
if $pdf; then
    dir="$(mktemp -d)"
    sh -c "$scanimage_cmd --batch=\"$dir/%d.png\""
    imgs="$(find $dir -type f | sort -V | tr '\n' ' ')"
    convert $imgs "$outpath"
else
    sh -c "$scanimage_cmd --batch=\"$outpath\""
fi
