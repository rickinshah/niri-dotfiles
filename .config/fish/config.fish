alias ls='eza -1 --color=always --icons=always --hyperlink --group-directories-first'
alias cat='bat'
alias rm='rm -i'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias cd='z'
zoxide init fish | source
direnv hook fish | source
if status is-interactive

    function fish_command_not_found
        if type -q yay
            echo "Command '$argv' not found. Searching in packages..."
            pacman -F $argv
        else
            echo "Command '$argv' not found and 'yay' is not installed."
        end
    end
    # Commands to run in interactive sessions can go here
    function auto_activate_venv --on-variable PWD
        if test -f .venv/bin/activate.fish
            if not set -q VIRTUAL_ENV
                source .venv/bin/activate.fish
            end
        else if set -q VIRTUAL_ENV
            deactivate
        end
    end

    set -g fish_greeting
    fastfetch
    stty -icanon -echo
    dd bs=1 count=1 >/dev/null 2>&1
    stty icanon echo
end
