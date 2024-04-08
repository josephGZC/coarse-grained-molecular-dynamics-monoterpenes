#!/bin/bash
# EXTENSION SCRIPT 
# DATE WRITTEN: MARCH 21, 2021
# DATE UPDATED: AUGUST 30, 2021
# PURPOSE: extend production in increments until target time is reached 

echo " "
echo " | EXTENSION SCRIPT | EXTENDS PRODUCTION RUN IN GROMACS | "
echo " "

# ========================================================
# ------------------    REMINDERS    --------------------- 
# ========================================================

# 1. only works for production files labelled as: step7_production_(ID)
#
# 2. declare important variables in section I, for:
#    a. name of production mdp file
#    b. number of processors designated for extension of production run
#    c. target time in ps
#    d. name of log file
# 
# 3. length of each increment is equal to first length of production run
#
# 4. run file in csrc as nohup "./EXTENSION_MULTIPLE.sh" > out.log &

# ========================================================
# -------------------    SECTIONS    --------------------- 
# ========================================================

# I.    DECLARE VARIABLES    
#
# II.   SET SCRIPT FUNCTIONS
#
# III.  DETERMINE PRODUCTION PARAMETERS
#
# IV.   DETERMINE LATEST PRODUCTION RUN 
#
# V.    INITIATE EXTENSION LOOP
#
# VI.   REGISTER STRUCTURE FILENAMES
#
# VII.  GENERATE NEW TPR FOR EXTENSION RUN
#
# VIII. SIMULATIE EXTENSION RUN
#
# IX.   CONCATENATE NEW TRAJECTORY TO INITIAL

# <=======================================================
# <==== I. DECLARE VARIABLES
# <=======================================================

prodmdp="step7_production.mdp"                                              #production mdp file
srvcnt=16                                                                   #number of processors
trtime=1000000								    #target time in ps
logfile="out_sh_1.log"  						    #log file                                                                                                                               

# <=======================================================
# <==== II. SET SCRIPT FUNCTIONS
# <=======================================================

function checkdisk(){ 
cp ${logfile} inspect_multiplelog.out && 
grep -cim1 "out of disk space" inspect_multiplelog.out &&
echo "ERROR [0]: OUT OF DISK SPACE" && exit
yes | rm inspect_multiplelog.out
}

# <=======================================================                 
# <==== III. DETERMINE PRODUCTION PARAMETERS                                
# <=======================================================                 
                                                                           
dt=$(awk '/dt / {print $3}' < $prodmdp)                                     #gets dt in mdp file
nsteps=$(awk '/nsteps / {print $3}' < $prodmdp)                             #gets nsteps in mdp file
timbin=$(echo $dt $nsteps | awk '{print $1*$2}')                            #calculates prod time in ps
                                                                           
# <=======================================================                 
# <==== IV. DETERMINE LATEST PRODUCTION RUN                            
# <=======================================================                 
                                                                           
ls step7*.gro | sort --version-sort -f > list1.txt                          
setmrk=$(tail -1 list1.txt | cut -c 18-20 | tr -d -c 0-9  )                 #finds latest ID generate
idnum1=$(($setmrk - 1))                                                     #preparation to enter while loop
gotime=$(($timbin * $setmrk))                                               #accumulates time

# <=======================================================                 
# <==== V. INITIATE EXTENSION LOOP                           
# <=======================================================                 

while [[ $gotime -ne $trtime ]]                                             #keep looping until target time reached
do
gotime=$(( $gotime + $timbin ))

# <=======================================================                 
# <==== VI. REGISTER STRUCTURE FILENAMES                           
# <=======================================================                 

idnum1=$(( $idnum1 + 1 )) 			    
idnum2=$(( $idnum1 + 1 )) 

prodnc="step7_production_$idnum1"
prodnn="step7_production_$idnum2"

checkc="000${idnum1}"
checkn="000${idnum2}"

alignc=$(echo $checkc | rev | cut -b 1-4 | rev)                             #part.0009 is different from part.0010 
alignn=$(echo $checkn | rev | cut -b 1-4 | rev)                             #if id is at 10 or above, important to cut zeroes 

suffxc="${prodnc}.part${alignc}"
suffxn="${prodnn}.part${alignn}"

[[ ! -f ${prodnc}.gro ]] && 
[[ ! -f ${suffxc}.gro ]] &&   
echo "ERROR [1]: ${prodnc}.gro AND ${suffxc}.gro DOES NOT EXIST" && exit

# <=======================================================
# <==== VII. GENERATE NEW TPR FOR EXTENSION RUN 
# <=======================================================

gmx convert-tpr -s ${prodnc}.tpr -until $gotime -o ${prodnn}.tpr  
checkdisk 

[[ ! -f "${prodnn}.tpr" ]] && 
echo "ERROR [2]: ${prodnn}.tpr DOES NOT EXIST" && exit

# <=======================================================
# <==== VIII. SIMULATE EXTENSION RUN
# <=======================================================

gmx mdrun -s ${prodnn}.tpr -cpi ${prodnc}.cpt -noappend -deffnm ${prodnn} -v -nt ${srvcnt}
checkdisk

[[ ! -f "${suffxn}.gro" ]] &&
echo "ERROR [3]: ${suffxn}.gro DOES NOT EXIST" && exit

# <=======================================================
# <==== IX. CONCATENATE NEW TRAJECTORY TO INITIAL 
# <=======================================================

if [[ $idnum1 == 1 ]]; then
gmx trjcat -f ${prodnc}.trr ${suffxn}.trr -o ${prodnc}-${idnum2}.trr
checkdisk

else
gmx trjcat -f step7_production_1-${idnum1}.trr ${suffxn}.trr -o step7_production_1-${idnum2}.trr
checkdisk

[[ -f "step7_production_1-${idnum2}.trr" ]] &&                   #!activate this only when small disk space left
yes | rm step7_production_1-${idnum1}.trr &&     
yes | rm ${suffxn}.trr
fi

[[ ! -f "system_production_1-2.trr" ]] && 
[[ ! -f "step7_production_1-${idnum2}.trr" ]] &&
echo "ERROR [4]: MISSING .trr FILE" && exit

done

# ========================================================
# ------------------      END      ----------------------- 
# ========================================================

echo " "
echo "...DONE"
echo " "

duration=$SECONDS
echo " | TIME ELAPSED: $(($duration / 60)) MINUTE/S and $(($duration % 60)) SECOND/S |"
echo " "
