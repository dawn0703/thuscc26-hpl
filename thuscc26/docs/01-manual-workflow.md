# 手动使用：每一步做什么，为什么

这份说明面向比赛 Linux 集群。Windows 终端负责 SSH；登录后再执行下列 Bash 命令。仓库里的脚本是可阅读的命令集合，不会自动替你申请计算资源。已有 baseline 无须为了整理仓库立即重跑。

## 1. 在独立目录获取仓库

**做什么：** 在自己的 WORK 下放置仓库。**原理：** Git 保存源码、配置和修改历史；独立目录保护原 baseline，也避免影响队友文件。

```bash
cd ~/WORK
git clone https://github.com/dawn0703/thuscc26-hpl.git
cd thuscc26-hpl
pwd
git status --short
```

**成功标准：** 当前目录是新仓库，工作区无意外修改。如果目录已存在，先检查内容，不覆盖、不重新初始化。整个流程不需要仓库包含 SSH 配置。

## 2. 固定官方 HPL 2.3 发布包

**做什么：** 先读脚本，再下载并校验。**原理：** 同名 GitHub 分支会更新；固定发布包与校验和才能解释“这次到底编译了什么”。

```bash
cat thuscc26/scripts/01-fetch-source.sh
bash thuscc26/scripts/01-fetch-source.sh
```

**成功标准：** SHA-256 校验显示 OK，源码位于 `.work/src/hpl-2.3/`，原文件清单为 `.work/original-files.sha256`。校验失败就停下排查，不能改掉预期哈希来放行。`.work/` 被 Git 忽略。

## 3. 编译：源代码 → xhpl

**做什么：** 用既定 Intel MPI / MKL 环境编译发布包。**原理：** `mpiicc` 编译并链接 MPI；MKL 提供高效矩阵运算；编译选项决定如何利用处理器指令。`module load` 选择软件环境，不申请计算节点。

```bash
cat thuscc26/build/Make.Linux_Intel.in
cat thuscc26/scripts/02-build.sh
bash thuscc26/scripts/02-build.sh
```

**成功标准：** `.work/src/hpl-2.3/bin/Linux_Intel/xhpl` 可执行，原文件校验通过，`.work/linked-libraries.txt` 无 `not found`。脚本不执行 `xhpl`。

脚本使用串行 `make -j1`，规避 HPL 构建阶段之间的依赖竞争。已有构建时拒绝重复构建；将来改编译选项或库，需要单独构建树，避免把旧目标文件当新结果。

当前链接 **MKL sequential**，用于112个MPI进程、每进程1线程的基线。只把 `MKL_NUM_THREADS` 改大，不会把串行 MKL 变成多线程 MKL。混合并行需要配套更换数学库链接、MPI进程数和Slurm核数申请。

## 4. 为一次实验准备独立副本

**做什么：** 保存本次的二进制、`HPL.dat` 和运行脚本。**原理：** `sbatch` 接收脚本，但不会替你冻结目录里的全部输入；排队后改输入会破坏实验可复现性。

在仓库根目录执行：

```bash
bash thuscc26/scripts/03-prepare-run.sh baseline-01 thuscc26/configs/baseline/HPL.dat
cd .work/runs/baseline-01
pwd
cat HPL.dat
cat run.slurm
bash -n run.slurm
```

**成功标准：** 目录内有 `xhpl`、`HPL.dat`、`run.slurm`、`provenance.txt`、`logs/`；语法检查无报错。已存在的实验名会报错，防止覆盖。

若只研究 NB、使用已有 baseline 的同一二进制，可以在仓库根目录把它作为第三个参数传入：

```bash
bash thuscc26/scripts/03-prepare-run.sh baseline-same-binary thuscc26/configs/baseline/HPL.dat /absolute/path/to/existing/xhpl
```

`/absolute/path/to/existing/xhpl` 是占位路径，先替换为你确认的文件。这样可跳过下载和编译，保持编译因素不变；但必须自己记录该二进制的实际构建来源，不能仅凭文件名确认库和选项。准备脚本不修改来源文件。

## 5. 手动提交一次，随后只查状态

**做什么：** 在刚准备好的实验目录提交。**原理：** `#SBATCH` 是 Slurm 的资源声明；Slurm 分配节点后，Bash 执行普通命令，`mpirun` 启动112个 `xhpl` 协作求解。模板使用 `SLURM_SUBMIT_DIR` 定位实验，避免残留旧目录的硬编码。

```bash
sbatch run.slurm
```

**成功标准：** 得到一个新作业号，记入实验记录。只执行一次；不应因为仍在排队再次提交。

```bash
squeue -u "$USER"
```

`PD` 是排队，`R` 是运行。`AssocGrpCpuLimit` 表示共享账号的CPU额度暂时不够；独立文件夹不会隔离配额。与队友协调，保留队友作业；不通过减配额等临时改动混淆基线。

不能用 `bash run.slurm` 替代 `sbatch`；它不会申请计算节点，本模板也会在缺少Slurm变量时停止。提交后不要改该目录的程序和输入。SSH断开通常不影响批作业。

## 6. 先核对正确性，再读性能

将 `JOBID` 替换为实际作业号：

```bash
sacct -S YYYY-MM-DD -X -j JOBID --format=JobID,State,ExitCode,Elapsed,AllocCPUS
cat logs/hpl_JOBID.out
cat logs/hpl_JOBID.err
```

日期使用本次提交日，避免跨日找不到历史。结束后同时检查：

- `COMPLETED` 与 `0:0`：作业正常退出。
- 参数表与预期一致，112进程对应 `P×Q=112`。
- `PASSED`、1通过、0失败、0跳过：数值检查通过。
- 起止时间、完整输出保留；错误日志检查完毕。
- 结果表 `Gflops` 是目标性能，越大越好；`Time` 是求解时间，不是排队或作业总时长。

计分仍须另按[官方提交指南](https://lab.cs.tsinghua.edu.cn/scc/submit/)办理。本流程不会下载或调用计分脚本。原始输出不可裁剪、拼接或修改来提交。

## 7. 保存修改与实验记录

**做什么：** 在 `thuscc26/configs/` 保存明确命名的参数，在记录中写明对应结果。**原理：** Git 能回答“改了什么”，完整日志回答“运行了什么”，两者合起来才能解释性能变化。

```bash
git diff
git status --short
```

公开记录用[实验模板](04-experiment-template.md)，原始运行证据完整保留在本地 `.work/`。检查本次要公开的文件后，再手动选择文件 `git add`、`git commit`、`git push`，不要把队伍内部资料混入仓库。
