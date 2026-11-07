#!/bin/bash
#SBATCH --job-name=hpl_nb
#SBATCH --partition=cnall
#SBATCH --nodes=2
#SBATCH --ntasks=112
#SBATCH --ntasks-per-node=56
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --output=logs/hpl_%j.out
#SBATCH --error=logs/hpl_%j.err
set -e -o pipefail
: "${SLURM_JOB_ID:?Use sbatch from a prepared trial directory}"
: "${SLURM_SUBMIT_DIR:?Missing submit directory}"
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
# Runtime snapshot; preserve original build configuration separately.
module list > environment.txt 2>&1
{
    printf 'Recorded: %s\nNodes: %s\nRanks: %s\nOMP_NUM_THREADS=%s\nMKL_NUM_THREADS=%s\nI_MPI_HYDRA_BOOTSTRAP=%s\nI_MPI_OFI_PROVIDER=unset\n' \
        "$(date -Is)" "$SLURM_JOB_NODELIST" "$SLURM_NTASKS" "$OMP_NUM_THREADS" "$MKL_NUM_THREADS" "$I_MPI_HYDRA_BOOTSTRAP"
    mpirun --version
    ldd ./xhpl
    sha256sum ./xhpl HPL.dat run.sh
} >> environment.txt 2>&1
mpirun -np "$SLURM_NTASKS" ./xhpl
