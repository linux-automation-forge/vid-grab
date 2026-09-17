vidgrab
Paste a link → pick a quality → the video lands in your Downloads folder.A friendly menu wrapper around the legendary yt-dlp engine: YouTube,Twitter/X, Instagram, Facebook, Snapchat, TikTok and 1000+ sites.

usage
./vidgrab.sh                              # interactive: paste URL, pick mode./vidgrab.sh "https://youtube.com/..."    # best quality directly./vidgrab.sh -a "https://youtube.com/..." # straight to mp3./vidgrab.sh --selftest
Modes: 1) best 2) cap 1080p 3) cap 720p 4) mp3 5) list formats 6) playlist

Every download is logged to Downloads/vidgrab/history.txt (date, platform, URL).

setup
sudo apt install -y ffmpegsudo pip3 install -U yt-dlp
honest notes
ALL downloading capability belongs to the yt-dlp project — this scriptis a menu wrapper around their engine, not a downloader itself.
Personal use only. Reuploading others' content violates copyright andplatform terms. Grab your own stuff, creators' free content, or thingsyou have rights to.
Some links (Instagram private, expired Snapchat spotlights) may refuse —that's yt-dlp's domain, not the wrapper's.
bash 4+, yt-dlp, ffmpeg. MIT licensed.

