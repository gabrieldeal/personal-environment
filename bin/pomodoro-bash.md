# QA

* `for n in dash bash posh ; do POSIXLY_CORRECT=1 dash bin/pomodoro-bash -p -w 5 -b 5; done`
* https://github.com/koalaman/shellcheck
* `checkbashisms --force --posix bin/pomodoro-bash`

# Windows

To enable pop-up notifications, install one of these:
* http://vaskovsky.net/notify-send/
* http://www.paralint.com/projects/notifu/index.html

To enable sounds, install one of these:
* http://www.videolan.org/vlc/
* madplay (available from https://www.cygwin.com/)

To make a pretty shortcut in the Start Menu:
1. Install https://www.cygwin.com/
1. Create a shortcut with a target like one of these:
  * `C:\cygwin\bin\mintty.exe -i C:\Users\Gabriel\config\local\pomodoro-bash\images\tomato13.ico -o Scrollbar=None -o ScrollbackLines=0 --title "Pomodoro Bash" -e /usr/bin/bash -il pomodoro-bash`
  * `C:\cygwin\bin\mintty.exe -i C:\Users\Gabriel\config\local\pomodoro-bash\images\tomato13.ico -o Scrollbar=None -o ScrollbackLines=0 --title "Pomodoro Bash"  -e C:\Users\Gabriel\bin\cygwin-bootstrap pomodoro-bash`

# Debugging

Under bash:
```
dump_stack() {
  local frame=0
  while caller $frame; do
      frame=$((frame + 1));
  done
}
```

# To do

* Use https://github.com/matryer/bitbar to display status in the MacOS status menu.
* Windows taskbar notification
  * Shell_NotifyIcon(): https://www.codeproject.com/kb/shell/stealthdialog.aspx
  * http://www.mingw.org/

