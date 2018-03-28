#!/bin/bash
##############################################################################
# batch_status.sh
#
# The HPC Client Services group has a weekly operational meeting on Mondays.
# During this meeting the status of the batch system is discussed and reviewed.
#
# This script is intended to be run as a cronjob, run weekly on Monday mornings.
# The output is saved, and used for the weekly operational meeting.
#
# The output includes various statistics on system utilization.
#
# Author:       Summer Wang <xwang@osc.edu>
# Date:         January 2017

# Global Defaults
TIMEOUT_LIMIT="600"
RANGE="-168:00:00"
SYSTEM=$LMOD_SYSTEM_NAME
CMD_REMOVE_EXTRAS="grep -v '^$'"
DATE=`date +%y%m%d`

cat <<EOF >>${SYSTEM}_${DATE}.dat
    -- -- -- -- Usage Summary for $SYSTEM -- -- -- --

-- Settings
TIMEOUT_LIMIT = $TIMEOUT_LIMIT
RELEVANT DATE RANGE = $RANGE

-- Statistics for Classes of Jobs
EOF
showstats -c -t $RANGE --timeout=$TIMEOUT_LIMIT | sed "s/  */&:/g" |awk -vC0='\033[0;0m' -vC1='\033[1;35m' ' { if(NR<4){$1=$1} else {$6=C1$6C0; $10=C1$10C0; $14=C1$14C0}; print }' FS=":" >>${SYSTEM}_${DATE}.dat

cat <<EOF >>${SYSTEM}_${DATE}.dat

-- Usage Statistics by QoS
EOF
showstats -q -t $RANGE --timeout=$TIMEOUT_LIMIT | sed "s/  */&:/g" |awk -vC0='\033[0;0m' -vC1='\033[1;35m' ' { if(NR<4){$1=$1} else {$6=C1$6C0; $10=C1$10C0; $14=C1$14C0}; print }' FS=":" >>${SYSTEM}_${DATE}.dat

cat <<EOF >>${SYSTEM}_${DATE}.dat

-- Top Groups by usage ( Sorted by CPU time)
PHDed = Total proc-hours dedicated to active and completed jobs.
Red: AvgQH > 12 hours or Effic < 20%
EOF
showstats -a -t $RANGE --timeout=$TIMEOUT_LIMIT | head -n 4 | $CMD_REMOVE_EXTRAS >temp2.dat
showstats -a -t $RANGE --timeout=$TIMEOUT_LIMIT | head -n 15 | $CMD_REMOVE_EXTRAS >temp1.dat
awk 'NR==FNR{a[$1]=$2 " " $3;next} ($1) in a{print $0, " ", a[$1]}' projectPI.txt temp1.dat >> temp2.dat
sed "s/  */&:/g" temp2.dat |awk -vC0='\033[0;0m' -vC1='\033[1;31m' '(NR<5){{$1=$1;$0=C0$C0}; print ;next}{if($14>12 || $15<20){$1=$1;$0=C1$0C0} else {$1=$1;$0=C0$C0}; print }' FS=":" >> ${SYSTEM}_${DATE}.dat
rm temp*.dat

cat <<EOF >>${SYSTEM}_${DATE}.dat

-- Top Users by usage ( Sorted by CPU time)
PHDed = Total proc-hours dedicated to active and completed jobs.
Red: AvgQH > 12 hours or Effic < 20%
EOF
showstats -u -t $RANGE --timeout=$TIMEOUT_LIMIT | head -n 4 | $CMD_REMOVE_EXTRAS >temp0.dat
showstats -u -t $RANGE --timeout=$TIMEOUT_LIMIT | head -n 15 | awk '(NR>4){print $0}' | $CMD_REMOVE_EXTRAS >temp1.dat
cat temp1.dat | awk '{print $1}'|xargs finger |grep Name | awk '{$1=$2=$3="";print}' >> temp2.dat
awk 'NR==FNR{a[NR]=$0;next}{print a[FNR],$0}' temp1.dat temp2.dat >>temp0.dat
sed "s/  */&:/g" temp0.dat |awk -vC0='\033[0;0m' -vC1='\033[1;31m' '(NR<5){{$1=$1;$0=C0$C0}; print ;next}{if($14>12 || $15<20){$1=$1;$0=C1$0C0} else {$1=$1;$0=C0$C0}; print }' FS=":" >> ${SYSTEM}_${DATE}.dat
rm temp*.dat

cat <<EOF >>${SYSTEM}_${DATE}.dat

