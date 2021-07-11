#!/bin/bash -eu

##########################################################################################################################################################################################
#- Purpose: Script is used to rename tv episodes into a "S##E#" format ie "Hokuto no Ken 001.mkv" to "Hokuto no Ken S01E01.mkv"
#- Parameters are:
#- [-n] seriesName - Series name (ex: Hokuto no Ken).
#- [-s] seriesSeasonNumber - Series season number (ex: 1,12).
#- [-d] episodeDirectory - Episode directory (ex: "c:/Hokuto No Ken").
#- [-e] fileExtension - File Extension filter (ex: mkv, mp4).
#- [-l] episodeNumberLength - Episode number length (ex: Series with that is 99 or less would be 2, 100 to 999 would be 3).  Must be 2 or 3.
#- [-p] episodeNumberStartPosition - The position where the episode number starts for each file.  Assumes it is the same for each file (ex: Hokuto no Ken 001.mkv would be 14, which is).
#- [-t] testing - OPTIONAL flag to do a test run before renaming the files.  Output will be logged to the log file.
#- [-r] renumber - OPTIONAL flag used to re-number the episodes, starting at 1.  Assumes files are ordered correctly by default.
#- [-c] renumberStart - OPTIONAL flag used to define the starting number for the re-number logic.  Default is 1 when -r set and not provided.
#- [-h] help
###########################################################################################################################################################################################

############################################################
#- function used to print out script usage
############################################################
function usage() {
    echo
    echo "Arguments:"
    echo -e "\t-n \t Series name (ex: Hokuto no Ken) (required)"
    echo -e "\t-s \t Series season number (ex: 1,12) (required)"
    echo -e "\t-d \t Episode directory (ex: "c:/Hokuto No Ken") (required)"    
    echo -e "\t-e \t File Extension filter (ex: mkv, mp4) (required)"        
    echo -e "\t-l \t Episode number length (ex: Series with that is 99 or less would be 2, 100 to 999 would be 3).  Must be 2 or 3 (required)"
	echo -e "\t-p \t The position where the episode number starts for each file.  Assumes it is the same for each file (ex: Hokuto no Ken 001.mkv would be 14, which is) (required)"
	echo -e "\t-t \t Flag to do a test run before renaming the files.  Output will be logged to the log file (optional)"
	echo -e "\t-r \t flag used to re-number the episodes, starting at 1.  Assumes files are ordered correctly by default (optional)"
	echo -e "\t-c \t flag used to define the starting number for the re-number logic.  Default is 1 when -r set and not provided"
    echo -e "\t-h \t Help (optional)"
    echo
    echo "Example:"
    echo -e "./tv-episode-filename-formatter.sh -n \"Hokuto no Ken\" -s 1 -d \"c:/Hokuto no Ken\" -e mkv -l 2 -p 15 -t"
}

# set default execute mode to testing = false
testing="false"
# set default renumber flag = false
renumber="false"
# set default renumberStart = 1
renumberStart=1

# Loop, get parameters & remove any spaces from input
while getopts "n:s:d:e:l:p:trc:h" opt; do

    case $opt in
        n)
            # Series Name
            seriesName=$OPTARG
        ;;
        s)
            # Series Season Number
            seriesSeasonNumber=$OPTARG
        ;;
        d)
            # Episode Directory
            episodeDirectory=$OPTARG
        ;;
        e)
            # File Extension
            fileExtension=$OPTARG
        ;;
        l)
            # Episode Number Length
            episodeNumberLength=$OPTARG
        ;;
        p)
            # Episode Number Start Position
            episodeNumberStartPosition=$OPTARG
        ;;
        t)
            # Testing
            testing="true"
        ;;
        r)
            # Renumber
            renumber="true"
        ;;
        c)
            # Renumber Start
            renumberStart=$OPTARG
        ;;		
        :)            
          echo "Error: -${OPTARG} requires a value"
          exit 1
        ;;
        *)
          usage
          exit 1
        ;;
    esac
done

