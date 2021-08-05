#!/bin/bash
# set -x
appname=acso_makepatch
appvers=1.1rc1
versionstring="${appname} ${appvers} (${0})"
ModdedExt="patched"
current_dir=$(pwd)
versions=()
lib_dir=$(dirname $(readlink -f ${0}))
config_file="${current_dir}/.acso_makepatch"

source "${lib_dir}/funcs"



patch_docfile(){
  srch_string="noioapicquirk	[APIC] Disable all boot interrupt quirks."
  DocSrc=Documentation/admin-guide/kernel-parameters.txt
  moddedDocSrc="${DocSrc}.${ModdedExt}"
  doc_replace="${lib_dir}/patch_source/doc.ptch"
  [ -f "${moddedDocSrc}" ] && rm -v "${moddedDocSrc}"
  echo > "${moddedDocSrc}"
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" == *"$srch_string"* ]] ; then
      cat $doc_replace >> "${moddedDocSrc}"
    fi
    printf '%s\n' "$line" >> "${moddedDocSrc}"
  done < $DocSrc
  echo "-----------------------------------------------------------------"
  echo -e ".......${moddedDocSrc} \n"
  cat "${moddedDocSrc}" | grep -B16 -A2 noioapicquirk
}

patch_quirkfile(){
  DocSrc=drivers/pci/quirks.c
  srch_string="static void quirk_no_bus_reset(struct pci_dev *dev)"
  doc_replace_1="${lib_dir}/patch_source/quirks1.ptch"
  line_no_1=$(grep -F -n "${srch_string}" $DocSrc | cut -d ":" -f 1)
  [ -z "${line_no_1}" ] && die "Could not find a valid insertion point for quirks part 1 patch \n${line_no}"
  line_no_1=$(( line_no_1 + 4))
  doc_replace_2="${lib_dir}/patch_source/quirks2.ptch"
  srch_string[1]="PCI_VENDOR_ID_ZHAOXIN, PCI_ANY_ID, pci_quirk_zhaoxin_pcie_ports_acs"
  srch_string[2]="PCI_VENDOR_ID_AMPERE, 0xE00C, pci_quirk_xgene_acs "
  for i in 1 2
  do
    srch=${srch_string[$i]}
    line_no_2=$(grep -F -n "${srch}" $DocSrc | cut -d ":" -f 1)
    [ ! -z "${line_no_2}" ] && break
  done
  [ -z "${line_no_2}" ] && die "Could not find a valid insertion point for quirks part 2 patch \n${line_no}"
  line_no_2=$(( line_no_2 + 1))
  moddedDocSrc="${DocSrc}.${ModdedExt}"
  [ -f "${moddedDocSrc}" ] && rm  "${moddedDocSrc}"

  i=0
  while IFS= read -r line || [ -n "$line" ]; do
    i=$(( i + 1 ))
    if [ $i -eq  ${line_no_1} -a  -z "${line}" ]
    then
        cat "${doc_replace_1}" >> "${moddedDocSrc}"
    fi
    if [ $i -eq  ${line_no_2}  ]
    then
        cat "${doc_replace_2}" >> "${moddedDocSrc}"
    fi
    printf '%s\n' "$line"  >> "${moddedDocSrc}"
  done < $DocSrc


    echo "-----------------------------------------------------------------"
    echo -e ".......${moddedDocSrc}\n"
    cat "${moddedDocSrc}" | grep -B6 -A5  "Begin: IOMMU - acso Patch"
    echo -e "\t.\n\t.\n\t.\n"
    cat "${moddedDocSrc}" | grep -B8 -A9 "End: IOMMU - acso Patch"
    echo -e "\t.\n\t.\n\t.\n"
    cat "${moddedDocSrc}" | grep -B5 -A5 "\* IOMMU - acso Patch"
    echo "-----------------------------------------------------------------"

}

