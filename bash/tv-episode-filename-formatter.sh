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
###########################################################################################################################################################################################

# set default execute mode to testing = false
testing="false"
# set default renumber flag = false
renumber="false"

# Loop, get parameters & remove any spaces from input
while getopts "n:s:d:e:l:p:tr" opt; do
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
        \?)            
            # If user did not provide required parameters then show usage.
            echo "Invalid parameters! Required parameters are:  [-n] seriesName [-s] seriesSeasonNumber [-d] episodeDirectory [-e] fileExtension [-l] episodeNumberLength [-p] episodeNumberStartPosition"
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
	episodeNumber=1

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








