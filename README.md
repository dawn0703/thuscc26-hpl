# THUSCC26 HPL：配置与提交材料

源码直接用[Netlib官方HPL 2.3发布包](https://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz)。不再重复存放整套源码、手册或多份教程；原始源码不允许修改。旧版本可从Git历史找到。

只维护五个工作文件：

| 文件 | 用途 / 更新时机 |
|---|---|
| `HPL.dat` | 当前选定参数；候选通过并决定采用后更新 |
| `Make.Linux_Intel` | 基线编译选项参考；交付用产生实际xhpl的构建文件 |
| `run.sh` | Slurm运行脚本；改资源或运行环境时更新 |
| `report.md` | 报告草稿及实验表；每次试跑后更新，定稿导出PDF |
| `README.md` | 操作与提交清单；规则于2026-11-07核对 |

原始程序、每次输入和日志保存在Git忽略的`.local/`，不放入公开仓库。仓库仍为官方上游的fork；本次精简当前工作树，没有改写历史。

## 30分钟安排

复用已验证的xhpl，不重新编译。固定N120000、P8Q14、112进程×1线程，仅比较NB336/384/448。NB会影响矩阵乘法效率和面板/通信开销，不预先认定哪一个最好。

| 操作窗口 | 任务 |
|---|---|
| 0–5分钟 | 查队列，确认已有baseline文件，准备NB336独立副本 |
| 5–12分钟 | 运行NB336，核对PASSED并更新报告 |
| 12–19分钟 | 资源/时间允许才试NB448，否则停止增加候选 |
| 19–25分钟 | 可选：复测较好候选或当期NB384，检查波动 |
| 25–30分钟 | 固定选定配置、更新报告、校验日志和整理交付材料 |

已有baseline约5分钟/次。两次候选约10分钟；加一次复测共约15分钟计算、28 CPU核时，磁盘主要为少量日志。**排队不含在估算中，不能保证30分钟内获得资源。** 第5分钟仍无可用额度就以材料准备为主，保留已有有效baseline，不取消队友作业。

## 手动准备一轮

先登录集群、进入自己的仓库，将BASELINE设为已验证的原baseline目录；下面的路径占位符需要替换。示例只准备NB336。

```bash
squeue -u "$USER"
BASELINE=/你的原baseline绝对路径
trial="$PWD/.local/runs/nb336"
mkdir -p .local/runs
mkdir "$trial"
mkdir "$trial/logs"
cp "$BASELINE/xhpl" "$trial/xhpl"
cp HPL.dat "$trial/HPL.dat"
cp run.sh "$trial/run.sh"
sed -i '8s/^384$/336/' "$trial/HPL.dat"
diff -u HPL.dat "$trial/HPL.dat"
bash -n "$trial/run.sh"
```

逐步执行，任一步报错先停下；已有实验目录应换名，不继续复制覆盖。原因：独立目录保存本次输入和程序，避免排队时修改文件影响结果。diff应只显示NB由384变336。确认后进入该目录，手动执行**一次**`sbatch run.sh`，记下作业号；不用`bash run.sh`在登录节点运行计算。

用squeue查当前、sacct查历史，读取该轮logs中的.out和.err。正常退出、参数正确、PASSED且1通过/0失败/0跳过后才比性能。固定N时GFlops越高越好；小幅差异未复测就写“待确认”，不宣称稳定提升。第二次试验另建目录。

## 根据官方指南，要交什么

截止：**2026-11-22 23:59:59，北京时间**，提前完成上传。

**计分：一份原样、UTF-8、≤100 MiB的完整HPL输出。** 必须含Start/End、完整banner/参数表/结果表和PASSED，且只含一次运行的一个测试规模。不得裁剪、修改、拼接；sbatch成功不等于已计分。

在登录节点下载官方脚本，不修改它；实际日志路径替换后使用：

```bash
mkdir -p .local
wget -O .local/submit.sh https://lab.cs.tsinghua.edu.cn/scc/assets/submit.sh
chmod +x .local/submit.sh
.local/submit.sh --dry HPL /实际路径/logs/hpl_JOBID.out
# 与队长确认本队当前成绩，决定采用后才正式提交：
.local/submit.sh HPL /实际路径/logs/hpl_JOBID.out
```

dry返回`Validation Passed (dry run)`只验证；正式成功以`Server Message: Submission Accepted; Performance: ...`为准。**同队同题最后一次成功的正式提交覆盖当前成绩，不自动保留最好成绩。** 提交账号为组委会发给队长的队伍编号，可能不同于SSH账号。凭证/回执留本地。

**最终：全队所有题目统一一个final.tar.gz，≤100 MiB，通过REPORT提交。** 你负责其中的HPL子目录：

```text
final/HPL/
  report.pdf          问题、方法、实验结果、加速比和结论
  HPL.dat             与选定日志对应的参数
  Make.Linux_Intel    产生该xhpl的实际编译配置
  environment.txt     软件版本、运行环境及复现信息
  run.sh              实际使用的脚本
  hpl_JOBID.out       与选定计分结果一致的完整原始输出
```

编译/脚本改动在报告中说明。HPL清单未要求重复打包整套官方源码或预编译二进制；其他题目的源码/补丁按各自规定准备。不要拿未使用的参考Make文件代替实际构建配置。

将HPL子目录交队长，合并其他题后由队伍执行`tar -czf final.tar.gz final/`，再用官方脚本`--dry REPORT`校验、`REPORT`正式提交。只接受.tar.gz；GitHub推送、单独PDF、ZIP、.tgz和dry通过均不等于最终提交。REPORT的dry不代表内容已获审核。

## 优化时同步维护

每轮独立保留`.local/runs/实验名/`中的xhpl、HPL.dat、run.sh、environment.txt及完整日志；run.sh记录运行环境和哈希，实际编译配置/日志另从构建目录保存。

助手根据你提供的输出同步更新report.md中的假设、参数、正确性、性能和结论；决定采用才更新根目录配置。选定后将报告导出report.pdf，从该轮原文件组装HPL交付目录，并记录HPL/REPORT两类回执。未运行或未收到回执的项目保持待确认。原始日志不因公开或写报告而改写。

依据：[原题](https://lab.cs.tsinghua.edu.cn/scc/Benchmarks/HPL/) · [源码主页](https://www.netlib.org/benchmark/hpl/index.html) · [提交指南](https://lab.cs.tsinghua.edu.cn/scc/submit/)。最新通知优先。
