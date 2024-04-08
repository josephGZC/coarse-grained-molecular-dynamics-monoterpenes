#!/bin/bash
# EXTENSION SCRIPT 
# DATE WRITTEN: MARCH 21, 2021
# DATE UPDATED: AUGUST 30, 2021
# PURPOSE: one-time extension of production run

echo " "
echo " | EXTENSION SCRIPT | ONE-TIME EXTENSION OF PRODUCTION RUN | "
echo " "

# ========================================================
# ------------------    REMINDERS    ---------------------
# ========================================================

# 1. only works for production files labelled as: step7_production_(ID)
#
# 2. declare important variables in section I, for:
#    a. number of threads designated for extension of production run
#    b. desired length of extension in ps
#    c. name of log file
#
# 3. run file in csrc as nohup "./EXTENSION_SINGLE.sh" > out.log &

# ========================================================                                                                                                                               
# -------------------    SECTIONS    ---------------------
# ========================================================

# I.   DECLARE VARIABLES
#
# II.  SET SCRIPT FUNCTIONS
#
# III. DETERMINE LATEST PRODUCTION RUN
#
# IV.  REGISTER STRUCTURE FILENAMES
#
# V.   GENERATE NEW TPR FOR EXTENSION RUN
#
# VI.  SIMULATIE EXTENSION RUN
#
# VII. CONCATENATE NEW TRAJECTORY TO INITIAL

# <=======================================================
# <==== I. DECLARE VARIABLES
# <=======================================================

srvcnt=24                                                                    #number of processors
gotime=20000                                                                 #length of extension in ps
logfile="out_sh_9.log"           					     #log file

# <=======================================================
# <==== II. SET SCRIPT FUNCTIONS
# <=======================================================

#function checkdisk(){
#cp ${logfile} inspect_multiplelog.out &&
#grep -cim1 "out of disk space" inspect_multiplelog.out &&
#echo "ERROR [0]: OUT OF DISK SPACE" && exit
#yes | rm inspect_multiplelog.out
#}

# <=======================================================
# <==== III. DETERMINE LATEST PRODUCTION RUN
# <=======================================================

ls step7*.gro | sort --version-sort -f > list1.txt

# <=======================================================
# <==== IV. REGISTER STRUCTURE FILENAMES
# <=======================================================

idnum1=$(tail -1 list1.txt | cut -c 18-20 | tr -d -c 0-9  )                  #finds latest ID generated
idnum2=$(($idnum1 + 1))                                                      #value of next ID to be generated

prodnc="step7_production_$idnum1"
prodnn="step7_production_$idnum2"

checkc="000${idnum1}"
checkn="000${idnum2}"

alignc=$(echo $checkc | rev | cut -b 1-4 | rev)                              #part.0009 is different fr
alignn=$(echo $checkn | rev | cut -b 1-4 | rev)                              #when id is at 10 or above,

suffxc="${prodnc}.part${alignc}"
suffxn="${prodnn}.part${alignn}"

[[ ! -f ${prodnc}.gro ]] &&
[[ ! -f ${suffxc}.gro ]] &&
echo "ERROR [1]: ${prodnc}.gro AND ${suffxc}.gro DO NOT EXIST" && exit

# <=======================================================
# <==== V. GENERATE NEW TPR FOR EXTENSION RUN 
# <=======================================================

gmx convert-tpr -s ${prodnc}.tpr -extend $gotime -o ${prodnn}.tpr            #extends by $gotime ps, MULTIPLE script uses "-until"
#checkdisk

[[ ! -f "${prodnn}.tpr" ]] &&
echo "ERROR [2]: ${prodnn}.tpr DOES NOT EXIST" && exit

# <=======================================================
# <==== VI. SIMULATE EXTENSION RUN
# <=======================================================

gmx mdrun -s ${prodnn}.tpr -cpi ${prodnc}.cpt -noappend -deffnm ${prodnn} -v -nt ${srvcnt}
#checkdisk

[[ ! -f "${suffxn}.gro" ]] &&
echo "ERROR [3]: ${suffxn}.gro DOES NOT EXIST" && exit

# <=======================================================
# <==== VII. CONCATENATE NEW TRAJECTORY TO INITIAL 
# <=======================================================

if [[ $idnum1 == 1 ]]; then
gmx trjcat -f ${prodnc}.trr ${suffxn}.trr -o ${prodnc}-${idnum2}.trr
#checkdisk
else
gmx trjcat -f step7_production_1-${idnum1}.trr ${suffxn}.trr -o step7_production_1-${idnum2}.trr
#checkdisk

#[[ -f "step7_production_1-${idnum2}.trr" ]] &&                            #active this only when small disk space left
#yes | rm step7_production_1-${idnum1}.trr && 
#yes | rm ${suffxn}.trr 
fi

[[ ! -f "system_production_1-2.trr" ]] &&
[[ ! -f "step7_production_1-${idnum2}.trr" ]] &&
echo "ERROR [4]: MISSING .trr FILE" && exit

# ========================================================
# ------------------      END      -----------------------
# ========================================================
