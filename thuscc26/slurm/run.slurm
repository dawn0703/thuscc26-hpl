#!/bin/bash
#SBATCH --job-name=hpl_baseline
#SBATCH --partition=cnall
#SBATCH --nodes=2
#SBATCH --ntasks=112
#SBATCH --ntasks-per-node=56
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH --output=logs/hpl_%j.out
#SBATCH --error=logs/hpl_%j.err
set -e -o pipefail
# sbatch must be called from the prepared case directory, where logs/ exists.
: "${SLURM_JOB_ID:?Use sbatch on the cluster, not bash on the login node}"
: "${SLURM_SUBMIT_DIR:?Missing Slurm submit directory}"
cd "$SLURM_SUBMIT_DIR"

printf 'Start Time: %s\n' "$(date -Is)"
printf 'Job ID: %s; nodes: %s; ranks: %s\n' "$SLURM_JOB_ID" "$SLURM_JOB_NODELIST" "$SLURM_NTASKS"
trap 'status=$?; printf "End Time: %s; exit code: %s\n" "$(date -Is)" "$status"; exit "$status"' EXIT
test "$SLURM_NTASKS" -eq 112
test -x ./xhpl
test -f HPL.dat
module load compilers/intel/oneapi-2023/config
export I_MPI_HYDRA_BOOTSTRAP=slurm
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
unset I_MPI_OFI_PROVIDER
mpirun -np "$SLURM_NTASKS" ./xhpl
