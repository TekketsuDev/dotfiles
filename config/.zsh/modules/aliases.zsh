# # ================================
# ~/.zsh/modules/aliases.zsh
# ================================
alias ls='eza -a --icons'
alias ll='eza -al --icons --color=always'
alias lt='eza -a --tree --level=1 --icons'
alias sized='du -hxd1 "$PWD" | sort -hr | head -20'
alias garbage_doc='find . -type f \( -iname "*.pdf" -o -iname "*.docx" -o -iname "*.doc" \) -exec mv {} $HOME/garbage_collector/docs \;'
alias tree='tree -a -I ".github|.git|Wallpapers|lib"'
alias treeh='tree -a -I ".github|.git|Wallpapers|lib" -p'
#alias treed='eza --tree -a --color=always --group-directories-first -I ".github|.git|Wallpapers|lib" -p'
alias treed='eza --tree -la --color=always --group-directories-first --no-time --ignore-glob=".github|.git|Wallpapers|lib"'
alias mini='~/mini-moulinette/mini-moul.sh'
alias vim='nvim'
alias mini='~/mini-moulinette/mini-moul.sh'
gcc-win() {
    local output=""
    local args=()

    # Parse -o output
    for ((i = 1; i <= $#; i++)); do
        if [[ "${@[$i]}" == "-o" ]]; then
            output="${@[$((i+1))]}"
        fi
        args+=("${@[$i]}")
    done

    # If no -o given, default to a.out.exe
    [[ -z "$output" ]] && output="a.exe"

    # Compile
    x86_64-w64-mingw32-gcc "${args[@]}" -lws2_32 -Wl,--subsystem,console

    # Run with wine if compilation succeeded
    if [[ $? -eq 0 ]]; then
        echo "🔧 Compilation successful. Running with wine: $output"
        wine "$output"
    else
        echo "❌ Compilation failed."
        return 1
    fi}
