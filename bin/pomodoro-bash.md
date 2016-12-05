# Windows

To enable pop-up notifications, install:
* http://vaskovsky.net/notify-send/
* http://www.paralint.com/projects/notifu/index.html

To enable sounds, install:
* http://www.videolan.org/vlc/
* madplay (available from https://www.cygwin.com/)

To make a shortcut in the Start Menu:
1. Install https://www.cygwin.com/
1. Create a shortcut with a target like one of these:
  * `C:\cygwin\bin\mintty.exe -i C:\Users\Gabriel\config\local\pomodoro-bash\images\tomato13.ico -o Scrollbar=None -o ScrollbackLines=0 --title "Pomodoro Bash" -e /usr/bin/bash -il pomodoro-bash`
  * `C:\cygwin\bin\mintty.exe -i C:\Users\Gabriel\config\local\pomodoro-bash\images\tomato13.ico -o Scrollbar=None -o ScrollbackLines=0 --title "Pomodoro Bash"  -e C:\Users\Gabriel\bin\cygwin-bootstrap pomodoro-bash`
