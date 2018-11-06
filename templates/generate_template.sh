#!/bin/bash

module load Molgenis-Compute/v17.08.1-Java-1.8.0_74
module load GAP/v2.1.0-beta
module list

host=$(hostname -s)
environmentParameters="parameters_${host}"

function showHelp() {
	#
	# Display commandline help on STDOUT.
	#
	cat <<EOH
===============================================================================================================
Script to copy (sync) data from a succesfully finished analysis project from tmp to prm storage.
Usage:
	$(basename $0) OPTIONS
Options:
	-h   Show this help.
	-a   sampleType (default=GAP)
	-l   pipeline (default=diagnostics)
	-p   project
	-g   group (default=basename of ../../../ )
	-f   filePrefix (default=basename of this directory)
	-r   RUNID (default=run01)
	-t   tmpDirectory (default=basename of ../../ )
	-x   excludeGTCFiles
	-w   workdir (default=/groups/\${group}/\${tmpDirectory})

===============================================================================================================
EOH
	trap - EXIT
	exit 0
}

while getopts "t:g:w:f:r:l:h:p:" opt;
do
	case $opt in h)showHelp;; t)tmpDirectory="${OPTARG}";; g)group="${OPTARG}";; w)workDir="${OPTARG}";; f)filePrefix="${OPTARG}";; p)project="${OPTARG}";; r)RUNID="${OPTARG}";;l)pipeline="${OPTARG}";;x)excludeGTCsFile="${OPTARG}";;
	esac
done

if [[ -z "${tmpDirectory:-}" ]]; then tmpDirectory=$(basename $(cd ../../ && pwd )) ; fi ; echo "tmpDirectory=${tmpDirectory}"
if [[ -z "${group:-}" ]]; then group=$(basename $(cd ../../../ && pwd )) ; fi ; echo "group=${group}"
if [[ -z "${workDir:-}" ]]; then workDir="/groups/${group}/${tmpDirectory}" ; fi ; echo "workDir=${workDir}"
if [[ -z "${filePrefix:-}" ]]; then filePrefix=$(basename $(pwd )) ; fi ; echo "filePrefix=${filePrefix}"
if [[ -z "${RUNID:-}" ]]; then RUNID="run01" ; fi ; echo "RUNID=${RUNID}"
if [[ -z "${pipeline:-}" ]]; then pipeline="diagnostics" ; fi ; echo "pipeline=${pipeline}"
genScripts="${workDir}/generatedscripts/${filePrefix}/"
samplesheet="${genScripts}/${filePrefix}.csv" ; mac2unix "${samplesheet}"

host=$(hostname -s)
echo "${host}"

projectDir="${workDir}/projects/${filePrefix}/${RUNID}/jobs/"

mkdir -p -m 2770 "${workDir}/projects/"
mkdir -p -m 2770 "${workDir}/projects/${filePrefix}/"
mkdir -p -m 2770 "${workDir}/projects/${filePrefix}/${RUNID}/"
mkdir -p -m 2770 "${workDir}/projects/${filePrefix}/${RUNID}/jobs/"

samplesheet="${genScripts}/${filePrefix}.csv" ; mac2unix "${samplesheet}"

perl "${EBROOTGAP}/scripts/convertParametersGitToMolgenis.pl" "${EBROOTGAP}/parameters_${host}.csv" > "${genScripts}/parameters_host_converted.csv"
perl "${EBROOTGAP}/scripts/convertParametersGitToMolgenis.pl" "${EBROOTGAP}/${pipeline}_parameters.csv" > "${genScripts}/parameters_converted.csv"

sh "${EBROOTMOLGENISMINCOMPUTE}/molgenis_compute.sh" \
-p "${genScripts}/parameters_converted.csv" \
-p "${genScripts}/parameters_host_converted.csv" \
-p "${samplesheet}" \
-rundir "${genScripts}/scripts" \
--runid "${RUNID}" \
-w "${EBROOTGAP}/Prepare_${pipeline}_workflow.csv" \
-o "RUNID=${RUNID};pipeline=${pipeline}" \
-weave \
--generate
