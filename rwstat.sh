n_arg=$#
time=${@: -1}
re='^[0-9]+$'


if [ $n_arg -le 0 ]; then
    echo "Parâmetro obrigatório em falta (Tempo em segundos )"
    exit $E_ASSERT_FAILED
fi
 
 
if ! [[ $time =~ $re ]] ; then # se o argumento final não for um numero o programa não corre
    echo "O ultimo argumento tem de ser o tempo"
    exit $E_ASSERT_FAILED
fi



proc_reg="."
user_reg="."
min_date=-1
max_date=$(($(date "+%s")+10000))
min_PID=-1
max_PID=$( cat /proc/sys/kernel/pid_max )
order_of_sort="-k 4 -n"

p=4


while getopts c:s:e:u:m:M:p:wr option ; do
    case $option in

     c) proc_reg=$OPTARG;;
     s) 
      if [ $(date -d "$OPTARG" 2>: 1>:; echo $?) == 1 ]; then # 2>: limpar stderr, 1>: limpar stdout
        echo "Data inicial invalida"
        exit $E_ASSERT_FAILED
      fi
      min_date=$(date -d "$OPTARG" "+%s")
      ;;
     e) 
      if [ $(date -d "$OPTARG" 2>: 1>:; echo $?) == 1 ]; then
          echo "Data final invalida"
          exit $E_ASSERT_FAILED
      fi
      max_date=$(date -d "$OPTARG" "+%s")
      ;;
     
     u) user_reg=$OPTARG;;
     m) 
      if ! [[ $OPTARG =~ $re ]] ; then # se o argumento final não for um numero o programa não corre
        echo "PID minimo tem de ser um inteiro"
        exit $E_ASSERT_FAILED
      fi
      min_PID=$OPTARG
     ;;
     M) 
      if ! [[ $OPTARG =~ $re ]]; then # se o argumento final não for um numero o programa não corre
        echo "PID maximo tem de ser um inteiro"
        exit $E_ASSERT_FAILED
      fi
      max_PID=$OPTARG
      ;;
     p) p=$OPTARG;;
     w) order_of_sort="-k 5 -n";;
     r) order_of_sort=$(echo $order_of_sort)" -r";;

    esac
done

printf "%-10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\n\n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"

# THE HOLY LINE >> AWK IS OVERPOWERED
data=( $(ps -eo euser,pid,lstart | tail -n +2 \
| awk '{"if [[ -f /proc/"$2"/comm ]]; then cat /proc/"$2"/comm ; fi" | getline proc_name; close(proc_name); regex="'$proc_reg'"; if ( (proc_name ~ regex) ){print $0 } }' \
| awk '$1 ~ "'$user_reg'" {print $0}' \
| awk '{date=$3" "$4" "$5" "$6" "$7; "date -d \"" date "\" " "\"+%s\"" | getline timestp; if( timestp > '$min_date' && timestp < '$max_date'){ print $2,$1,timestp }}' \
| awk '{ if( $1 > '$min_PID' && $1 < '$max_PID' ){ print $0 }}' \
| awk '{"if [[ -r /proc/"$1"/io ]]; then cat /proc/"$1"/io | sed -n 1p | cut -d \" \" -f2; fi" | getline read; print $1,$2,$3,read}' \
| awk '{"if [[ -r /proc/"$1"/io ]]; then cat /proc/"$1"/io | sed -n 2p | cut -d \" \" -f2; fi" | getline write; print $1":"$2":"$3":"$4":"write}') )

# data entry: 
# 636:tiago:1669662994:0:0
# id:user:timespt:read:write

if [[ ${#data[@]} -eq 0 ]]; then
  echo "No specified entries found"
  exit 0
fi


sleep $time

{

  for entry in ${data[@]}; do

    id=$( echo $entry | cut -d ":" -f1 )
    
    if [[ -r /proc/$id/io ]];then

        i_rw=$( echo $entry | cut -d ":" -f4 )
        
        # Get date

        d=$( echo $entry | cut -d ":" -f3 )
        d=$(date -d @$d)

        # Get User

        user=$( echo $entry | cut -d ":" -f2 )

        # Get process

        process=$( cat /proc/"$id"/comm )

        # Calculate Readbytes
        i_rw=$( echo $entry | cut -d ":" -f4 )
        f_rw=$( cat /proc/$id/io | sed -n 1p | cut -d " " -f2 )
        read=$(($f_rw-$i_rw))

        # Calculate Writebytes
        i_rw=$( echo $entry | cut -d ":" -f5 )
        f_rw=$( cat /proc/$id/io | sed -n 2p | cut -d " " -f2 )
        write=$(($f_rw-$i_rw))

        # Calculate RateR

        rr=$( bc <<< "scale=2; $read / $time" )

        # Calculate RateW

        rw=$( bc <<< "scale=2; $write / $time" )

        printf "%-10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\t%10s\n" "$process" "$user" "$id" "$read B" "$write B" "$rr B/s" "$rw B/s" "$d"
        
    fi
  done

} | sort $order_of_sort |sed -n "1,$p p"

# Fixed ?

# So i thougth the readbytes and wrotebytes by a process would be the 5th and 6th entries for having that exact name,
# but the results were kinda of weird using those variables, so i searched if it really was the rigth place to search such data
# when came up to this stack overflow [response](https://stackoverflow.com/a/3634088) and by reading it, i got even more confused,
# but changed the data processing to grab data by the readchars and writechars and results were somewhat what i was expecting,
# is it wrong, is it right, idk what i know is that even doing the calculations manually the latter implementation of this script made more sense 