-- Longest Average Queue Time by Users with Queue Time is more than 2 hours
Queue time includes time spent in various holds
Red: Effic < 20% 
Blue: WCAcc < 20%
EOF
showstats -u -t $RANGE --timeout=$TIMEOUT_LIMIT | awk 'NR<5{print $0;next}' | $CMD_REMOVE_EXTRAS >temp0.dat
showstats -u -t $RANGE --timeout=$TIMEOUT_LIMIT | awk '(NR>4 && $14>2){print $0 | "sort -r -k 14n,14 | tac | head"}' | $CMD_REMOVE_EXTRAS >temp1.dat
cat temp1.dat | awk '{print $1}'|xargs finger |grep Name | awk '{$1=$2=$3="";print}' > temp2.dat
awk 'NR==FNR{a[NR]=$0;next}{print a[FNR],$0}' temp1.dat temp2.dat >>temp0.dat
sed "s/  */&:/g" temp0.dat |awk -vC0='\033[0;0m' -vC1='\033[1;31m' -vC2='\033[1;34m' '(NR<5){{$1=$1;$0=C0$C0}; print ;next}{if($15<20){$1=$1;$0=C1$0C0} else if ($16<20){$1=$1;$0=C2$0C0} else {$1=$1;$0=C0$C0}; print }' FS=":" >>${SYSTEM}_${DATE}.dat
rm temp*.dat

cat <<EOF >>${SYSTEM}_${DATE}.dat

-- Least Efficient Users with no less than 5 jobs and PHDed > 1% and Effic <80%
Effic = Actual CPU hours / Allocated CPU hours
RED: PHDed > 10% and Effic <20%
EOF
showstats -u -t $RANGE --timeout=$TIMEOUT_LIMIT | awk 'NR<5{print $0;next}' | $CMD_REMOVE_EXTRAS >temp0.dat
showstats -u -t $RANGE --timeout=$TIMEOUT_LIMIT | awk '(NR>4 && $5 > 4 && $10 > 1 && $15 <80){print $0 | "sort -r -k 15n,15 | head"}'| $CMD_REMOVE_EXTRAS >temp1.dat
cat temp1.dat | awk '{print $1}'|xargs finger |grep Name | awk '{$1=$2=$3="";print}' > temp2.dat
awk 'NR==FNR{a[NR]=$0;next}{print a[FNR],$0}' temp1.dat temp2.dat >>temp0.dat
sed "s/  */&:/g" temp0.dat |awk -vC0='\033[0;0m' -vC1='\033[1;31m' '(NR<5){{$1=$1;$0=C0$C0}; print ;next}{if($10>10 && $15 <20){$1=$1;$0=C1$0C0} else {$1=$1;$0=C0$C0}; print }' FS=":" >>${SYSTEM}_${DATE}.dat
rm temp*.dat

cat <<EOF >>${SYSTEM}_${DATE}.dat
 
-- Blocked Jobs
Are any of these forgotten?  Non-runnable?
EOF
showq -b | grep -v -E 'blocked|jobs|JOBID|^$' |sort -r -k1,2 |awk '{ c[$2]++; t[$2]=$7" "$8" "$9" "$10} END {  print "Job Count,", "User,", "Oldest Queue Time";for (i in c) print c[i],",", i,",", t[i]}'|column -t -s ',' >temp1.dat
echo > temp2.dat
sed 1d temp1.dat | awk '{print $2}'|xargs finger |grep Name | awk '{$1=$2=$3="";print}' >> temp2.dat
awk 'NR==FNR{a[NR]=$0;next}{print a[FNR],$0}' temp1.dat temp2.dat >>${SYSTEM}_${DATE}.dat
rm temp*.dat

cat <<EOF >>${SYSTEM}_${DATE}.dat
 
-- Eligible Jobs, Sort by Queue Time
EOF
#showq -i | grep "eligible jobs" |tail -1  >>${SYSTEM}_${DATE}.dat
#showq -i | sort -r -k 10n,10 |grep -v '^$' | tail -n +5 | awk '{ c[$5]++; t[$5]=$10" "$11" "$12" "$13} END {  print "Job Count,", "User,", "Oldest Queue Time";for (i in c) print c[i],",", i,",", t[i]}'|column -t -s ',' | head > temp1.dat
#echo > temp2.dat
#sed 1d temp1.dat | awk '{print $2}'|xargs finger |grep Name | awk '{$1=$2=$3="";print}' >> temp2.dat
#awk 'NR==FNR{a[NR]=$0;next}{print a[FNR],$0}' temp1.dat temp2.dat >>${SYSTEM}_${DATE}.dat
#rm temp*.dat
showq -i |awk 'NR<5{print $0;next}{print $0 | "sort -r -k 10n,10 | tac |head -20 "}' | grep -v '^$' >>${SYSTEM}_${DATE}.dat
cat <<EOF >>${SYSTEM}_${DATE}.dat
 
-- Non-Job Reservations
EOF
showres | grep -v debug* | awk '$2 == "User" { print $0 }' >>${SYSTEM}_${DATE}.dat


