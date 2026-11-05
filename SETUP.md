# New Mac setup

`build.sh` installs everything and links all config into this repo. It is
safe to re-run at any time; re-running is the fix for most problems.

## Fresh Mac

1. Finish the macOS setup assistant (any account name works).
2. In **Terminal.app**:
   ```sh
   xcode-select --install          # wait for the dialog to finish
   git clone https://github.com/hyptocrypto/dotfiles.git ~/dev/dotfiles
   ~/dev/dotfiles/build.sh         # never with sudo
   ```
   It will prompt for: your **sudo password**, a **passphrase** for the new
   SSH key, and the **Raycast export password** (in Raycast's import window).
   `wezterm@nightly` is a ~110 MB download, so it can look stalled for a while.
3. Manual steps (apps / accounts the script can't do):
   - **Karabiner**: open it, allow the driver extension + Input Monitoring in
     System Settings → Privacy & Security (Caps Lock → Esc needs this).
   - **Raycast**: if onboarding showed instead of the import, use
     Settings → Advanced → Import → `~/dev/dotfiles/raycast/raycast.rayconfig`.
     If script commands are missing: Settings → Extensions → Script Commands →
     Add Directories → `~/dev/raycast_scripts`.
   - **Secrets**: copy `~/.zshrc.local` from the old Mac (never committed).
   - **GitHub**: `gh auth login`, `gh ssh-key add ~/.ssh/id_ed25519.pub`, then
     `git -C ~/dev/dotfiles remote set-url origin git@github.com:hyptocrypto/dotfiles.git`
   - **pi**: run `pi`, `/login`, quit, then `~/dev/dotfiles/pi/install.sh`.
   - **Log out and back in** (key repeat, scroll direction, Cmd+Space).
4. Use **WezTerm** from now on (icons/fonts are configured there).

## Repairing a Mac where a previous run went wrong

```sh
cd ~/dev/dotfiles
git diff --stat            # config edited on this Mac lands here (files are symlinks)
git checkout -- .          # discard those edits (p10k wizard, installers, manual fixes)
git pull https://github.com/hyptocrypto/dotfiles.git master
./build.sh
exec zsh
```

`build.sh` repairs the usual breakage on its own: root-owned dirs in `$HOME`,
`/opt/homebrew` owned by another (deleted) account, insecure zsh completion
dirs, stale `~/.zcompdump*`, a half-installed `~/.oh-my-zsh`, and fonts
missing for the current user.

## Verify

```sh
echo $TERM_PROGRAM                          # WezTerm
stat -f %Su /opt/homebrew                   # your username
compaudit                                   # no output
grep POWERLEVEL9K_MODE ~/.p10k.zsh          # nerdfont-complete
ls ~/Library/Fonts | grep -c JetBrainsMonoNerdFont   # > 0
ls -l ~/.zshrc ~/.p10k.zsh ~/.wezterm.lua ~/.config/karabiner   # -> ~/dev/dotfiles/...
git -C ~/dev/dotfiles status --short        # empty
```

## Day to day

Config files are symlinks into this repo, so edits on any Mac show up in
`git status` here. Commit + push them; on other Macs run `syncdot`
(`git pull` + reload shell). Add new packages to `Brewfile`.
