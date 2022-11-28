time=${@: -1}

proc_reg="."
user_reg="."
min_date=-1
max_date=$(($(date "+%s")+1000))
min_PID=-1
max_PID=$( cat /proc/sys/kernel/pid_max )
order_of_sort="-k 4 -n"

p=4


while getopts c:s:e:u:m:M:p:wr option ; do
    case $option in

     c) proc_reg=$OPTARG;;
     s) min_date=$(date -d "$OPTARG" "+%s");;
     e) max_date=$(date -d "$OPTARG" "+%s");;
     u) user_reg=$OPTARG;;
     m) min_PID=$OPTARG;;
     M) max_PID=$OPTARG;;
     p) p=$OPTARG;;
     w) order_of_sort="-k 5 -n";;
     r) order_of_sort=$(echo $order_of_sort)" -r";;

    esac
done



# THE HOLY LINE >> AWK IS OVERPOWERED
data=( $(ps -eo euser,pid,lstart | tail -n +2 \
| awk '{"if [[ -f /proc/"$2"/comm ]]; then cat /proc/"$2"/comm ; fi" | getline proc_name; close(proc_name); regex="'$proc_reg'"; if ( (proc_name ~ regex) ){print $0 } }' \
| awk '$1 ~ "'$user_reg'" {print $0}' \
| awk '{date=$3" "$4" "$5" "$6" "$7; "date -d \"" date "\" " "\"+%s\"" | getline timestp; if( timestp > '$min_date' && timestp < '$max_date'){ print $2,$1,timestp }}' \
| awk '{ if( $1 > '$min_PID' && $1 < '$max_PID' ){ print $0 }}' \
| awk '{"if [[ -r /proc/"$1"/io ]]; then cat /proc/"$1"/io | sed -n 5p | cut -d \" \" -f2; fi" | getline read; print $1,$2,$3,read}' \
| awk '{"if [[ -r /proc/"$1"/io ]]; then cat /proc/"$1"/io | sed -n 6p | cut -d \" \" -f2; fi" | getline write; print $1":"$2":"$3":"$4":"write}') )

# data entry:
# 636:tiago:1669662994:0:0
# id:user:timespt:read:write

printf "%-10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\n\n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"

sleep $time


function out() {

  for entry in ${data[@]}; do

    id=$( echo $entry | cut -d ":" -f1 )
    
    if [[ -r /proc/$id/io ]];then
        
        # Get date

        d=$( echo $entry | cut -d ":" -f3 )
        d=$(date -d @$d)

        # Get User

        user=$( echo $entry | cut -d ":" -f2 )

        # Get process

        process=$( cat /proc/"$id"/comm )

        # Calculate Readbytes
        i_rw=$( echo $entry | cut -d ":" -f4 )
        f_rw=$( cat /proc/$id/io | sed -n 5p | cut -d " " -f2 )
        read=$(($f_rw-$i_rw))

        # Calculate Writebytes
        i_rw=$( echo $entry | cut -d ":" -f5 )
        f_rw=$( cat /proc/$id/io | sed -n 6p | cut -d " " -f2 )
        write=$(($f_rw-$i_rw))

        # Calculate RateR

        rr=$( bc <<< "scale=2; $read / $time" )

        # Calculate RateW

        rw=$( bc <<< "scale=2; $write / $time" )

        printf "%-10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\n" "$process" "$user" "$id" "$read B" "$write B" "$rr B/s" "$rw B/s" "$d"
        
    fi
  done

}

out | sort $order_of_sort |sed -n "1,$p p"