#!/bin/sh

# Check that both arguments are provided
if [ $# -ne 2 ]; then
    echo "Error: Missing arguments"
    exit 1
fi

filesdir=$1
searchstr=$2

# Check that filesdir exists and is a directory
if [ ! -d "$filesdir" ]; then
    echo "Error: $filesdir is not a directory"
    exit 1
fi

# Count number of files in directory and subdirectories
file_count=$(find "$filesdir" -type f | wc -l)

# Count number of lines containing the search string
match_count=$(grep -r "$searchstr" "$filesdir" | wc -l)

# Print result in required format
echo "The number of files are $file_count and the number of matching lines are $match_count"

