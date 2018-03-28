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

if [[ $SYSTEM = *"oak"* ]]
then
	NODE=12
elif [[ $SYSTEM = *"ruby"* ]]
then
	NODE=20
elif [[ $SYSTEM = *"owens"* ]]
then 
	NODE=28
else
	NODE=50
	echo "system is not in the list. Assume 50 cores per node"
fi


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

-- Low Efficiency Jobs (efficiency < 0.05 and CPU hours > value that is equivalent to 1 whole node for 24 hours)
 
EOF
cpu=$(($NODE*24))


mysql -hdbsys01.infra -uwebapp pbsacct --execute=" 
SELECT username, jobid,(TIME_TO_SEC(cput)/3600.0)/(nproc*TIME_TO_SEC(walltime)/3600.0) AS efficiency, nproc*TIME_TO_SEC(walltime)/3600.0 FROM Jobs WHERE system LIKE '$SYSTEM' and (start_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) ) and (nproc*TIME_TO_SEC(walltime)/3600.0 > $cpu) and ((TIME_TO_SEC(cput)/3600.0)/(nproc*TIME_TO_SEC(walltime)/3600.0) < 0.05) ORDER by efficiency;" >>${SYSTEM}_${DATE}.dat



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


