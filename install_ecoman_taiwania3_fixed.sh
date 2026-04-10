#!/bin/bash

set -e

echo "=========================================="
echo "ECOMAN2.0 安裝腳本 (TAIWAN-ICA3)"
echo "=========================================="

# 載入模組
module purge
module load old-module
module load compiler/intel/2020u4
module load OpenMPI/4.1.1
module load hdf5/1.12.2

# 設置環境（包含 libevent 符號鏈接）
export LD_LIBRARY_PATH=~/lib:$LD_LIBRARY_PATH
export LC_ALL=C
export LANG=C

echo ""
echo "環境檢查："
mpif90 --version | head -1
h5pfc --version | head -1
echo ""

cd ~/software/ECOMAN2.0-geodynamics/D-REX_M

# 編譯 D-REX_M
echo "=========================================="
echo "編譯 D-REX_M"
echo "=========================================="

h5pfc -O3 -qopenmp -o drex_m \
    precision.f90        \
    DistComm.f90         \
    DistGrid.F90         \
    module.f90           \
    D-REX_M.f90   \
    read_input_file.f90  \
    initgrid.f90         \
    loadsave.f90         \
    eulerian2D.f90  \
    eulerian3D.f90  \
    strainLPO.f90        \
    tensor_calc.f90      \
    ../DATABASES/elastic_database.f90 \
    ../shared_funct/readfunct.f90 \
    ../shared_funct/rotmat.f90 \
    ../shared_funct/inverse.f90 \
    ../shared_funct/dsyevc3.f \
    ../shared_funct/dsyevh3.f \
    ../shared_funct/dsyevq3.f \
    ../shared_funct/dsytrd3.f

mkdir -p objects
mv *.o objects/ 2>/dev/null || true
mv *.mod objects/ 2>/dev/null || true

if [ -f drex_m ]; then
    echo "✓ D-REX_M 編譯成功"
    ls -lh drex_m
else
    echo "✗ D-REX_M 編譯失敗"
    exit 1
fi

# 編譯 D-REX_S
echo ""
echo "=========================================="
echo "編譯 D-REX_S"
echo "=========================================="

cd ../D-REX_S

ifort -qopenmp -O2 \
    -I../D-REX_M/objects \
    -I/opt/ohpc/Taiwania3/libs/i2020-Ompi411/hdf5-1.12.2/include \
    -L/opt/ohpc/Taiwania3/libs/i2020-Ompi411/hdf5-1.12.2/lib \
    -o drexs \
    module.f90 \
    D-REX_S.f90 \
    read_input_file.f90 \
    ../D-REX_M/strainLPO.f90 \
    ../D-REX_M/tensor_calc.f90 \
    ../EXEV/spo.f90 \
    ../VIZTOMO/dec.f90 \
    ../DATABASES/elastic_database.f90 \
    ../shared_funct/readfunct.f90 \
    ../shared_funct/rotmat.f90 \
    ../shared_funct/inverse.f90 \
    ../shared_funct/dsyevc3.f \
    ../shared_funct/dsyevh3.f \
    ../shared_funct/dsyevq3.f \
    ../shared_funct/dsytrd3.f \
    -lhdf5hl_fortran -lhdf5_hl -lhdf5_fortran -lhdf5 -lz -ldl -lm

mkdir -p objects
mv *.o objects/ 2>/dev/null || true
mv *.mod objects/ 2>/dev/null || true

if [ -f drexs ]; then
    echo "✓ D-REX_S 編譯成功"
    ls -lh drexs
else
    echo "✗ D-REX_S 編譯失敗"
    exit 1
fi

echo ""
echo "=========================================="
echo "安裝完成！"
echo "=========================================="
echo ""
ls -lh ~/software/ECOMAN2.0-geodynamics/D-REX_M/drex_m
ls -lh ~/software/ECOMAN2.0-geodynamics/D-REX_S/drexs
