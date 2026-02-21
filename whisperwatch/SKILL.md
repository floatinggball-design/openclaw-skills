---
name: whisperwatch
description: Watch a folder and auto-transcribe new audio/video files using local Whisper via the whisperwatch CLI. Use when setting up automatic transcription of recordings, podcasts, or voice memos. Also supports one-shot batch transcription of existing files.
---

# whisperwatch

Folder watcher that auto-transcribes audio/video with local Whisper.

## Binary
`~/go/bin/whisperwatch` — ensure `~/go/bin` is in PATH. Requires `whisper` CLI installed (`brew install whisper`).

## Usage

```bash
whisperwatch ~/Recordings                # watch + transcribe on arrival
whisperwatch ~/Recordings --once         # transcribe existing files, then exit
whisperwatch ~/Podcasts -m medium        # use larger model for accuracy
whisperwatch ~/Audio -o ~/Transcripts    # output to separate directory
```

## Key flags
- `-m, --model` — whisper model: tiny, base (default), small, medium, large
- `--once` — batch mode, no watching
- `-o, --output` — output dir (default: same as source)
- `-l, --language` — language hint (en, de, fr, etc.)
- `-w, --workers` — parallel transcription workers (default 2)
- `--whisper` — custom whisper binary path

## Output
Creates `.md` transcript files alongside source audio/video files.
