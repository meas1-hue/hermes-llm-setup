# hermes-llm-setup

Disaster recovery snapshot for the local Hermes LLM inference stack.

**Model:** Qwen3.6-35B-A3B-UD-Q5_K_XL  
**Engine:** ikawrakow/ik_llama.cpp @ `3f40e73`  
**Hardware:** Core Ultra 7 155H + RTX 3060 12GB eGPU  
**Performance:** ~35 t/s decode (vs ~27 t/s on TheTom/turboquant — +30%)

---

## Contents

| File | Purpose |
|---|---|
| `llama-server` | Pre-compiled binary (Linux x86_64, CUDA 13.2, SM86) |
| `llama-server.service` | systemd user service file |
| `build.sh` | Rebuild binary from source (if binary incompatible) |

---

## Recovery Steps

### 1. Prerequisites

```bash
# Fedora
sudo dnf install cmake gcc g++ ninja-build python3

# CUDA toolkit at /usr/local/cuda (nvcc must exist)
ls /usr/local/cuda/bin/nvcc

# Model file
~/models/qwen35b/Qwen3.6-35B-A3B-UD-Q5_K_XL.gguf
```

### 2a. Use pre-built binary (fastest)

```bash
cp llama-server ~/ik_llama_cpp/build/bin/llama-server
chmod +x ~/ik_llama_cpp/build/bin/llama-server
```

Binary requires: Linux x86_64, AVX2+AVX-VNNI CPU, CUDA 13.x, SM86 GPU.  
If it crashes at load, rebuild from source instead.

### 2b. Rebuild from source

```bash
chmod +x build.sh && ./build.sh
```

Takes ~15–20 min. Output: `~/ik_llama_cpp/build/bin/llama-server`

### 3. Install service

```bash
cp llama-server.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now llama-server
```

### 4. Verify

```bash
systemctl --user status llama-server
curl http://localhost:8081/health
nvidia-smi   # should show llama-server using ~11.4 GB VRAM
```

---

## Key Config Notes

- `--n-cpu-moe 27`: 27 of 40 layers run MoE on CPU. Minimum — `n=26` causes OOM on RTX 3060 12GB.
- `--cache-type-k q8_0 --cache-type-v iq4_nl`: KV cache is tiny (~0.9 GB at 131k ctx) due to model's aggressive GQA (n_kv_heads=2).
- `CPUAffinity=0,1,3,6,8,10`: one logical CPU per P-core on 155H, avoids HT contention.
- `MemoryHigh=18G`: cgroup soft limit creates RAM cold tier; evicted pages go to NVMe (not swap).
- **Why ik is fast:** IQK kernels use `vpdpbusd` (AVX-VNNI) for Q5_K matmul on the 27 CPU MoE layers. Same weights as before, faster math.

---

## Model Source

`Qwen3.6-35B-A3B-UD-Q5_K_XL.gguf` — unsloth/Qwen3-30B-A3B-GGUF (non-MTP variant)  
MTP variant path: `~/models/qwen35b-mtp/Qwen3.6-35B-A3B-UD-Q5_K_XL-MTP.gguf` (not in production)
