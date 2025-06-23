alias ls='eza -1 --color=always --icons=always --hyperlink --group-directories-first'
alias cat='bat'
alias rm='rm -i'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
direnv hook fish | source
if status is-interactive
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
