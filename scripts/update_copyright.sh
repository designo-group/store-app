#! /bin/zsh

OIFS="$IFS"
IFS=$'\n'

dirname=$PWD
CURRENT_YEAR=$(date +'%Y')
echo "Current year is ${CURRENT_YEAR}"

echo "$PWD"

FILES=($(find "$PWD" -type f | grep '\.txt'))
echo "Found ${#FILES[@]} files with .swift extension"

for f in "${FILES[@]}"
do
	sed -i "" "s/Copyright (c) [0-9]\{4\} Designø/Copyright (c) ${CURRENT_YEAR} Designø/g" "$f"
	if [ "$?" -eq "0" ];
	then
       sed -i "" "s/Copyright (c) [0-9]\{4\} Designø/Copyright (c) ${CURRENT_YEAR} Designø/g" "$f"
	else
		echo "Error encountered with ${f}"
	fi
done

IFS="$OIFS"
