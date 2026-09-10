# Shell Autocomplete Fix

## Problem
`zsh-autocomplete` plugin broke on latest main branch (Feb 2026). Functions `_autocomplete__unambiguous` and `_autocomplete__should_add_space` were moved from `Functions/` to `Completions/` directory, causing:

```
autocomplete:_main_complete:new:post:3: command not found: _autocomplete__unambiguous
.autocomplete__complete-word__post:59: command not found: _autocomplete__should_add_space
```

## Solution Applied
Rolled back to stable tag `26.08.04` and pinned on local branch `stable-26.08.04`.

```bash
cd ~/.oh-my-zsh/custom/plugins/zsh-autocomplete
git checkout 26.08.04
git switch -c stable-26.08.04
```

## To apply
**Restart your shell** (close and reopen terminal, or run `exec zsh`)

## To prevent future breakage
Plugin now on local branch, won't auto-update. To manually update later:
```bash
cd ~/.oh-my-zsh/custom/plugins/zsh-autocomplete
git fetch origin
git log origin/main --oneline -10  # Check if issues resolved
git merge origin/main  # Only if safe
```

## Alternative
Consider removing `zsh-autocomplete` from plugins list in `.zshrc` - it conflicts with `zsh-autosuggestions` and standard completion. Standard zsh completion + autosuggestions usually sufficient.
