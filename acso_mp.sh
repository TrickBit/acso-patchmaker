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

#source "${lib_dir}/funcs"

die(){
	local __MSG__
	__MSG__="${versionstring} line $(caller 1)\nError : ${1}"
	echo "${__MSG__}"
	exit 1
}

function readkey(){
	echo hit a key to continue
	read -r



}
tarballs_dir=~/dev/acso-iommu/patching/KernelSource
patch_dir=~/dev/acso-iommu/patching/PatchFiles

[ ! -d "${patch_dir}" ] && mkdir -p "${patch_dir}"


patch_docfile(){
  srch_string="noioapicquirk	[APIC] Disable all boot interrupt quirks."
  DocSrc=Documentation/admin-guide/kernel-parameters.txt
  moddedDocSrc="${DocSrc}.${ModdedExt}"
  doc_replace="${lib_dir}/patch_source/doc.ptch"
  [ -f "${moddedDocSrc}" ] && rm -v "${moddedDocSrc}"
  echo > "${moddedDocSrc}"

  [ -f /tmp/top_file  ] && rm /tmp/top_file
  [ -f /tmp/bottom_file ] && rm /tmp/bottom_file
  start_srch=$(grep -F -n "${srch_string}" $DocSrc | cut -d ":" -f 1)
  [ -z "${start_srch}" ] && die "Could not find a valid insertion point for Docs patch \n"
  awk -v n=$start_srch 'NR < n { print >> "/tmp/top_file"; next } {print >> "/tmp/bottom_file" }' $DocSrc
  cat  /tmp/top_file "${doc_replace}" /tmp/bottom_file > "${moddedDocSrc}"
  echo "-----------------------------------------------------------------"
  echo -e ".......${moddedDocSrc} \n"
  cat "${moddedDocSrc}" | grep -B16 -A2 noioapicquirk
}


patch_quirkfile(){
  DocSrc=drivers/pci/quirks.c
  moddedDocSrc="${DocSrc}.${ModdedExt}"
  worksrc="${DocSrc}.${ModdedExt}.tmp"
  srch_string="static void quirk_no_bus_reset(struct pci_dev *dev)"
  doc_replace_1="${lib_dir}/patch_source/quirks1.ptch"
  doc_replace_2="${lib_dir}/patch_source/quirks2.ptch"
  line_no_1=$(grep -F -n "${srch_string}" $DocSrc | cut -d ":" -f 1)
  [ -z "${line_no_1}" ] && die "Could not find a valid insertion point for first part of quirks.c patch!\n"
  line_no_1=$(( line_no_1 + 4))
  echo "Found insertion point for first part of quirks.c patch=$line_no_1"
  echo "we will insert our text into the appropriate place"
  # patch the file
  [ -f /tmp/top_file  ] && rm /tmp/top_file
  [ -f /tmp/bottom_file ] && rm /tmp/bottom_file
  awk -v n=$line_no_1 'NR < n { print >> "/tmp/top_file"; next } {print >> "/tmp/bottom_file" }' $DocSrc
  cat  /tmp/top_file "${doc_replace_1}" /tmp/bottom_file > "${worksrc}"

  DocSrc="${worksrc}"

  # now we look for :
  # static const struct pci_dev_acs_enabled {
  # 	u16 vendor;
  # 	u16 device;
  # 	int (*acs_enabled)(struct pci_dev *dev, u16 acs_flags);
  # } pci_dev_acs_enabled[] = {
  # specifically the last line ^ then we look for the closing }; and rewind a line number and we have our insertion point

  # this is slow but a little more accurate than other ways - even more accurate that part one of the patch (above)
    srch_string="} pci_dev_acs_enabled[] = {"
    start_srch=$(grep -F -n "${srch_string}" "${worksrc}" | cut -d ":" -f 1)
    [ -z "${start_srch}" ] && die "Could not find a valid insertion point for second part of quirks.c patch!\n"
    echo "Found beggining of code block that will be patched with the second part of quirks.c patch=$start_srch"
    while IFS= read -r line || [ -n "$line" ]; do
      i=$(( i + 1 ))
      [ $i -eq  "${start_srch}"  ] && start=$i
      if [ -n "${start}" ] ; then
        #now eat up lines intil we find "}:"
        #echo "${line}"
        if [ "${line//[[:space:]]}" == "};" ] ; then
          line_no_2=$((i-1)) # the line before that will be a {0} and we want to insert out code immediateley before that
          break
        fi
      fi
    done < "${worksrc}"
    [ -z "${line_no_2}" ] && die "Could not find a valid insertion point for quirks part 2 patch \n"
    echo "Found insertion point for second part of quirks.c patch=$line_no_2"
    echo "we will insert the text into the code block"

    # patch the file
    [ -f /tmp/top_file  ] && rm /tmp/top_file
    [ -f /tmp/bottom_file ] && rm /tmp/bottom_file
    awk -v n=$line_no_2 'NR < n { print >> "/tmp/top_file"; next } {print >> "/tmp/bottom_file" }' "${worksrc}"
    cat  /tmp/top_file "${doc_replace_2}" /tmp/bottom_file > "${moddedDocSrc}"

    [ -f /tmp/top_file  ] && rm /tmp/top_file
    [ -f /tmp/bottom_file ] && rm /tmp/bottom_file  #
    [ -f "${worksrc}" ] && rm "${worksrc}"

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
    [ -f "${outfile}" ] &&  echo -e "created patch file : ${outfile})"
  else
    die "No patched files to work on"
  fi
}

