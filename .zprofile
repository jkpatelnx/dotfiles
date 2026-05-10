eval "$(/opt/homebrew/bin/brew shellenv)"

# Created by `pipx` on 2026-05-10 08:18:35
export PATH="$PATH:/Users/jitendra/.local/bin"
export SSL_CERT_FILE=$(python3 -m certifi)

idm() {
  aria2c \
  -x 8 \
  -s 8 \
  -k 1M \
  --min-split-size=1M \
  --max-connection-per-server=8 \
  --split=8 \
  --continue=true \
  --auto-file-renaming=false \
  --allow-overwrite=false \
  --file-allocation=none \
  --max-tries=10 \
  --retry-wait=3 \
  --timeout=30 \
  --console-log-level=error \
  --dir="$HOME/Downloads" \
  "$1"
}

yt() {
  yt-dlp \
  --no-playlist \
  --sleep-requests 1 \
  --concurrent-fragments 8 \
  -f "bv*+ba/b" \
  --merge-output-format mp4 \
  --embed-metadata \
  --embed-thumbnail \
  --convert-thumbnails jpg \
  --add-metadata \
  --replace-in-metadata title "(?i)\(full video\)" "" \
  --replace-in-metadata title "(?i)\[full video\]" "" \
  --replace-in-metadata title "(?i)\(official video\)" "" \
  --replace-in-metadata title "(?i)\(official audio\)" "" \
  --replace-in-metadata title "(?i)\(lyrical video\)" "" \
  --replace-in-metadata title "(?i)\[official music video\]" "" \
  --replace-in-metadata title "(?i)#shorts" "" \
  -o "%(title)s.%(ext)s" \
  -P ~/Movies/youtube-video \
  "$1"
}

yt-playlist() {
  url="$1"

  if [[ "$url" == *"list=RD"* ]]; then
    echo "Auto-generated YouTube Mix playlists are blocked."
    echo "Use a normal fixed playlist instead."
    return 1
  fi

  yt-dlp \
  --yes-playlist \
  --sleep-requests 2 \
  --sleep-interval 1 \
  --max-sleep-interval 3 \
  --concurrent-fragments 8 \
  -f "bv*+ba/b" \
  --merge-output-format mp4 \
  --embed-metadata \
  --embed-thumbnail \
  --convert-thumbnails jpg \
  --add-metadata \
  --replace-in-metadata title "(?i)\(full video\)" "" \
  --replace-in-metadata title "(?i)\[full video\]" "" \
  --replace-in-metadata title "(?i)\(official video\)" "" \
  --replace-in-metadata title "(?i)\(official audio\)" "" \
  --replace-in-metadata title "(?i)\(lyrical video\)" "" \
  --replace-in-metadata title "(?i)\[official music video\]" "" \
  --replace-in-metadata title "(?i)#shorts" "" \
  -o "%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s" \
  -P ~/Movies/youtube-video/playlist \
  "$url"
}

yt-music() {
  url="${1/music.youtube.com/www.youtube.com}"

  yt-dlp \
  --extractor-args "youtube:player_client=android" \
  --extract-audio \
  --audio-format mp3 \
  --audio-quality 0 \
  --embed-thumbnail \
  --compat-options embed-thumbnail-atomicparsley \
  --convert-thumbnails jpg \
  --embed-metadata \
  --add-metadata \
  --sleep-requests 2 \
  --concurrent-fragments 1 \
  -f "bestaudio/best" \
  --no-playlist \
  --replace-in-metadata title "(?i)\(full video\)" "" \
  --replace-in-metadata title "(?i)\[full video\]" "" \
  --replace-in-metadata title "(?i)\(official video\)" "" \
  --replace-in-metadata title "(?i)\(official audio\)" "" \
  --replace-in-metadata title "(?i)\(lyrical video\)" "" \
  --replace-in-metadata title "(?i)\[official music video\]" "" \
  --replace-in-metadata title "(?i)#shorts" "" \
  -o "%(title)s.%(ext)s" \
  -P ~/Music/youtube-music \
  "$url"
}

yt-music-playlist() {
  url="${1/music.youtube.com/www.youtube.com}"

  yt-dlp \
  --extractor-args "youtube:player_client=android" \
  --extract-audio \
  --audio-format mp3 \
  --audio-quality 0 \
  --embed-thumbnail \
  --compat-options embed-thumbnail-atomicparsley \
  --convert-thumbnails jpg \
  --embed-metadata \
  --add-metadata \
  --sleep-requests 3 \
  --sleep-interval 2 \
  --max-sleep-interval 5 \
  --concurrent-fragments 1 \
  -f "bestaudio/best" \
  --yes-playlist \
  --replace-in-metadata title "(?i)\(full video\)" "" \
  --replace-in-metadata title "(?i)\[full video\]" "" \
  --replace-in-metadata title "(?i)\(official video\)" "" \
  --replace-in-metadata title "(?i)\(official audio\)" "" \
  --replace-in-metadata title "(?i)\(lyrical video\)" "" \
  --replace-in-metadata title "(?i)\[official music video\]" "" \
  --replace-in-metadata title "(?i)#shorts" "" \
  -o "%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s" \
  -P ~/Music/youtube-music/playlist \
  "$url"
}
