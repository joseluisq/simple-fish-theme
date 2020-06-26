# Borrowed from https://github.com/fishpkg/fish-humanize-duration/blob/master/humanize_duration.fish 
function ___humanize_duration -d "Make a time interval human readable"
    command awk '
        function hmTime(time, stamp) {
            split("h:m:s:ms", units, ":")
            t = int(time / (60 ^ 2 * 1000))
            stamp = stamp t units[1] " "
            for (i = 1; i >= -1; i--) {
                if (t = int( i < 0 ? time % 1000 : time / (60 ^ i * 1000) % 60 )) {
                    stamp = stamp t units[sqrt((i - 2) ^ 2) + 1] " "
                }
            }
            if (stamp ~ /^ *$/) {
                return "0ms"
            }
            return substr(stamp, 1, length(stamp) - 1)
        }
        { print hmTime($0) }
    '
end

function ___has_status_failed
    set -l v_status
    set -l v_color_normal (set_color normal)

    # take $status as optional argument to maintain compatibility
    if set v_status (string match -r -- '^\d+$' $argv[1])
        set -e argv[1]
    else
        # default to $pipestatus[-1]
        set v_status $argv[-1]
    end

    # Only print status codes if the job failed.
    # SIGPIPE (141 = 128 + 13) is usually not a failure, see #6375.
    if test $v_status -ne 0 && test $v_status -ne 141
        echo -n 1
    else
        echo -n 0
    end
end

function fish_prompt --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus
    set -l last_status $status
    set -l normal (set_color normal)

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l suffix ' >'
    if contains -- $USER root toor
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix ' #'
    end

    # If we're running via SSH, change the host color.
    set -l color_host $fish_color_host
    if set -q SSH_TTY
        set color_host $fish_color_host_remote
    end

    # check for status execution
    set -l prompt_status_color (set_color $fish_color_user)

    if test (___has_status_failed $last_status) -eq 1
        set prompt_status_color (set_color $fish_color_status)
    end

    set -l duration ""

    if test "$CMD_DURATION" -gt 250
        set duration (command echo -n $CMD_DURATION | ___humanize_duration)
        set duration (set_color $fish_color_comment; echo -n "[$duration] ")
    end

    echo -ns \
        (set_color $fish_color_user) "$USER" \
        $normal @ (set_color $color_host) \
        (prompt_hostname) \
        $normal ' ' \
        (set_color $color_cwd) (prompt_pwd) \
        $normal (fish_vcs_prompt) \
        $prompt_status_color $suffix \
        $normal " " \
        $duration
end
