Source common.tape
Output hero.gif
Hide
Type "tmux -L revamped-screens attach -t demo"
Enter
Sleep 1.5s
Show
Sleep 2500ms
Screenshot playing.png
Sleep 800ms
Hide
Ctrl+]
Type@5ms "prefix M-m, n"
Enter
Show
Ctrl+B
Escape
Type@1ms "m"
Sleep 2s
Screenshot menu.png
Sleep 1s
Type "n"
Sleep 3500ms
Screenshot next.png
Sleep 1s
Hide
Ctrl+]
Type@5ms "prefix M-p"
Enter
Show
Ctrl+B
Escape
Type@1ms "p"
Sleep 3500ms
Screenshot paused.png
Sleep 1s
Hide
Ctrl+]
Type@5ms "prefix M-p"
Enter
Show
Ctrl+B
Escape
Type@1ms "p"
Sleep 3s
Hide
Ctrl+]
Type@5ms "prefix M-b"
Enter
Show
Ctrl+B
Escape
Type@1ms "b"
Sleep 3500ms
Screenshot previous.png
Sleep 1s
Hide
Ctrl+]
Type@5ms "tmux set -g @music_revamped_max_len 6"
Enter
Show
Sleep 800ms
Type "tmux set -g @music_revamped_max_len 6"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot cut.png
Sleep 1s
Hide
Ctrl+]
Type@5ms "tmux set -g @music_revamped_max_len 0"
Enter
Show
Sleep 800ms
Type "tmux set -g @music_revamped_max_len 0"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Type@5ms "tmux set -g status-right #{music_icon} #{music} #{music_time}"
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{music_icon} #{music} #{music_time} '"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1500ms
Hide
Ctrl+]
Type@5ms "tmux set -g @music_revamped_render options"
Enter
Show
Sleep 800ms
Type "tmux set -g @music_revamped_render options"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Type@5ms "music-revamped apply"
Enter
Show
Sleep 800ms
Type "music-revamped apply"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 2500ms
Hide
Ctrl+]
Type@5ms "tmux show -gv status-right"
Enter
Show
Sleep 800ms
Type "tmux show -gv status-right"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 2500ms
Screenshot options.png
Sleep 1s
Hide
Ctrl+]
Type@5ms "prefix M-n"
Enter
Show
Ctrl+B
Escape
Type@1ms "n"
Sleep 2500ms
Screenshot options-next.png
Sleep 1500ms
