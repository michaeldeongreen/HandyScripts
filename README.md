# Overview

This repository contains various scripts that I find useful.

## Bash

### tv-episode-filename-formatter.sh Script

Used to re-name television filenames to a S##E## format ie Hokuto No Ken 001.mkv to Hokuto no Ken S01E01.mkv.

*Usage:*

```bash
chmod +x tv-episode-filename-formatter.sh

./tv-episode-filename-formatter.sh -n "Hokuto no Ken" -s "1" -d "C:/temp/My Plex/My Anime/Hokuto no Ken" -e "mkv" -l "3" -p "14"
```

*Parameters:*

- [-n] seriesName - Series name *(ex: Hokuto no Ken)*.
- [-s] seriesSeasonNumber - Series season number *(ex: 1,12)*.
- [-d] episodeDirectory - Episode directory *(ex: "c:/Hokuto No Ken")*.
- [-e] fileExtension - File Extension filter *(ex: mkv, mp4)*.
- [-l] episodeNumberLength - Episode number length *(ex: Series that is 99 or less would be 2, 100 to 999 would be 3)*.  Must be 2 or 3.
- [-p] episodeNumberStartPosition - The position where the episode number starts for each file.  Assumes it is the same for each file *(ex: Hokuto no Ken 001.mkv would be 14, which is the position of the first 0 in the file name)*.
- [-t] testing - OPTIONAL flag to do a test run before renaming the files.  Output will be logged to the log file.
- [-r] renumber - OPTIONAL flag used to re-number the episodes, starting at 1.  Assumes files are ordered correctly by default.
- [-c] renumberStart - OPTIONAL flag used to define the starting number for the re-number logic.  Default is 1 when -r set and not provided.
- [-h] help

*Notes:*

The script will also create a log file called **tv-episode-filename-formatter.log** in the Episode Directory.