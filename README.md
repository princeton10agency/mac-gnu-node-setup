\
    # mac-gnu-node-setup

    Contents:
    - `bootstrap-gnu.sh`: Install Homebrew, GNU coreutils (unprefixed), and NVM + Node LTS.
    - `nvm-auto-use.zsh`: Auto `nvm use` on `cd` for zsh inside Git repos with `.nvmrc`.
    - `nvm-auto-use.bash`: Auto `nvm use` on `cd` for bash inside Git repos with `.nvmrc`.

    ## Quick start
    1. Download `bootstrap-gnu.sh`, make it executable, run it:
       ```sh
       chmod +x bootstrap-gnu.sh
       ./bootstrap-gnu.sh
       ```
    2. Add the appropriate `nvm-auto-use` snippet to your shell:
       - zsh: append `nvm-auto-use.zsh` to `~/.zshrc`
       - bash: append `nvm-auto-use.bash` to `~/.bash_profile` or `~/.bashrc`

    After opening a new terminal, `make`, `sed`, `tar`, etc. should be GNU versions,
    and `cd`-ing into a repo with `.nvmrc` will auto-switch Node.
