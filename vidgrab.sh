#!/usr/bin/env bash
# vidgrab.sh — one-paste video/photo downloader (v1.0.0)
# Wraps yt-dlp (the real engine) with a friendly menu.
# Platforms: YouTube, Twitter/X, Instagram, Facebook, Snapchat, TikTok + 1000s more
# ALL CREDIT for downloading capability: yt-dlp project (github.com/yt-dlp/yt-dlp)
# PERSONAL USE ONLY — respect creators' copyright and platform terms.
#
# USAGE: ./vidgrab.sh [URL] | -a [URL] (audio mp3) | --selftest | --gen-files | -h
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
VERSION="1.0.0"
DL_DIR="${HOME}/Downloads/vidgrab"
HISTORY="$DL_DIR/history.txt"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    R=$'\033[0m'; B=$'\033[1m'; DIM=$'\033[2m'
    GRN=$'\033[1;32m'; YLW=$'\033[1;33m'; RED=$'\033[1;31m'; CYN=$'\033[1;36m'
else
    R=""; B=""; DIM=""; GRN=""; YLW=""; RED=""; CYN=""
fi
ok()   { printf '  %s[ok]%s %s\n' "$GRN" "$R" "$1"; }
warn() { printf '  %s[!!] %s%s\n' "$YLW" "$1" "$R"; }
err()  { printf '  %s[XX] %s%s\n' "$RED" "$1" "$R" >&2; }
sect() { printf '\n%s%s── %s %s%s\n' "$B$CYN" "" "$1" "$(printf '─%.0s' $(seq 1 44))" "$R"; }
die()  { err "$2"; exit "$1"; }

# ---------- dependency gate ----------
need_ytdlp() {
    command -v yt-dlp > /dev/null 2>&1 && return 0
    err "yt-dlp is not installed — it's the download engine"
    printf '  install with ONE of these:\n'
    printf '    %ssudo apt install -y yt-dlp%s          (Debian/Ubuntu, may be older)\n' "$B" "$R"
    printf '    %ssudo pip3 install -U yt-dlp%s         (recommended — always latest)\n' "$B" "$R"
    printf '    %ssudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && sudo chmod a+rx /usr/local/bin/yt-dlp%s\n' "$B" "$R"
    exit 1
}
need_ffmpeg() {
    command -v ffmpeg > /dev/null 2>&1 && return 0
    warn "ffmpeg missing — needed to merge HD video+audio and for mp3 conversion"
    printf '  install: %ssudo apt install -y ffmpeg%s\n' "$B" "$R"
    printf '  (low-quality downloads work without it, but why would you)\n'
    return 1
}

