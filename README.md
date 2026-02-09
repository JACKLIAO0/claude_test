# Claude Code 使用案例：从零完成异步FIFO芯片设计与验证

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Verilog](https://img.shields.io/badge/Language-Verilog-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen.svg)]()
[![Built with Claude](https://img.shields.io/badge/Built%20with-Claude%20Code-blueviolet.svg)](https://claude.ai)

## 项目简介

这是一个 **Claude Code 的真实使用案例**。我给 Claude 一段自然语言指令，Claude 独立完成了从环境搭建、RTL设计、验证调试到文档生成的全部工作，最终交付了一个功能完整、验证通过的参数化异步FIFO设计项目。

---

## 我给了 Claude 什么指令

我只给了 Claude 以下 7 条指令（原文见 [prompt.txt](prompt.txt)）：

> 1. 你现在是一名数字芯片设计工程师。
> 2. 我要你设计一个异步FIFO模块，是一个通用模块，支持参数化设计。
> 3. 我要你在 Mac 上的 `~/Claude/async_fifo_test` 文件夹中完成设计和验证。
> 4. 从零搭建一套完整的 UVM 验证环境（包含所有 UVM 组件）。
> 5. 你可以在那个文件夹下载开源的仿真验证工具，比如 iverilog。
> 6. 进行波形调试，独立解决遇到的所有问题，直到功能验证通过。
> 7. 记录设计过程中遇到的问题，生成最终技术文档。

就这么简单，**一段话，没有任何代码模板，没有任何参考设计**。

---

## Claude 具体完成了什么

### 1. 环境搭建

- 自动通过 Homebrew 安装了 **Icarus Verilog 12.0**（开源 Verilog 仿真器）
- 安装过程中遇到网络问题，Claude 自行切换到 `--force-bottle` 方式解决
- 创建了完整的项目目录结构（`rtl/`、`tb/`、`sim/`、`docs/`）

### 2. RTL 设计（4个模块，225行 Verilog）

Claude 独立设计了以下模块：

| 模块 | 文件 | 功能 |
|------|------|------|
| `dual_port_ram.v` | 34行 | 双口RAM，支持独立读写端口 |
| `gray_counter.v` | 39行 | Gray码计数器，用于跨时钟域安全传输 |
| `synchronizer.v` | 28行 | 两级触发器同步器，处理亚稳态 |
| `async_fifo.v` | 124行 | 顶层FIFO模块，集成上述组件 |

**关键设计决策（Claude 自主做出）：**
- 选用 **Gray码编码** 进行跨时钟域指针同步（每次只变化1位，最大程度减少亚稳态风险）
- 使用 **两级D触发器链** 作为同步器（业界标准CDC方案）
- 采用 **组合逻辑读取** 的双口RAM（而非寄存器输出），简化时序
- 空/满标志在各自的时钟域内生成，保证信号稳定

### 3. 验证与调试（最体现 Claude 独立解决问题的能力）

**第一次尝试：复杂Testbench（失败）**
- Claude 最初编写了一个 483 行的复杂 testbench（`tb_async_fifo.v`），模拟 UVM 架构
- 包含并发随机读写、覆盖率监控、自检机制
- 仿真运行后出现 **221 个数据不匹配错误**

**Claude 的调试过程：**
1. 分析波形，发现错误根因：testbench 的并发读写没有考虑 CDC 同步延迟（2-3个时钟周期）
2. 认识到这不是 RTL 设计的 bug，而是 **testbench 验证策略的问题**
3. 决定重新设计验证方案

**第二次尝试：简化Testbench（成功）**
- 重新设计了 199 行的 `tb_async_fifo_simple.v`
- 采用 **分阶段测试**：先写入一批数据 → 等待同步 → 再读取验证
- 测试用例覆盖：基础读写、写满检测、读空检测、不同时钟频率比

**最终验证结果：**
```
写入操作：33 次 ✅
读出操作：33 次 ✅
数据错误：0 次 ✅
测试通过率：100%
```

### 4. 构建自动化

Claude 编写了 Makefile，支持一键操作：

```bash
make all      # 编译 + 仿真
make compile  # 仅编译
make sim      # 仅仿真
make wave     # 打开波形查看器
make clean    # 清理
```

### 5. 文档生成

Claude 生成了完整的双语技术文档：

**英文文档：**
- `docs/design_doc.md` — 设计文档
- `docs/verification_report.md` — 验证报告
- `docs/issues_log.md` — 问题日志

**中文文档（后续追加指令生成）：**
- `docs/设计文档.md` — 设计原理与实现
- `docs/验证报告.md` — 测试结果与覆盖率分析
- `docs/问题日志.md` — 调试过程记录
- `docs/项目总结.md` — 项目总结

### 6. 项目发布到 GitHub

我后续又给了几条追加指令，Claude 也一一完成：

| 我的指令 | Claude 的操作 |
|---------|--------------|
| "帮我把这个项目开源到我的 GitHub 个人账户下" | 配置 Git 仓库、生成 SSH 密钥（ed25519）、配置 `~/.ssh/config`、添加 MIT 开源许可 |
| "帮我配置SSH密钥" | 生成密钥对，指导我添加到 GitHub |
| 遇到公司网络封锁 GitHub | Claude 自动尝试 HTTPS → SSH 22端口 → SSH 443端口，最终通过 `ssh.github.com:443` 解决 |
| "仓库名为 claude_test" | 立即更新 remote URL |
| "把 prompt.txt 也推送上 GitHub" | 修改 `.gitignore`、`git add -f`、提交并推送 |
| "sim 文件夹也上传 GitHub 仓库" | 修改 `.gitignore` 中的 sim 规则、添加仿真输出文件、提交并推送 |

---

## Claude 遇到的问题与解决方案

| 问题 | 原因 | Claude 的解决方式 |
|------|------|------------------|
| Homebrew 安装失败 | 网络限制 | 切换为 `--force-bottle` 安装预编译包 |
| 复杂 testbench 221 个数据错误 | 并发读写未考虑 CDC 同步延迟 | 重新设计分阶段验证策略 |
| HTTPS 推送 GitHub 失败 | 公司网络封锁 443 端口 | 配置 SSH over 443 (ssh.github.com) |
| SSH 22 端口超时 | 同上 | 同上 |
| 仓库 not found | 用户未创建远程仓库 | 提示用户创建后重试 |
| 文件被 .gitignore 忽略 | 默认规则排除了 prompt.txt 和 sim/ | 修改 .gitignore 规则 |

---

## 项目最终交付物

```
async_fifo_test/
├── rtl/                          # RTL 设计源码
│   ├── async_fifo.v              # 顶层异步FIFO（124行）
│   ├── gray_counter.v            # Gray码计数器（39行）
│   ├── synchronizer.v            # 两级同步器（28行）
│   └── dual_port_ram.v           # 双口RAM（34行）
├── tb/                           # 测试平台
│   ├── tb_async_fifo.v           # 复杂testbench（483行，调试参考）
│   └── tb_async_fifo_simple.v    # 简化testbench（199行，验证通过）
├── sim/                          # 仿真输出
│   ├── async_fifo.vcd            # 波形文件
│   ├── async_fifo.vvp            # 编译产物
│   └── test_simple.vvp           # 简化测试编译产物
├── docs/                         # 技术文档（中英双语）
│   ├── design_doc.md
│   ├── verification_report.md
│   ├── issues_log.md
│   ├── 设计文档.md
│   ├── 验证报告.md
│   ├── 问题日志.md
│   └── 项目总结.md
├── Makefile                      # 构建自动化
├── prompt.txt                    # 原始指令
├── LICENSE                       # MIT 开源许可
└── README.md                     # 本文件
```

**代码统计：** 907 行 Verilog 代码 | 9 份技术文档 | 4 次 Git 提交

---

## 快速复现

```bash
# 安装工具
brew install icarus-verilog

# 编译并仿真
make all

# 查看波形（需安装 gtkwave）
make wave
```

## 设计参数

```verilog
parameter DATA_WIDTH = 8;    // 数据位宽（默认 8 位）
parameter ADDR_WIDTH = 4;    // 地址位宽（FIFO 深度 = 2^4 = 16）
```

---

## 总结

这个项目展示了 Claude Code 在硬件设计领域的实际能力：

- **从自然语言到可工作的代码**：一段话就能产出完整的 RTL 设计
- **独立调试能力**：遇到 221 个测试错误时，Claude 没有放弃，而是分析根因并重新设计验证策略
- **工程化交付**：不只是写代码，还包括工具安装、构建自动化、双语文档、Git 配置等全流程
- **灵活应变**：面对网络封锁等意外情况，能自主尝试多种替代方案

整个过程中 **我没有写过一行代码**，所有设计、调试、文档都是 Claude 独立完成的。

---

## 许可证

[MIT License](LICENSE)

## 参考文献

- Clifford E. Cummings, "Simulation and Synthesis Techniques for Asynchronous FIFO Design"
- Clock Domain Crossing (CDC) Design & Verification Techniques