# If user did not provide required parameters then non-usage.
if [[ $# -eq 0 || -z $seriesName || -z $seriesSeasonNumber || -z $episodeDirectory || -z $fileExtension || -z $episodeNumberLength || -z  $episodeNumberStartPosition ]]; then
    echo "Parameters missing! Required parameters are:  [-n] seriesName [-s] seriesSeasonNumber [-d] episodeDirectory [-e] fileExtension [-l] episodeNumberLength [-p] episodeNumberStartPosition"
    exit 1; 
fi

# as of now, the episode number length must be 2 or 3 ie 01-99 or 001-999
if [[ "$episodeNumberLength" -ne "2" && "$episodeNumberLength" -ne "3" ]]; then
	echo "Parameter episodeNumberLength is invalid.  Must be 2 or 3!"
	exit 1;
fi

#######################################################
#- function used to loop through directory and rename
# files but keep the original episode numbers.
#- $1 - Log file entry
#######################################################
dontRenumberEpisodes () {
	# loop through each file
	for f in $files
	do
		# write to log file
		writeToLogFile "Processing file $f"
		
		# get the file name only
		filename=$(basename -- "$f")

		# get the episode number only
		episodeNumber=${filename:episodeNumberStartPosition:episodeNumberLength}

		# get the first digit of the episode number
		firstDigit=${episodeNumber:0:1}

		# logic to check the first digit
		if [ "$zero" == "$firstDigit" ]; then
			
			if [[ "$episodeNumberLength" == "2" ]]; then
				newEpisodeNumber=${episodeNumber:0:2} # start at first position string
			else
				newEpisodeNumber=${episodeNumber:1:2} # start at second position in string
			fi
			newEpisodeName="$episodeDirectory/$seriesName $preS$seriesSeasonNumber$preE$newEpisodeNumber.$fileExtension"
			# rename file
			rename "$f" "$newEpisodeName"
		else
			newEpisodeName="$episodeDirectory/$seriesName $preS$seriesSeasonNumber$preE$episodeNumber.$fileExtension"
			# rename file		
			rename "$f" "$newEpisodeName"
		fi
	done
}

#######################################################
#- function used to rename a file using the mv command
#- $1 - Original file name
#- $2 - New file name
#######################################################
rename () {
	if [[ "$testing" == "false" ]]; then
		mv "$1" "$2"
	fi
	
	# write to log file
	writeToLogFile "New file name: $2\n\n"
}

#######################################################
#- function used to loop through directory and rename
# files but re-numbers episodes.
#- $1 - Log file entry
#######################################################
renumberEpisodes () {
	episodeNumber=$renumberStart

	# loop through each file
	for f in $files
	do
		# write to log file
		writeToLogFile "Processing file $f"
		
		# get the file name only
		filename=$(basename -- "$f")
		
		# format episode number
		if [ ${#episodeNumber} == 1 ]; then
			formattedEpisodeNumber="0$episodeNumber"
		else
			formattedEpisodeNumber="$episodeNumber"
		fi		

		newEpisodeName="$episodeDirectory/$seriesName $preS$seriesSeasonNumber$preE$formattedEpisodeNumber.$fileExtension"
		# rename file		
		rename "$f" "$newEpisodeName"

		episodeNumber=$((episodeNumber+1))
	done
}

#######################################################
#- function used to write to log file
#- $1 - Log file entry
#######################################################
writeToLogFile () {
	echo -e "$1" | tee -a "$logFile"
}

# resetting the internal separator to newline so a directory with spaces is not split by spaces
IFS='|'

# first digit
zero="0"
# S before season number
preS="S"
# E before episode number
preE="E"
# log file
logFile="$episodeDirectory/tv-episode-filename-formatter.log"

# directory location with filter
files="$episodeDirectory/*.$fileExtension"

# write to log file
writeToLogFile "Parameters:  [-n] $seriesName [-s] $seriesSeasonNumber [-d] $episodeDirectory [-e] $fileExtension [-l] $episodeNumberLength [-p] $episodeNumberStartPosition\n\n"

# concat 0 onto series season number if length is 1
if [ ${#seriesSeasonNumber} == 1 ]; then
	seriesSeasonNumber="0$seriesSeasonNumber"
fi

# determine whether episodes need to be renumbered
if [ "$renumber" == "false" ]; then
	dontRenumberEpisodes
else
	renumberEpisodes
fi