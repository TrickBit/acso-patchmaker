ACSO-IOMMU Kernel Patch making


This is entirely for makinh patchfiles for the acso-krnl-utils
or anyone whou wants acso patch files

It works pretty wll for me but there is a big CAVEAT

it doesnt use patch tools to find the insertion points for the patches
in the realm of patchmaking this is a bit no-no

That being said - one is able to review the changes to the files prior to 
the aproper patch being created.

Think of it more as a helper

My Mileage was that I was able to generate 30 odd functioning patch files 
for diferent kernel versions in about 10 minutes
and thats just time taken extracting the two files affected by the patch
making a copy - inserting the patch code automagically
reviewing the changes and crating the patch
all of this except the review process is automated

The only thing you need is a folder full of kernels source tarbals

PS You WILL need https://github.com/TrickBit/acso-krnl-utils/blob/main/funcs 
in the same folder as the script - all the scripts I developed for this share 
some basic functions.

Enjoy - hope you find it useful
