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

- [-n] seriesName - Series name (ex: Hokuto no Ken)
- [-s] seriesSeasonNumber - Series season number (ex: 1,12)
- [-d] episodeDirectory - Episode directory (ex: "c:/Hokuto No Ken")
- [-e] fileExtension - File Extension filter (ex: mkv, mp4)
- [-l] episodeNumberLength - Episode number length (ex: Series with that is 99 or less would be 2, 100 to 999 would be 3).  Must be 2 or 3.
- [-p] episodeNumberStartPosition - The position where the episode number starts for each file.  Assumes it is the same for each file (ex: Hokuto no Ken 001.mkv would be 14, which is )