# ---------- platform detection (cosmetic + honest) ----------
detect_platform() {
    local u="${1,,}"
    case "$u" in
        *youtube.com*|*youtu.be*)  echo "YouTube" ;;
        *twitter.com*|*x.com*)     echo "Twitter/X" ;;
        *instagram.com*)           echo "Instagram" ;;
        *facebook.com*|*fb.watch*) echo "Facebook" ;;
        *snapchat.com*)            echo "Snapchat" ;;
        *tiktok.com*)              echo "TikTok" ;;
        *reddit.com*)              echo "Reddit" ;;
        *twitch.tv*)               echo "Twitch" ;;
        *)                         echo "Generic (yt-dlp will try)" ;;
    esac
}
valid_url() { [[ "$1" =~ ^https?://[a-zA-Z0-9.-]+ ]]; }

# ---------- the menu ----------
show_menu() {
    sect "Pick download mode"
    printf '   1) Best quality video (recommended)\n'
    printf '   2) Cap at 1080p (smaller file, still crisp)\n'
    printf '   3) Cap at 720p (small)\n'
    printf '   4) Audio only → MP3\n'
    printf '   5) List available formats first (no download)\n'
    printf '   6) Playlist (every video in the link)\n'
    printf '\n'
}

# ---------- download runners ----------
run_video() { # $1=format spec
    local spec="$1"
    printf '\n%sdownloading...%s (progress below — file lands in %s)\n\n' "$DIM" "$R" "$DL_DIR"
    yt-dlp -f "$spec" \
           --merge-output-format mp4 \
           --no-playlist \
           -o "$DL_DIR/%(title).80s.%(ext)s" \
           "$URL"
}
run_audio() {
    printf '\n%sconverting to MP3...%s\n\n' "$DIM" "$R"
    yt-dlp -x --audio-format mp3 --audio-quality 0 \
           --no-playlist \
           -o "$DL_DIR/%(title).80s.%(ext)s" \
           "$URL"
}
run_list() {
    printf '\n%savailable formats:%s\n\n' "$DIM" "$R"
    yt-dlp -F --no-playlist "$URL"
}
run_playlist() {
    printf '\n%splaylist mode — downloading everything...%s\n\n' "$DIM" "$R"
    yt-dlp -f "bv*[height<=1080]+ba/b" \
           --merge-output-format mp4 \
           -o "$DL_DIR/%(playlist_title).60s/%(playlist_index)03d - %(title).70s.%(ext)s" \
           "$URL"
}

# ---------- history ----------
log_history() {
    mkdir -p "$DL_DIR"
    printf '%s | %s | %s\n' "$(date '+%Y-%m-%d %H:%M')" "$PLATFORM" "$URL" >> "$HISTORY"
}

# ---------- main flow ----------
URL=""; MODE=""
main_flow() {
    printf '%s vidgrab %s — paste a link, get the video %s\n' "$CYN$B" "$R$DIM" "$R"
    printf '%sengine: yt-dlp · personal use only — respect copyright%s\n\n' "$DIM" "$R"

    need_ytdlp
    need_ffmpeg || true

    sect "The link"
    if [[ -z "$URL" ]]; then
        read -r -p 'Paste URL: ' URL || die 2 "no input"
    fi
    URL="${URL#"${URL%%[![:space:]]*}"}"; URL="${URL%"${URL##*[![:space:]]}"}"
    valid_url "$URL" || die 2 "that doesn't look like a URL (expected https://...)"

    PLATFORM="$(detect_platform "$URL")"
    ok "platform: $PLATFORM"

    if [[ -z "$MODE" ]]; then
        show_menu
        read -r -p 'choice [1-6]: ' MODE || die 2 "aborted"
    fi

    mkdir -p "$DL_DIR"
    sect "Downloading"

    case "$MODE" in
        1) run_video "bv*+ba/b" ;;
        2) run_video "bv*[height<=1080]+ba/b" ;;
        3) run_video "bv*[height<=720]+ba/b" ;;
        4) need_ffmpeg || die 1 "mp3 needs ffmpeg — install it first"; run_audio ;;
        5) run_list ;;
        6) run_playlist ;;
        *) die 2 "pick 1-6" ;;
    esac

    log_history
    sect "Done"
    ok "saved into: $DL_DIR"
    ok "history:    $HISTORY"
    printf '\n%sreminder: personal use only — do not reupload others content.%s\n\n' "$DIM" "$R"
}

# ---------- selftest ----------
self_test() {
    local pass=0 fail=0
    oks()  { printf '  %sPASS%s %s\n' "$GRN" "$R" "$1"; pass=$((pass+1)); }
    bads() { printf '  %sFAIL%s %s\n' "$RED" "$R" "$1"; fail=$((fail+1)); }
    printf '%sVIDGRAB SELF-TEST (offline)%s\n' "$CYN" "$R"

    command -v yt-dlp > /dev/null 2>&1 && oks "yt-dlp installed" \
        || bads "yt-dlp missing (pip3 install -U yt-dlp)"
    command -v ffmpeg > /dev/null 2>&1 && oks "ffmpeg installed" \
        || bads "ffmpeg missing (sudo apt install ffmpeg)"

    local p; p="$(detect_platform 'https://www.youtube.com/watch?v=x')"
    [[ "$p" == "YouTube" ]] && oks "detect YouTube" || bads "detect YouTube ($p)"
    p="$(detect_platform 'https://x.com/user/status/1')"
    [[ "$p" == "Twitter/X" ]] && oks "detect X" || bads "detect X ($p)"
    p="$(detect_platform 'https://www.snapchat.com/spotlight/x')"
    [[ "$p" == "Snapchat" ]] && oks "detect Snapchat" || bads "detect Snapchat ($p)"
    p="$(detect_platform 'https://example.com/x')"
    [[ "$p" == "Generic (yt-dlp will try)" ]] && oks "detect fallback" || bads "detect fallback ($p)"

    valid_url "https://x.com/a" && oks "url validate ok" || bads "url validate"
    valid_url "not a url" && bads "url reject bad" || oks "url rejects garbage"

    printf '%sRESULT: pass=%d fail=%d%s\n' "$CYN" "$pass" "$fail" "$R"
    (( fail > 0 )) && exit 1
    printf '%sSELF-TEST OK%s\n' "$GRN" "$R"
}

