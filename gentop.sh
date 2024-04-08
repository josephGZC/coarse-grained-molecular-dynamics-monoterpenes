#!/bin/bash
# AUXILIARY SCRIPT
# DATE WRITTEN: JUNE 15, 2021
# DATE UPDATED: JUNE 15, 2021
# PURPOSE: create topology file for desired structure using GROMACS 

echo " "
echo " | AUXILIARY SCRIPT | GENERATES TOPOLOGY FILE USING GROMACS | "
echo " "

# <=======================================================
# <==== I. DECLARE VARIABLES
# <=======================================================

aatf="model1.pdb"

# <=======================================================
# <==== II. CREATE SEPARATE WORKING DIRECTORY
# <=======================================================

mkdir gmxtop &&
mv $aatf gmxtop &&
cd gmxtop 

# <=======================================================
# <==== III. GENERATE TOPOLOGY 
# <=======================================================

gmx pdb2gmx -f ${aatf} -o out1.gro -ignh <<EOF
4
1
EOF

mv out1.gro amb_out.gro &&
mv posre.itp amb_posre.itp &&
mv topol.top amb_topol.top &&

gmx pdb2gmx -f model1.pdb -o out1.gro -ignh <<EOF
8
1
EOF

mv out1.gro cha_out.gro &&
mv posre.itp cha_posre.itp &&
mv topol.top cha_topol.top &&

echo "...FILE/S GENERATED" &&
echo " " &&
[[ -f "amb_out.gro" ]] &&
 echo "   amb_out.gro" &&
[[ -f "amb_posre.itp" ]] &&
 echo "   amb_posre.itp" &&
[[ -f "amb_topol.top" ]] &&
 echo "   amb_topol.top" &&

echo " " &&
[[ -f "cha_out.gro" ]] &&
 echo "   cha_out.gro" &&
[[ -f "cha_posre.itp" ]] &&
 echo "   cha_posre.itp" &&
[[ -f "cha_topol.top" ]] &&
 echo "   cha_topol.top" &&

# <=======================================================
# <==== IV. RETURN TO ORIGINAL DIRECTORY 
# <=======================================================

mv * ../ 
cd ../
rm -r gmxtop

# ========================================================
# ------------------      END      -----------------------
# ========================================================

echo " "
echo "...DONE"
echo " "

duration=$SECONDS
echo " | TIME ELAPSED: $(($duration / 60)) MINUTE/S and $(($duration % 60)) SECOND/S |"
echo " "
