time=${@: -1}

proc_reg="."
user_reg="."
min_date=-1
max_date=$(($(date "+%s")+1000))
min_PID=-1
max_PID=$( cat /proc/sys/kernel/pid_max )
p=4

while getopts c:s:e:u:m:M:p:rw option ; do
    case $option in
     c)
      proc_reg=$OPTARG
      ;;
     s)
      min_date=$(date -d "$OPTARG" "+%s")
      ;;
     e)
      max_date=$(date -d "$OPTARG" "+%s")
      ;;
     u)
      user_reg=$OPTARG
      ;;
     m)
      min_PID=$OPTARG
      ;;
     M)
      max_PID=$OPTARG
      ;;
     p)
      p=$OPTARG
      ;;
     r)
      reverse=true
      ;;
     w)
      srt=true
      ;;
    esac
done


# THE HOLY LINE >> AWK IS OVERPOWERED
ps -eo euser,pid,lstart | tail -n +2 \
| awk '{date=$3" "$4" "$5" "$6" "$7; "date -d \"" date "\" " "\"+%s\"" | getline timestp; print $1,$2,timestp}' \
| awk '{"if [ -f /proc/"$2"/comm ]; then cat /proc/"$2"/comm ; fi" | getline proc_name; close(proc_name); regex="'$proc_reg'"; if ( (proc_name ~ regex) ){print $0 } }' \
| awk '{regex="'$user_reg'"; if ( ($1 ~ regex) ){print $0} }' \
| awk '{ if( $3 > '$min_date' && $3 < '$max_date'){ print $0 }}' \
| awk '{ if( $2 > '$min_PID' && $2 < '$max_PID' ){ print $0 }}'