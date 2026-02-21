---
name: imagetag
description: Describe, tag, or rename images using AI vision (Claude or GPT-4o) via the imagetag CLI. Use when batch-describing photos, generating tags for image organization, or auto-renaming image files with descriptive names.
---

# imagetag

AI-powered image description, tagging, and renaming.

## Binary
`~/go/bin/imagetag` — ensure `~/go/bin` is in PATH.

## Commands

```bash
imagetag describe photo.jpg             # 1-2 sentence description
imagetag describe *.jpg                 # batch describe
imagetag tags *.jpg                     # JSON tags array per image
imagetag rename --dry-run ~/Photos/     # preview AI filenames
imagetag rename ~/Photos/               # rename in-place
```

## Key flags
- `-p, --provider` — anthropic (default), openai
- `-m, --model` — override model (default: claude-sonnet-4-6 / gpt-4o)
- `-w, --workers` — parallel workers (default 4)
- `--json` — JSON lines output

## Notes
- Requires `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` in env.
- `rename` preserves file extension; use `--dry-run` first.
- Supports jpg, png, gif, webp.
