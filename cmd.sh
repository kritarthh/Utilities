#!/bin/bash
my_dir="$(dirname "$0")"
# make sure you have a variables.sh file in the cwd
if [ ! -f $my_dir/variables.sh ]; then
    echo "Variables not found, please place the variables.sh file in $my_dir"
    exit 1
fi
source "$my_dir/variables.sh"


function remote {
    tmux send-keys -t $session "$1" C-m
}

function init_ssh_cd_source {
    # remote "zsh"
    remote "ssh $USER@$MS_IP"
    remote "cd $PC_DIR"
    remote "source bin/activate"
}

function get_first_line {
    tmux capture-pane -S 0 -E 0 -t $session
    tuser=$(tmux save-buffer -)
    tmux delete-buffer
}

function get_user {
    remote C-c
    remote "clear && whoami"
    # wait for the tmux output to settle down
    sleep 0.5s
    get_first_line
}

function ensure_ssh {
    get_user
    if [ "$tuser" != "$USER" ]; then
        echo "ssh broken"
        init_ssh_cd_source && echo "ssh fixed"
    fi
}

# create tmux 
tmux new-session -d -s $session 2> /dev/null
ensure_ssh

case "$1" in
    ("tail") remote "tail -f $LOG_FILE" C-m && echo "tail success" ; exit 0 ;;
    ("cdr")  rsync -av --rsync-path="sudo rsync" -e ssh $USER@$MS_IP:$XML_DIR/$2.cdr.xml cdr.xml ; grep "plivo_hangup" cdr.xml |cut -d'>' -f2 |cut -d'<' -f1 |sed 's/%20/ /g' ; exit 0 ;;
    ("copy") rsync -av --rsync-path="sudo rsync" -e ssh $MY_DIR/$2 $USER@$MS_IP:$SRC_DIR ; exit 0 ;;
    ("deploy") echo "$1"ing "$2";;
esac

# install
remote "sudo python setup.py install"


# restart
remote "sudo $service restart"
remote "sudo $service status"
