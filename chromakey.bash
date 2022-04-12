#!/bin/bash

# Produce a ffmpeg command line to custom chromakey $FILE 

FILE=$1    # File to operate on
OUTP=$2    # Resulting file
DIFF=0x20  # Color difference: perform chromakeying if pixel is inside colorspace cube [(r-DIFF;g-DIFF;b-DIFF);(r+DIFF;g+DIFF;b+DIFF)]

# CHROMA should consist of one or more color replace sequences:
#   Source R:Source G:Source B:Target R:Target G:Target B:Target Alpha
# For example:
#   Step 1: 95fca3 -> #95fca3 + 100% transparency
#   Step 2: 046752 -> #046752 + 50% transparency (2-step to fix edges; convert near colors to exact color)
#   Step 3: 046752 -> black + 50% transparency

CHROMA="0x95:0xfc:0xa3:0x95:0xfc:0xa3:0 0x04:0x67:0x52:0x04:0x67:0x52:128 0x04:0x67:0x52:0:0:0:128"

echo -n "ffmpeg -i $FILE -vf format=argb,"

for chroma in $CHROMA
do
    SR=`echo $chroma | cut -d: -f1`
    SG=`echo $chroma | cut -d: -f2`
    SB=`echo $chroma | cut -d: -f3`
    SRA=`echo $(($SR - $DIFF))`
    SGA=`echo $(($SG - $DIFF))`
    SBA=`echo $(($SB - $DIFF))`
    SRB=`echo $(($SR + $DIFF))`
    SGB=`echo $(($SG + $DIFF))`
    SBB=`echo $(($SB + $DIFF))`
    TR=`echo $chroma | cut -d: -f4`
    TG=`echo $chroma | cut -d: -f5`
    TB=`echo $chroma | cut -d: -f6`
    TA=`echo $chroma | cut -d: -f7`
    for COORD in "X,Y" "X-1,Y-1" "X,Y-1" "X+1,Y-1" "X-1,Y" "X,Y" "X+1,Y" "X-1,Y+1" "X,Y+1" "X+1,Y+1"
    do
        echo -n "geq='"
        echo -n "r=if(between(r($COORD),$SRA,$SRB)*between(g($COORD),$SGA,$SGB)*between(b($COORD),$SBA,$SBB),$TR,r(X,Y)):"
        echo -n "g=if(between(r($COORD),$SRA,$SRB)*between(g($COORD),$SGA,$SGB)*between(b($COORD),$SBA,$SBB),$TG,g(X,Y)):"
        echo -n "b=if(between(r($COORD),$SRA,$SRB)*between(g($COORD),$SGA,$SGB)*between(b($COORD),$SBA,$SBB),$TB,b(X,Y)):"
        echo -n "a=if(between(r($COORD),$SRA,$SRB)*between(g($COORD),$SGA,$SGB)*between(b($COORD),$SBA,$SBB),min($TA,alpha(X,Y)),alpha(X,Y))"
        echo -n "',"
    done
done

# Anti-aliasing
echo -n "geq='r=r(X,Y):g=g(X,Y):b=b(X,Y):a=((alpha(X,Y)+alpha(X-1,Y-1)+alpha(X,Y-1)+alpha(X+1,Y-1)+alpha(X-1,Y)+alpha(X,Y)+alpha(X+1,Y)+alpha(X-1,Y+1)+alpha(X,Y+1)+alpha(X+1,Y+1))/10)',"

echo "null $OUTP"