#dirname "$(readlink -f $(which acso_mp.sh))"

  function fetchemall() {
    local IFS
    ACSO_KERNEL_ORG_URL="https://mirrors.edge.kernel.org/pub/linux/kernel"
    ACSO_CURRENT_TEMP_FILE="./info"
    local stable_releases_combined_html
  	echo "Retrieving info about the most current bleeding edge kernel versions..."
    [ -f  "process.log" ] && rm "process.log"
    ACSO_CURRENT_TEMP_FILE="${ACSO_CURRENT_TEMP_FILE}_versions"
    echo > downloaded
		stable_releases_combined_html=""
    IFS=^M
    for i in 4 5 ; do
      page=$(curl -s "${ACSO_KERNEL_ORG_URL}/v${i}.x/" | grep -E -o 'linux-([0-9]{1,}\.)+[0-9]{1,}\.tar\.xz' )
      while IFS= read -r tb
      do
          if [ -n "${tb}" ] ; then
            numbers=$(echo "${tb}" | cut -d "-" -f 2)
            IOFS=$IFS
            IFS="."
            read -r maj min sub <<< "${numbers}"
            IFS=$OIFS
          fi

          if [ -n "${maj}" ] && [ -n "${min}" ] ; then
            link="${ACSO_KERNEL_ORG_URL}/v${maj}.x/${tb}"
            of=${tarballs_dir}/${tb}
            # #Kernels below 4.10 are not supported
            if  [ "${maj}" -le 4 ] && [ "${min}" -lt 10 ] ; then
              echo "skipping $tb - out of range for patchable kernels"
              #I might have already downloaded these at some point before the code was right so do a bit of cleanup
              [ -f "${of}" ] && rm "${of}"
              continue
            fi

            if [ -f "${of}" ] ; then
               echo "skipping $tb - already have it"
               z=1
            else
              echo "grabbing $tb" | tee -a downloaded
              wget -O "${of}" "${link}" || rm "${of}"
              #process_tarball "${of}"  $cleanup 2>&1 | tee -a "process.log"
              z=1
            fi
          fi
      done <<< "${page}"
		done
  }


  process_tarball(){
    tarball=${1}
    [ "${2}" == "refresh" ] && refresh=1
    folder=$(basename -- "${tarball}" )
    folder=$(echo $folder | sed -e 's/\.tar.*//g')
    quirks_c=drivers/pci/quirks.c
    doc_params=Documentation/admin-guide/kernel-parameters.txt
    if [ -n "${refresh}" ]; then
      echo "Refresh: pruning ${folder}"
      rm -rf   "${folder}"
      echo "extracting  ${tarball} into ${folder}"
    fi
		# readkey
	  if [ -f ${tarball} ] ; then
      if [ ! -f  ${quirks_c} -o ! -f ${doc_params} -o ! -z "${refresh}" ] ; then
        tar -xvf "${tarball}"   "${folder}/${quirks_c}" "${folder}/${doc_params}"
      fi
			# readkey
      cd ${folder}
      echo "In ${folder}"
      [ -f  "${quirks_c}" ] && echo "got ${quirks_c}" || echo "${quirks_c} not found!"
      [ -f  "${doc_params}" ] && echo "got ${doc_params}" || echo "${doc_params} not found!"
      if [ -f  ${quirks_c} -a -f ${doc_params} ] ; then
        cp -v "${quirks_c}" "${quirks_c}.${ModdedExt}"
        cp -v "${doc_params}" "${doc_params}.${ModdedExt}"

        patch_docfile
        patch_quirkfile
        make_patchfile "${folder}"

        # to actually test the patches uncomment the following
        # for patchfile in ../*acso*.patch;
        # do
        #   echo  "Try to apply acs override patch for ${folder}+ "
        #     echo "Checking ${patchfile} patch validity.."
        #     if git apply --check "${patchfile}"fetchinfo
        #     then
        #       echo -n "Applying patch file ..."
        #       git apply "${patchfile}"
        #       echo -e "Done!!! - Successfully applied ${patchfile} to ${folder}" | tee -a ../log.log
        #       break
        #     else
        #       echo " ..failed"
        #       #return "${FALSE}"
        #     fi
        # done

        # You will probably want to leave this but if you want to build
        # lots and lots of patch files - this works well unattended - so comment out
        # the next 2 lines
        # get_yesno "Please review and indicate - Are you happy with the results [y/N]?"
        # [ "${response}" == 'n' ] && die "Please check the code before continuing - perhaps submit a bug report"

      else
        echo -e "${quirks_c}\n${doc_params} "
        ls -al ${quirks_c}
        die "what happened?"
      fi
      cd -
    else
      echo  "No source tarball for ${tarball}"
    fi
  }

function run(){
  #load_config "${config_file}"

  if [[ "${config_vars}" == *"tarballs_dir"* ]]; then
      [ ! -d "${tarballs_dir}" ] && die "I cant find patchfies : ${tarballs_dir}"
  else
      [ ! -d "${tarballs_dir}" ] && mkdir_or_die  "${tarballs_dir}"
  fi

# fetchinfo=$TRUE
# fetchemall
# return

cleanup=refresh
  shopt -s nullglob    # In case there aren't any files
#  for tarball in "${tarballs_dir}"/linux-*.tar.*
[ -f  "process.log" ] && rm "process.log"
  for tarball in "${tarballs_dir}"/linux-*.tar.*
  do
      echo "processing ${tarball}"

      [ -f "${tarball}" ] &&   process_tarball "${tarball}"  $cleanup 2>&1 | tee -a "process.log"

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
