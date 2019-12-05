#!/bin/bash
my_dir="$(dirname "$0")"

# make sure you have a variables.sh file in the cwd
if [ ! -f $my_dir/variables_$CMD_SERVER_TYPE.sh ]; then
    echo "Variables not found, please place the variables_$CMD_SERVER_TYPE.sh file in $my_dir"
    exit 1
fi
source "$my_dir/variables_$CMD_SERVER_TYPE.sh"


function remote {
    tmux send-keys -t $session "$1" C-m
}

function init_ssh_cd_source {
    # remote "zsh"
    remote "ssh $USER@$MS_IP"
}

function get_first_line {
    tmux capture-pane -S 0 -E 0 -t $session
    tuser=$(tmux save-buffer -)
    tmux delete-buffer
}

function get_user {
    remote C-c
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
    ("put") rsync -av --exclude=".*" --rsync-path="sudo rsync" -e ssh $2 $USER@$MS_IP:$3 ; exit 0 ;;
    ("fetch") rsync -av --exclude=".*" --rsync-path="sudo rsync" -e ssh $USER@$MS_IP:$2 `[ -z "$3" ] && echo ./ || echo $3`; exit 0 ;;
    ("deploy") echo "$1"ing "$2"; remote "cd /opt/plivocom"; remote "source bin/activate"; remote "sudo python setup.py install -f"; remote "sudo plivocomm restart"; remote "sudo systemctl restart rsyslog" ;;
esac

#remote "cd /opt/plivocom"
#remote "source bin/activate"
#remote "sudo python setup.py install -f"
#remote "sudo plivocomm restart"
#remote "sudo systemctl restart rsyslog"
#remote "sudo tail -F /mnt/data/log/plivo.log"
