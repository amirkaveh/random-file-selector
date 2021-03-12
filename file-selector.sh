#!/bin/bash

script_name=$(basename -- $0)
script_path="$(cd $(dirname "$0") && pwd)"
extensions_file="$script_path/video_format.csv"

echo_usage() {
    cat <<EOF
Usage: $script_name NUMBER DESTINATION [Options]
Parameters:
  NUMBER                Number of files to select.
  DESTINATION           Path to destination.
Options:
  -h | --help           Show this message.
EOF
}

echo_error() {
    text=
    case $1 in 
        1) text="Destination directory does not exists." ;;
        2) text="Number is invalid." ;;
        3) text="Invalid option '$2'" ;;
        *) text="Invalid usage." ;;
    esac

    cat <<EOF
$text
Try '$script_name --help' for more information.
EOF
}

number_to_select=
destination_path=
parse_input() {
    other_args=()
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo_usage
                exit
            ;;
            -*)
                echo_error 3 $1
                exit 1
            ;;
            *)
                other_args+=("$1")
            ;;
        esac
        shift
    done

    if [[ ${#other_args[@]} -gt 2 || ${#other_args[@]} -eq 0 ]]; then
        echo_error 0
        exit 1
    fi

    number_regex="^([1-9][0-9]*)$"
    number_to_select=${other_args[0]}
    if [[ -z "$number_to_select" ]] || ! [[ $number_to_select =~ $number_regex ]]; then
        echo_error 2
        exit 1
    fi

    destination_path=${other_args[1]}
    if [[ ! -d $destination_path ]]; then
        echo_error 1
        exit 1
    fi
}

echo_extensions() {
    cat <<EOF
File extensions to search: 
  $1
  to change it, edit the file '$extensions_file'
EOF
}

ext_string=
read_extensions() {
    extensions=$(<$extensions_file)
    extensions=($extensions)
    ext_string=""
    for (( i=1 ; i < ${#extensions[@]} ; i++ )); do
        ext_string="$ext_string|${extensions[i]}"
    done
    ext_string=${ext_string:1}
    echo_extensions $ext_string
}

ext_regex=
make_extension_regex() {
    ext_regex=$(printf ".*\.(%s)" "$ext_string")
}

files=
number_of_files=
find_files() {
    exclude_path=$(realpath --relative-to="." "$destination_path")
    exclude_path="./$exclude_path"
    if [[ "${exclude_path: -1}" != "/" ]]; then
        exclude_path+="/"
    fi
    exclude_path+="*"
    readarray -t files < <(find . -type f -regextype egrep -regex "$ext_regex" -not -path "$exclude_path")
    number_of_files=${#files[@]}
    
    if [[ $number_of_files -eq 0 ]]; then
        echo "No matching files were found!"
        exit 0
    else 
        echo "Found $number_of_files matching file(s)."
    fi
}

min() {
    if [[ $2 -gt $1 ]]; then
        echo $1
    else 
        echo $2
    fi
}

selected_files=()
select_files() {
    number_to_select=$(min $number_of_files $number_to_select)

    for (( i=0 ; i < $number_to_select ; i++ )); do
        selected_number=$(( $RANDOM % $number_of_files ))
        selected_files[$i]=${files[selected_number]}
    done
}

temp=
echo_copy() {
    temp="'$(basename -- "$1")' to '$(basename -- "$destination_path")'"
    echo "Copying $temp..."
}

echo_copied() {
    echo -e "\e[1A\e[KCopied $temp."
}

copy_files() {
    for (( i=0 ; i < $number_to_select ; i++ )); do
        file="${selected_files[i]}"
        echo_copy "$file"
        file="${file%.*}"
        cp "$file"* "$destination_path"
        echo_copied
    done
}

main() {
    parse_input $@
    read_extensions
    make_extension_regex
    find_files
    select_files
    copy_files
    echo "DONE!"
}

main $@