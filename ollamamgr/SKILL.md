---
name: ollamamgr
description: Manage local Ollama models from the terminal via the ollamamgr CLI. Use when listing, pulling, removing, or benchmarking Ollama models. Trigger when managing local LLM models or comparing model performance.
---

# ollamamgr

Ollama model manager — list, pull, remove, benchmark.

## Binary
`~/go/bin/ollamamgr` — ensure `~/go/bin` is in PATH. Requires Ollama running on localhost:11434.

## Commands

```bash
ollamamgr list                  # show all local models (name, size, quant)
ollamamgr pull llama3.2         # download a model
ollamamgr pull mistral:7b       # pull specific tag
ollamamgr rm codellama          # remove a model
ollamamgr bench llama3.2        # benchmark tokens/sec
ollamamgr bench --all           # benchmark all local models
```

## Notes
- Ollama must be running (`ollama serve` or Ollama.app).
- `bench` measures prompt eval and generation tokens/sec.
- `list` shows model name, parameter count, quantization, and disk size.
