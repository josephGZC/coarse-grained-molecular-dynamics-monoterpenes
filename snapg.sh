#!/bin/bash
# AUXILIARY SCRIPT
# DATE WRITTEN: JULY 15, 2021
# DATE UPDATED: AUGUST 30, 2021
# PURPOSE: generate all-atom structure from coarse-grained trajectory

echo " "
echo " | AUXILIARY SCRIPT | GENERATE ALL-ATOM STRUCTURE FROM COARSE-GRAINED TRAJECTORY | "
echo " "

# ========================================================
# ------------------    REMINDERS    ---------------------
# ========================================================

# 1. the following files are required to be in the same directory:
#    a. trajectory 
#        - name should be "comp.xtc"
#        - snapshots will be obtained here using trjconv
#        - .xtc recommended for easier handling
#    b. run topology file 
#        - name should be "step7_production_1.tpr"
#        - tpr describing xtc trajectory for trjconv
#        - to be used in initram.sh 
#    c. mapping file (basis for conversion of cgmd to aa) 
#        - to be used in initram.sh 
#    d. forcefield (for backmapping, basis of the minimization)
#        - to be used in initram.sh 
#
#    SPECIFIC FOR DABIOTECH PROJECT 2016
#    - comp.txc
#    - step7_production_1.tpr
#    - backward.py
#    - initram.sh
#    - cha_topol.top
#    - cha_posre.itp
#    - ffbonded.itp
#    - ffnonbonded.itp
#    - ffcharm36.itp
#    - Mapping (amino acids)
#
# 2. declare important variables in section I, for:
#    a. part of system to be outputted
#    b. name of log file
#    c. desired frames to be outputted
#
# 3. run file in csrc as nohup "./snapg.sh" > out.log &

# ========================================================                                                                                             
# -------------------    SECTIONS    ---------------------
# ========================================================

# I.   DECLARE VARIABLES
#
# II.   DETERMINE SYSTEM
#
# III.  EXTRACT SELECTED FRAMES
#
# IV.   SEPARATE FRAMES INTO RESPECTIVE GRO FILES
#
# V.    CENTER STRUCTURE IN BOX
#
# VI.   COMMENCE BACKMAPPING
#
# VII.  CONVERT AA GRO STRUCTURE TO PDB
#
# VIII. STORE ALL FILES AND OUTPUT IN SETUP DIR
#
# IX.   TAR SETUP

# <=======================================================
# <==== I. DECLARE VARIABLES
# <=======================================================

pic=1   				  #which part of system do you need? 1 for protein.
logfile=out.log

echo "...(1/4) WRITE FRAME INDEX"
echo " "

cat > frames.ndx <<EOF
[frames]
1251
3751
6251
8751
EOF

# <=======================================================
# <==== II. DETERMINE SYSTEM
# <=======================================================

getname=$(pwd)
sysname=$(echo $getname | rev | cut -d/ -f2 | rev)

# <=======================================================
# <==== III. EXTRACT SELECTED FRAMES
# <=======================================================

echo "...(2/4) GENERATE GRO FILE CONTAINING SELECTED FRAMES"
echo " "

echo ${pic} | gmx trjconv -f comp.xtc -s step7_production_1.tpr -o frames.gro -fr frames.ndx -pbc nojump &&

[[ ! -f frames.gro ]] &&
echo "ERROR [0]: frames.gro DOES NOT EXIST" && exit


# <=======================================================
# <==== IV. SEPARATE FRAMES INTO RESPECTIVE GRO FILES 
# <=======================================================

echo "...(3-${out}/4) CGMD SELECTED FRAME-${out}" 
echo " "
echo "   (A) SEPARATING FRAMES"

num=$(grep -r "t=" frames.gro | wc -l)           #number of frames
atm=$(sed -n 2p frames.gro | sed 's/^ *//g')     #number of atoms
rg1=$((atm+2))                                   #length of frame following title line, +2 to account for atom number line and dimension line                            
clc=1                                            #row number of first line of frame, accounts for title line
out=0                                            #counter for while loop

while [[ $out -ne $num ]] 
do
out=$((out+1))
rag=$((clc+rg1))                                	                     #row number of last line of frame                    
sed -n "${clc},${rag} p" frames.gro >> ${sysname}-cgmd-noc-frame-${out}.gro &&   #outputs one frame

[[ ! -f ${sysname}-cgmd-noc-frame-${out}.gro ]] &&
echo "ERROR [1]: ${sysname}-cgmd-noc-frame-${out}.gro DOES NOT EXIST" && exit

# <=======================================================
# <==== V. CENTER STRUCTURE IN BOX 
# <=======================================================

echo "   (B) CENTERING"

gmx editconf -f ${sysname}-cgmd-noc-frame-${out}.gro -c -o ${sysname}-cgmd-frame-${out}.gro && 

[[ ! -f ${sysname}-cgmd-frame-${out}.gro ]] &&
echo "ERROR [2]: ${sysname}-cgmd-frame-${out}.gro DOES NOT EXIST" && exit

# <=======================================================
# <==== VI. COMMENCE BACKMAPPING 
# <=======================================================

echo "   (C) BACKMAPPING"

./initram.sh -f ${sysname}-cgmd-frame-${out}.gro -o ${sysname}-aa-frame-${out}.gro -to charmm36 -p cha_topol.top 

cp ${logfile} inspect_multiplelog.out &&
grep -cim1 "LINCS" inspect_multiplelog.out &&
echo "ERROR [3]: LINCS WARNING OCCURRED" && exit
yes | rm inspect_multiplelog.out

[[ ! -f ${sysname}-aa-frame-${out}.gro ]] &&
echo "ERROR [4]: ${sysname}-aa-frame-${out}.gro DOES NOT EXIST" && exit


# <=======================================================
# <==== VI. CONVERT AA GRO STRUCTURE TO PDB
# <=======================================================

echo "   (D) CONVERTING TO PDB"
echo " "

gmx editconf -f ${sysname}-aa-frame-${out}.gro -o ${sysname}-aa-frame-${out}.pdb &&

[[ ! -f ${sysname}-aa-frame-${out}.pdb ]] &&
echo "ERROR [5]: ${sysname}-aa-frame-${out}.pdb DOES NOT EXIST" && exit

clc=$((clc+rg1+1))
done

# <=======================================================
# <==== VII. STORE ALL FILES AND OUTPUT IN SETUP DIR
# <=======================================================

mkdir ${sysname}-setup cgmd-gro aa-gro aa-pdb &&
cp {cha_posre.itp,cha_topol.top} ${sysname}-setup
cp ff* ${sysname}-setup
cp {initram.sh,backward.py} ${sysname}-setup
cp -r Mapping ${sysname}-setup

mv *cgmd-*.gro cgmd-gro &&
mv *aa-*.gro aa-gro &&
mv *aa-*.pdb aa-pdb &&
 
mv cgmd-gro ${sysname}-setup &&
mv aa-gro ${sysname}-setup &&
mv aa-pdb ${sysname}-setup &&

# <=======================================================
# <==== VIII. TAR SETUP
# <=======================================================

echo "...(4/4) TAR SET UP DIR"
echo " "

tar -zcvf ${sysname}-setup.tar.gz ${sysname}-setup/

# ========================================================
# ------------------      END      -----------------------
# ========================================================

echo " "
echo "...DONE"
echo " "

duration=$SECONDS
echo " | TIME ELAPSED: $(($duration / 60)) MINUTE/S and $(($duration % 60)) SECOND/S |"
echo " "                    
