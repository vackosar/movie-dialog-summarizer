# movie-dialog-summarizer
Cuts movie dialog summary video from video file and subtitles.

# Examples
- [The Shawshank Redemption](https://youtu.be/FZdDk7A4t1A)
- [The Gotfather Part I](https://youtu.be/6pY6qu0AZ2Y)
- [The Dark Knight](https://youtu.be/Px-f24xC0q0)
- [Schindler's List](https://youtu.be/3JdCfARm4IQ)
- [The Fellowship Of The Ring](https://youtu.be/75M5UUtTUgA)

# Technologies
- [LexRank](https://en.wikipedia.org/wiki/Automatic_summarization#TextRank_and_LexRank)
- [Sumy](https://github.com/miso-belica/sumy)
- [ffmpeg](https://github.com/FFmpeg/FFmpeg)

# Usage
    ./summarize-movie-dialog.sh [video file] [subtitles ".srt" file]