# ---------- gen-files ----------
gen_repo_files() {
    [[ -e README.md ]] || { cat > README.md <<'VG1'
# vidgrab

Paste a link → pick a quality → video lands in your Downloads folder.
Wraps the legendary **yt-dlp** engine with a friendly menu: YouTube,
Twitter/X, Instagram, Facebook, Snapchat, TikTok and 1000+ sites.

## usage

    ./vidgrab.sh                          # interactive: paste URL, pick mode
    ./vidgrab.sh "https://youtube.com/..."           # best quality
    ./vidgrab.sh -4 "https://youtube.com/..."        # straight to mp3
    ./vidgrab.sh --selftest

Modes: 1) best  2) 1080p  3) 720p  4) mp3  5) list formats  6) playlist

## requirements

    sudo apt install -y ffmpeg
    sudo pip3 install -U yt-dlp     # the actual engine — all credit to them

## honest notes

- ALL downloading capability belongs to the yt-dlp project — this script is
  just a menu wrapper around it.
- PERSONAL USE ONLY. Reuploading others' content violates copyright and
  most platforms' terms. Download your own stuff, creators' free content,
  or things you have rights to.
- Some platforms (Instagram private accounts, Snapchat after link expiry)
  may refuse — that's yt-dlp's domain, not the wrapper's.

bash 4+, yt-dlp, ffmpeg. MIT licensed.
VG1
    printf '  [ok] README.md\n'; }
    [[ -e LICENSE ]] || { cat > LICENSE <<'VG2'
MIT License

Copyright (c) 2025 YOUR NAME HERE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
VG2
    printf '  [ok] LICENSE (add your name!)\n'; }
    [[ -e requirements.txt ]] || { cat > requirements.txt <<'VG3'
# vidgrab — dependency manifest

yt-dlp        REQUIRED — the download engine (pip3 install -U yt-dlp)
ffmpeg        REQUIRED — merges HD video+audio, mp3 conversion
bash          (4.0+)

# one-line setup:
# sudo apt install -y ffmpeg && sudo pip3 install -U yt-dlp
VG3
    printf '  [ok] requirements.txt\n'; }
    [[ -e .gitignore ]] || { printf 'Downloads/\n*.mp4\n*.mp3\n*.log\n.DS_Store\n' > .gitignore; printf '  [ok] .gitignore\n'; }
    printf '\nDone — edit LICENSE (your name), then upload.\n'
}

# ---------- CLI ----------
parse_args() {
    local -a rest=()
    while (( $# > 0 )); do
        case "$1" in
            -a|--audio) MODE="4" ;;
            -b|--best)  MODE="1" ;;
            --list)     MODE="5" ;;
            --selftest) self_test; exit $? ;;
            --gen-files) gen_repo_files; exit 0 ;;
            -h|--help)
                printf 'vidgrab v%s — paste a link, get the video (engine: yt-dlp)\n' "$VERSION"
                printf 'USAGE: %s [URL] | -a URL (mp3) | --selftest | --gen-files | -h\n' "$SCRIPT_NAME"
                exit 0 ;;
            -V|--version) printf '%s v%s\n' "$SCRIPT_NAME" "$VERSION"; exit 0 ;;
            -*) die 2 "unknown option '$1' — try --help" ;;
            *) rest+=("$1") ;;
        esac
        shift
    done
    (( ${#rest[@]} > 0 )) && URL="${rest[0]}"
}
parse_args "$@"
main_flow
