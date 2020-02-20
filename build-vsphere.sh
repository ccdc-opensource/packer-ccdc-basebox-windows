#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

pushd $DIR

if [[ "$( grep Microsoft /proc/version )" ]]; then
  PACKER="packer.exe"
else
  PACKER="packer"
fi

if [[ ! -e ./vsphere-environment-do-not-add ]]
then
  echo "Please add a vsphere-environment-do-not-add file to set up the environment variables required to deploy"
  echo "These vary based on the target VMWare server. The list can be found at the bottom of the packer template."
  return 1
fi
source ./vsphere-environment-do-not-add

echo 'creating output directory'
mkdir -p output

if [[ -f answer_files/Autounattend.xml ]]; then
  rm answer_files/Autounattend.xml
fi
cp answer_files/Autounattend.xml.template answer_files/Autounattend.xml

if [[ ! -x $WINDOWS_PRODUCT_KEY ]]; then
  echo "Inserting Windows product key in unattended install answer file..."
  sed -i "s/<\!--<Key><\/Key>-->/<Key>$WINDOWS_PRODUCT_KEY<\/Key>/" answer_files/Autounattend.xml
fi

echo 'building base images'
$PACKER build \
  -only=vmware-iso \
  -except=vagrant,vsphere,vsphere-template \
  -var 'customise_for_buildmachine=1' \
  -var 'build_directory=./output/' \
  -var 'disk_size=400000' \
  -var 'cpus=2' \
  -var 'memory=4096' \
  -var 'box_basename=ccdc-basebox/windows-2019' \
  -var 'virtualhw.version=13' \
  ./ccdc-basebox-windows-server-2019.json