make_patchfile(){
  kernelver=$(echo ${1} | sed -e 's/\./_/g')
  patch_dir="${lib_dir}/patchfiles"
  outfile="${patch_dir}/acso_${kernelver}.patch"
  DocSrc=Documentation/admin-guide/kernel-parameters.txt
  QrkSrc=drivers/pci/quirks.c
  moddedDocSrc="${DocSrc}.${ModdedExt}"
  moddedQrkSrc="${QrkSrc}.${ModdedExt}"

  echo  "mds=${moddedDocSrc} mqs=${moddedQrkSrc} "
  if [ -f ${moddedDocSrc} -a -f ${moddedQrkSrc} ]
  then
    git diff "${DocSrc}" "${moddedDocSrc}"  | sed -e "s/\.${ModdedExt}//g" > "${outfile}"
    git diff "${QrkSrc}" "${moddedQrkSrc}"  | sed -e "s/\.${ModdedExt}//g" >> "${outfile}"
    echo -e "created patch file : $(ls -l ${outfile})"
  else
    die "No patched files to work on"
  fi
}


process_tarballs(){
  tarball=${1}
  [ "${2}" == "refresh" ] && refresh=1
  folder=$(basename -- "${tarball}" )
  folder=$(echo $folder | sed -e 's/\.tar.*//g')
  quirks_c=drivers/pci/quirks.c
  doc_params=Documentation/admin-guide/kernel-parameters.txt
  if [ ! -z $refresh ]; then
    echo "Refresh: pruning ${folder}"
    rm -rf   "${folder}"
    echo "extracting  ${tarball} into ${folder}"
  fi

  if [ -f ${tarball} ] ; then
    if [ ! -f  ${quirks_c} -o ! -f ${doc_params} -o ! -z "${refresh}" ] ; then
      tar -xvf ${tarball}   "${folder}/${quirks_c}" "${folder}/${doc_params}"
    fi
    cd ${folder}
    echo "In ${folder}"
    [ -f  "${quirks_c}" ] && echo "got ${quirks_c}" || echo "${quirks_c} not found!"
    [ -f  "${doc_params}" ] && echo "got ${doc_params}" || echo "${doc_params} not found!"
    if [ -f  ${quirks_c} -a -f ${doc_params} ] ; then
      cp -v "${quirks_c}" "${quirks_c}.${ModdedExt}"
      cp -v "${doc_params}" "${doc_params}.${ModdedExt}"
      patch_docfile
      patch_quirkfile

      # this works well unattended - I had this in so I could review the changes prior to
      # creating a patchfile

      # get_yesno "Please review and indicate - Are you happy with the results [y/N]?"
      # [ "${response}" == 'n' ] && die "Please check the code before continuing - perhaps submit a bug report"
      make_patchfile "${folder}"
    else
      echo -e "${quirks_c}\n${doc_params} "
      die "wtf?"
    fi
    cd -
  else
    echo  "No source tarball for ${tarball}"
  fi
}

# keep forgetting this stuff ...
#strip trailing whitespace ${ff%%*( )}
#strip leading whitespace ${ff##*( )}

function run(){
  load_config "${config_file}"
  if [[ "${config_vars}" == *"tarballs_dir"* ]]; then
      [ ! -d "${tarballs_dir}" ] && die "I cant find patchfies : ${tarballs_dir}"
  else
      [ ! -d "${tarballs_dir}" ] && mkdir_or_die  "${tarballs_dir}"
  fi

  shopt -s nullglob    # In case there aren't any files
  for filepath in "${tarballs_dir}"/linux-*.tar.*
  do
      echo "processing ${filepath}"
      [ -f "${filepath}" ] &&   process_tarballs "${filepath}"  $cleanup
  done
  shopt -u nullglob    # Optional, restore default behavior for unmatched file globs
}


cleanup= # "refresh"

# manual testing
# cd  linux-5.8
# patch_docfile
# patch_quirkfile
# make_patchfile "linux-5.8.tar.gz"
run
#patch_docfile
