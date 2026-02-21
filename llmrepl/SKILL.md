---
name: llmrepl
description: Chat with LLMs (Claude, OpenAI, Gemini, Ollama) from the terminal via the llmrepl CLI. Use for one-shot queries, interactive REPL sessions, piped input, or retrieving conversation history. Trigger when needing a quick LLM query outside the main agent, comparing providers, or accessing local Ollama models.
---

# llmrepl

Terminal LLM chat client supporting multiple providers.

## Binary
`~/go/bin/llmrepl` — ensure `~/go/bin` is in PATH.

## Usage

```bash
llmrepl                          # interactive REPL (default provider)
llmrepl ask "what is Go?"        # one-shot query
echo "explain this" | llmrepl    # pipe mode
llmrepl history                  # list past conversations
llmrepl --continue 3             # resume conversation #3
```

## Key flags
- `-p, --provider` — anthropic, openai, ollama, gemini
- `-m, --model` — override model name
- `-c, --continue <id>` — resume a past conversation
- `-s, --system` — custom system prompt
- `--json` — JSON output

## Providers
Reads API keys from env: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`. Ollama uses localhost:11434 by default.

## Conversation history
Stored in SQLite at `~/.config/llmrepl/history.db`. Use `llmrepl history` to list, `--continue <id>` to resume.
