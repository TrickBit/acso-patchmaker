#!/bin/bash


lib_dir=$(dirname $(readlink -f ${0}))
out=test.txt
echo >"${out}"
all=""
for patch in *.patch ;
do
  kernver="${patch//acso_linux-/}"
  kernver="${kernver//source-/}"
  kernver="${kernver//.patch/}"
  # kernver="${kernver//-rc[0-9]/}"

  # kernver="${kernver//_/./}"
#  oifs=$IFS
#  IFS="_"
#  read -r maj min rev <<< "${kernver}"
  # printf -v sortcol "%8.5f"  "${maj}.${min}${rev}"
  # printf -v sortcol "%0.8f"  ".${maj}${min}${rev}"
  # IFS=$oifs

  md5info=$(md5sum "${patch}")
  #echo "${md5info}"
  all="${md5info} ${kernver}\n${all}"
done
# echo -e ${all}
echo -e "${all}" | sort -V -k 3  >"${out}"
echo "OK"
currhash=""
currfile=""
firstver=""

tmpd="${lib_dir}/patchfiles"
mapfile="${tmpd}/kernel_map"
rm -rf "${tmpd}"
mkdir -pv "${tmpd}"
while read hash file lastver ; do
  [ -z "${currhash}" ] && currhash=$hash
  [ -z "${currfile}" ] && currfile=$file
  if [ "${currhash}" != "${hash}" ]; then #we finish our old hash and start a new hash
    newfile="${tmpd}/${currfile//.patch}-${oldver}.patch"
    cp "${currfile}"  "${newfile}"
    currhash=$hash
    currfile=$file
    currver=${lastver}
    #echo "Created file ${newfile}"
    #echo "NEW hash ${hash} ${file}"
    echo ------
  else
    #echo "same hash ${hash} ${file}"
    #echo  "${currver} ${oldver} $lastver  ${newfile}  "
    i=0
  fi
  echo  "c=${currver} o=${oldver} l=${lastver}  ${newfile}  "
  oldver=$lastver
done < <(cat "${out}" )
# cd "${tmpd}"
# ls -al
