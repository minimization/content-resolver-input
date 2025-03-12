#! /bin/sh

if [ "$1" = "-n" ]; then
  dryrun=:
  shift
fi

for f; do
  [ -f $f ] || (echo "ERROR: $f: file not found"; exit 1)
  old_maint=$(yq -e '.data.maintainer' $f | awk '{print $1}')
  case $old_maint in
    # nonconformant renames
    ssg_virtualization)		new_maint=rhel-sst-virtualization ;;
    sst_cloud_experience)	new_maint=rhel-sst-cloudexperience ;;
    sst_insights)		new_maint=rhel-sst-idm-insights ;;
    sst_rhel_lightspeed)	new_maint=rhel-sst-lightspeed ;;
    sst_rhgs)			new_maint=rhel-sst-rh-ceph-storage ;;
    # individuals instead of SSTs
    bakery|bstinson)		new_maint=rhel-sst-program ;;
    jwboyer)			new_maint=rhel-sst-rh-ceph-storage ;;
    kkeithle)			new_maint=rhel-sst-rh-ceph-storage ;;
    plautrba)			new_maint=rhel-sst-security-selinux ;;
    sgallagh)			new_maint=rhel-sst-centos-stream ;;
    # typos or obsolete names
    sst_platform_storage)	new_maint=rhel-sst-logical-storage ;;
    sst_virtualization_spice)	new_maint=rhel-sst-virtualization ;;
    sst_window_management)	new_maint=rhel-sst-display-window-management ;;
    # regular patterns
    ssg_*|sst_*)	new_maint=rhel-${old_maint//_/-} ;;
    rhel-ssg-*|rhel-sst-*)	new_maint=${old_maint} ;;
    *) echo "ERROR: $f: unknown maintainer: $old_maint" ; exit 2 ;;
  esac

$dryrun env MAINT=${new_maint} yq -I 2 -i '.data.maintainer = strenv(MAINT)' $f

  d=${f%/*}
  b=${f##*/}
  [ $d != $f ] || d="."
  case $b in
    acg-level1-*)
        nf=$d/${new_maint}--$b
        ;;
    cee_support_unwanted.yaml)
        nf=$d/${new_maint}--unwanted.yaml
        ;;
    cee-support-workload.yaml)
        nf=$d/${new_maint}--all.yaml
        ;;
    eln_buildroot.yaml)
        nf=$d/${new_maint}--rpmautospec.yaml
        ;;
    mingw-pkg-config-exclusion.yaml)
        nf=$d/${new_maint}--mingw-pkg-config-unwanted.yaml
        ;;
    mingw-pkgs-exclusion.yaml)
        nf=$d/${new_maint}--mingw-unwanted.yaml
        ;;
    rhel-8-appstream-comps-performance.yaml)
        nf=$d/${new_maint}--performance.yaml
        ;;
    ssg_*-*|sst_*-*)
        pfx=${b%%-*}
        sfx=${b#*-}
        [ "$pfx" = "$old_maint" ] || (echo "WARNING: $f: maintainer mismatch: $old_maint")
        nf=$d/${new_maint}--$sfx
        ;;
    sst_*)
        pfx=${b%.yaml}
        [ "$pfx" = "$old_maint" ] || (echo "WARNING: $f: maintainer mismatch: $old_maint")
        nf=$d/${new_maint}--all.yaml
        ;;
    rhel-ssg-*--*|rhel-sst-*--*)
        pfx=${b%%--*}
        sfx=${b#*--}
        [ "$pfx" = "$old_maint" ] || (echo "WARNING: $f: maintainer mismatch: $old_maint")
        nf=$d/${new_maint}--$sfx
        ;;
    *) echo "ERROR: $f: unknown filename pattern: $f" ; exit 3 ;;
  esac

  if [ "$nf" != "$f" ]; then
    echo "$f ($old_maint) -> $nf ($new_maint)"
    $dryrun git mv $f $nf || (echo "ERROR: rename of $f to $nf failed"; exit 4)
  fi
done
