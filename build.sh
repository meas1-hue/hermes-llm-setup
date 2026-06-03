#!/usr/bin/env bash
# Rebuild ik_llama.cpp llama-server from source.
# Tested on Fedora 44, Core Ultra 7 155H, RTX 3060 12GB (SM86), CUDA 13.2
# Commit: 3f40e73c367ad9f0c1b1819f28c7348c26aa340d

set -e

REPO_DIR="$HOME/ik_llama_cpp"
COMMIT="3f40e73c367ad9f0c1b1819f28c7348c26aa340d"

if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/ikawrakow/ik_llama.cpp "$REPO_DIR" --depth=1
    cd "$REPO_DIR"
    git fetch --depth=1 origin "$COMMIT"
    git checkout "$COMMIT"
else
    cd "$REPO_DIR"
fi

cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_CUDA=ON \
    -DCMAKE_CUDA_ARCHITECTURES=86 \
    -DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc \
    -DGGML_NATIVE=ON \
    -DGGML_AVX_VNNI=ON \
    -DGGML_IQK_MUL_MAT=ON \
    -DGGML_IQK_FLASH_ATTENTION=ON \
    -DGGML_IQK_FA_ALL_QUANTS=ON \
    -DGGML_CUDA_COMPRESSION_MODE=speed \
    -DGGML_LTO=OFF

cmake --build build --target llama-server -j"$(nproc)"

echo "Binary: $REPO_DIR/build/bin/llama-server"
