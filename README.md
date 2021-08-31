ACSO-IOMMU Kernel Patch making


This is entirely for making patchfiles for the acso-krnl-utils
or anyone who wants acso patch files

It works pretty wll for me but there is a big CAVEAT

it doesnt use patch tools to find the insertion points for the patches
in the realm of patchmaking this is a bit of a no-no

That being said - one is able to review the changes to the files prior to 
the aproper patch being created.

Think of it more as a helper

My Mileage was: 


These are test I ran :

I was able to generate a patch file for EVERY kernel source from linux-4.10.130 to linux-5.14-rc3 
Yes I ran the script over that many kernel sources. - sounds excessive but wasnt that difficult to script

I then selected a random group of 30 different kernel sources and ran a patch and compile script on 
them and they all compiled without issues

All the patches were hashed to find uniqueness - (see sortpatch.sh) and renamed to indicate
the range of kernels they apply to

What goes on in here is basically:

download kernel source - put it in (see the source) 
  tarballs_dir=~/dev/acso-iommu/patching/KernelSource  <--- change these to suit your environment
  patch_dir=~/dev/acso-iommu/patching/PatchFiles       <--- 


run the script and you'll end upt with a patchfile THAT YOU SHOULD REVIEW BEFORE APPLYING 

Next, extract your kernel source somewhere - apply your new patch and build your accso kernel

If you enjoy hacking bash scripts, one might hack this script into a acso kernel patcher and skip 
creating patch files altogether - I prefer being able to inspect the patch file and the 
source code before and after patching to make sure things look right prior to compiling

On one hand downloading and applying patches is cool if thats all you wanna do and you trust the 
patch and its source.

With this script there is only ONE source for the code that will be inserted into the 
kernel sources and it is included in this script - It is commented to make it easier to find 
the added code in the kernel source file. All steps are transparent and verifiable.

Please keep in mind that I wrote this to do some testing and help make patchfile -
This script has not been hardened and may be brittle in places. 
Experienced programmers/script guru's will know what I mean.

If anyon does start using it and any interest develops, I'll tidy the code some more 
and make it as robust as I can

Enjoy - hope you find this useful
