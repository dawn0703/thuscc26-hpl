# THUSCC26 HPL：从 baseline 学习优化

这是 [icl-utk-edu/hpl](https://github.com/icl-utk-edu/hpl) 的公开 fork，用于清华大学学生超算竞赛 HPL 题的个人学习、配置管理和实验复现。

**当前进度：已完成 baseline，尚未在本仓库开展优化实验。** 已有手动 baseline 为 **4072.2 GFlop/s、282.90 秒、PASSED**。新脚本已在本机验证语法、下载校验、实验副本准备和防覆盖保护，尚未在比赛集群编译或运行。仓库整理、GitHub 发布由助手完成；集群编译、提交和优化由学习者手动操作。

## 先弄清原题与源码

- [比赛原题与规则](https://lab.cs.tsinghua.edu.cn/scc/Benchmarks/HPL/)：CPU 集群、最多 2 节点 / 112 核，残差通过后比较 GFlops。
- [Netlib 官方主页](https://www.netlib.org/benchmark/hpl/)：明确链接到本 fork 的上游 GitHub 仓库。
- **比赛实际编译的是官方 `hpl-2.3.tar.gz`**。GitHub 上游当前提交与该发布包有少量差异，不能直接假定当前 `main` 就是比赛原始发布版。获取脚本会下载发布包并核对固定 SHA-256；不会编译仓库根目录的源码。
- HPL 源码不可修改；可调整编译器、编译选项、BLAS / MPI、`HPL.dat` 和运行配置。只用 `sbatch` 提交计算，登录节点用于编辑、编译和提交。

## 仓库导航

```text
README.md                       本说明：先读这里
src/ include/ testing/ ...       保留的上游源码：理解算法、通信、计时
README  COPYRIGHT  COPYING      上游原始说明与许可
thuscc26/
  configs/baseline/HPL.dat       N=120000、NB=384、P×Q=8×14
  build/Make.Linux_Intel.in      Intel MPI + MKL sequential 编译模板
  slurm/run.slurm                双节点112进程、每进程1线程的运行模板
  scripts/01-fetch-source.sh     下载、校验、解压比赛发布包
  scripts/02-build.sh            编译并核对原文件及动态库
  scripts/03-prepare-run.sh      准备独立实验目录，不提交作业
  docs/01-manual-workflow.md     做什么、为什么、命令、成功标准
  docs/02-optimization-map.md    优化对象和比较方法
  docs/03-code-map.md            读源码、配置、脚本时该看哪里
  docs/04-experiment-template.md 每次实验的记录模板
  results/BASELINE.md            已有结果与证据来源
.work/                          下载、构建、运行和原始日志；本地生成，Git忽略
```

**真正开始优化时，先改参数配置，保持源码不变。** 例如调整 `HPL.dat` 的 NB，研究分块大小对矩阵乘法效率和通信的影响；之后再研究进程网格、进程与线程、库和编译选项。没有“所有机器通用的最佳参数”。

## 怎样使用

先读 [手动流程](thuscc26/docs/01-manual-workflow.md)，再逐步操作。下面是阶段索引，**不是需要一次性粘贴执行的命令串**：

| 阶段 | 手动使用的工具 | 为什么 |
|---|---|---|
| 获取源码 | `bash thuscc26/scripts/01-fetch-source.sh` | 固定比赛允许的发布版，避免源码版本混淆 |
| 编译 | `bash thuscc26/scripts/02-build.sh` | 把原始 C 代码与 MPI / MKL 链接成 `xhpl` |
| 准备一次实验 | `bash thuscc26/scripts/03-prepare-run.sh baseline-01 thuscc26/configs/baseline/HPL.dat` | 每次独立保存程序、输入和脚本，保护已有结果 |
| 提交计算 | 在该实验目录中手动 `sbatch run.slurm` | 由 Slurm 申请计算节点并执行脚本 |
| 查结果 | `squeue`、`sacct`、`cat logs/hpl_作业号.out` | 分清排队、正常退出、正确性和性能 |

脚本没有自动提交、取消或监控作业的逻辑。`sbatch` 是计算提交；比赛计分提交是另一件事，已有成绩的计分回执尚未确认。

## 公开与本地文件

公开保存：官方源码历史、可复用配置、脚本、学习说明、带来源的结果摘要。原始计分日志在本地完整保留，不编辑为“更好看的结果”；本仓库目前只公开摘要。

不放入仓库：SSH / VPN 配置、密钥、账号口令、队内聊天、内部 PDF、编译产物、下载缓存或队友文件。不要在这个仓库中存放上述内容。

## 上游与许可

上游基点：`9edeab5e1713116c4231e5d3aa6159b5b747ede8`（2026-11-07 核对）。现有上游文件保留；本次新增内容集中在 `thuscc26/` 及本 README、Git 管理说明。

This product includes software developed at the University of Tennessee, Knoxville, Innovative Computing Laboratory.

HPL 原有许可见 [COPYRIGHT](COPYRIGHT) / [COPYING](COPYING)，保留全部版权声明。
