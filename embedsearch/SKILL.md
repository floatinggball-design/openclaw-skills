---
name: embedsearch
description: Index and semantically search local files using OpenAI embeddings via the embedsearch CLI. Use when indexing documents/code for semantic search, finding files by meaning rather than keywords, or building a searchable knowledge base from local files.
---

# embedsearch

Semantic file search using OpenAI embeddings + local SQLite index.

## Binary
`~/go/bin/embedsearch` — ensure `~/go/bin` is in PATH.

## Commands

```bash
embedsearch index ~/Documents          # index a folder
embedsearch index ~/code --verbose     # show progress per file
embedsearch query "budget meeting"     # search indexed files
embedsearch query "auth logic" -n 5    # top 5 results
embedsearch status                     # index stats
```

## Key flags
- `--db` — database path (default: `~/.config/embedsearch/index.db`)
- `--model` — embedding model (default: text-embedding-3-small)
- `-n` — number of results for query
- `--verbose` — show each file during indexing

## Notes
- Requires `OPENAI_API_KEY` in env.
- Indexes text files, markdown, code. Skips binary files.
- Re-indexing skips unchanged files (by mtime + size).
