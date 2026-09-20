# PostgreSQL 日常操作速查

> **这份文件是什么**：把每天都要敲的 PostgreSQL 命令固定下来，**按顺序一条条粘贴即可**。
> **换新窗口必须重跑 A 段**（变量只对当前窗口有效）。
>
> **两台机器都覆盖了**：A 段有两块变量，抄你在的那台。差异表见 I 段。
>
> **配套**：概念和原理见 `课程/第1周/` 下的课程文件；这份只管"怎么敲"。

---

## A. 开场 —— 一段搞定（每开一个新窗口，粘贴这一整块）

**先选你在哪台机器上**：抄下面**其中一块**，整块粘进 PowerShell。它一次做完三件事：
定义路径 → 查状态 → 启动。

### 在**公司电脑**（`G:` 盘）

```powershell
# ===== 1. 定义路径 =====
$PG   = "G:\Project\PostgreSQL_pocket\pgsql\bin"
$DATA = "G:\Project\PostgreSQL_pocket\pgdata"
$CONF = "G:\Project\PostgreSQL_pocket\pgdata\postgresql.conf"
$LOG  = "G:\Project\PostgreSQL_pocket\pgdata\server.log"

# ===== 2. 看状态（0 = 在跑，3 = 没跑）=====
& "$PG\pg_ctl.exe" -D $DATA status
$LASTEXITCODE

# ===== 3. 启动 =====
& "$PG\pg_ctl.exe" -D $DATA -l $LOG start
```

### 在**家里电脑**（`C:` 盘）

```powershell
# ===== 1. 定义路径 =====
$PG   = "C:\Users\Admin\Documents\Project\PostgreSQL_pocket\pgsql\bin"
$DATA = "C:\Users\Admin\Documents\Project\PostgreSQL_pocket\pgdata"
$CONF = "C:\Users\Admin\Documents\Project\PostgreSQL_pocket\pgdata\postgresql.conf"
$LOG  = "C:\Users\Admin\Documents\Project\PostgreSQL_pocket\pgdata\server.log"

# ===== 2. 看状态（0 = 在跑，3 = 没跑）=====
& "$PG\pg_ctl.exe" -D $DATA status
$LASTEXITCODE

# ===== 3. 启动 =====
& "$PG\pg_ctl.exe" -D $DATA -l $LOG start
```

**成功时第 3 步会打印：**

```
等待服务器进程启动 .... 完成
服务器进程已经启动
```

> ⚠️ 如果打印的是 `pg_ctl: another server might be running` ——
> 那是陈旧的 `postmaster.pid`，处理办法见 `课程/第1周/第4课.md` 第五节。
> **先看 `status` 的退出码**：`3` 才说明真的没在跑。

> **懒人版**：如果懒得每次选，把这一段贴在**最前面**，它会自己判断在哪台机器：
>
> ```powershell
> if (Test-Path "G:\Project\PostgreSQL_pocket\pgsql\bin") {
>     $ROOT = "G:\Project\PostgreSQL_pocket"
> } else {
>     $ROOT = "C:\Users\Admin\Documents\Project\PostgreSQL_pocket"
> }
> $PG = "$ROOT\pgsql\bin"; $DATA = "$ROOT\pgdata"
> $CONF = "$DATA\postgresql.conf"; $LOG = "$DATA\server.log"
> & "$PG\pg_ctl.exe" -D $DATA status
> & "$PG\pg_ctl.exe" -D $DATA -l $LOG start
> ```
> **但它没在真实机器上验证过** —— 两台都试一次再说。

---

## B. 看状态（单独查，不动手）

**A 段第二步已经查过一次。** 想单独再查：

```powershell
# 0 = 正在运行    3 = 没有运行
& "$PG\pg_ctl.exe" -D $DATA status

# 看它刚才那个退出码是多少
$LASTEXITCODE
```

**两种输出：**

```
pg_ctl: 没有服务器进程正在运行          <- 没开
pg_ctl: 服务器进程正在运行 (PID: 12345)  <- 开着
```

**不确定的时候，用 `psql` 实测最准**（能打印版本号就是开着）：

```powershell
& "$PG\psql.exe" -U postgres -h 127.0.0.1 -c "SELECT version();"
```

> ⚠️ 和直觉相反：`status` 在"没运行"时**不是报错**，它返回退出码 `3`。
> 脚本里用 `if ($LASTEXITCODE -eq 0)` 判断是可靠的；
> 但只看一行中文就以为出事了，会白白慌一场。

### 三种典型报错，一眼对照

| psql 报错里出现 | 真正的原因 | 怎么办 |
| --- | --- | --- |
| `Connection refused (0x0000274D/10061)` | 那个端口上没有程序在听 | 服务没开 → A 段；或端口不对 → 加 `-p` |
| `database "xxx" does not exist` | 服务是好的，但**没有这个库** | 检查 `-d` 的库名，或 `\l` 看有哪些库 |
| `password authentication failed` | 服务是好的，库也在，但**身份不对** | 检查 `-U` 的用户名 |
| `permission denied ...` | 身份对、名字对，**没这个权限** | 看报错的 `DETAIL`，它通常说缺哪个属性 |

**读报错的顺序：先看冒号后面的结论，再看带具体原因的那句，最后才是 `Is the server running...?` 那种问句（提示，不是原因）。**

---

## C. 启动 / 停止 / 重启

**A 段第三步已经启动过。** 单独用：

```powershell
# 停止
& "$PG\pg_ctl.exe" -D $DATA stop

# 重启（改完配置用这个最快）
& "$PG\pg_ctl.exe" -D $DATA -l $LOG restart

# 只看状态
& "$PG\pg_ctl.exe" -D $DATA status
```

**停止成功时：**

```
等待服务器进程关闭 .... 完成
服务器进程已经关闭
```

---

## D. 起不来 / 出问题 → 看日志

```powershell
# 看最后 30 行
Get-Content $LOG -Tail 30
```

| 日志里出现 | 什么意思 | 怎么办 |
| --- | --- | --- |
| `could not create any TCP/IP sockets` | 端口被占了 | 换端口，见 F 段 |
| `Address already in use` | 同上，5432 上已经有别的 PostgreSQL | 同上 |
| `invalid configuration parameter` | `postgresql.conf` 改坏了 | `notepad $CONF` 回去检查 |
| `syntax error` | 同上，多半漏了引号或写错单词 | 同上 |

---

## E. 连接

### 随手执行一条 SQL

```powershell
# -U 用户   -h 主机   -p 端口（默认 5432，可省）   -c 执行这条就退出
& "$PG\psql.exe" -U postgres -h 127.0.0.1 -c "SELECT version();"
```

### 进入交互式界面（可以一直敲 SQL）

```powershell
# 不带 -c 就会进入 psql 的交互界面
& "$PG\psql.exe" -U postgres -h 127.0.0.1
```

进去之后（**注意：这些帮助命令也必须先连上服务器才给看**）：

| 想干什么 | 敲 |
| --- | --- |
| 退出 | `\q` |
| 看有哪些库 | `\l` |
| 切到某个库 | `\c 库名` |
| 看当前库有哪些表 | `\dt` |
| 看某张表的结构 | `\d 表名` |
| **列出所有元命令** | `\?` |
| **查某条 SQL 的语法** | `\h SELECT` |
| 看当前身份 / 连的哪个库 | `\conninfo` |
| 把快慢变成数字 | `\timing`（开关） |
| 结果太宽，改竖排 | `\x`（开关） |
| 用编辑器写多行 SQL | `\e` |
| 执行一个 SQL 脚本文件 | `\i 文件路径` |

### 只要值，不要表头和边框（写脚本时用）

```powershell
# -t 去掉表头和边框   -A 不对齐（用 | 分隔）
& "$PG\psql.exe" -U postgres -h 127.0.0.1 -tAc "SELECT version();"
```

---

## F. 改端口（第 10 周之后可能用得上）

```powershell
# 1. 先停
& "$PG\pg_ctl.exe" -D $DATA stop

# 2. 打开配置文件，搜 port，把 #port = 5432 改成 port = 5433
notepad $CONF

# 3. 启动
& "$PG\pg_ctl.exe" -D $DATA -l $LOG start

# 4. 用新端口连 —— 应该成功
& "$PG\psql.exe" -U postgres -h 127.0.0.1 -p 5433 -c "SELECT version();"

# 5. 用旧端口连 —— 应该失败
& "$PG\psql.exe" -U postgres -h 127.0.0.1 -p 5432 -c "SELECT version();"
```

**要点：改配置文件之后必须重启，否则不生效。**

---

## G. 数据目录（看一眼磁盘）

```powershell
# 数据目录第一层有什么
Get-ChildItem -LiteralPath $DATA -Force

# base\ 下的数字目录 = 每个库一个（目录名是 OID，不是库名）
Get-ChildItem -LiteralPath "$DATA\base" -Force -Directory | Select-Object -ExpandProperty Name

# WAL 有几个文件（每个 16 MB）
Get-ChildItem -LiteralPath "$DATA\pg_wal" -Force -File | Select-Object Name, Length
```

**库名和 OID 怎么对上：**

```powershell
& "$PG\psql.exe" -U postgres -h 127.0.0.1 -c "SELECT oid, datname FROM pg_database ORDER BY oid;"
```

> ⚠️ `postmaster.pid` 可能是**陈旧的**（服务已停、文件还在）。
> 它会让你启动时看到 `another server might be running`。
> **先 `status` 确认退出码是 3，再删它。**

---

## H. 不管当前开没开，都想要它是"开着"的状态

**改完配置、心里没底的时候用这段，它自己判断：**

```powershell
# 先悄悄查一下状态（*> $null 是"把输出丢掉，不要打到屏幕上"）
& "$PG\pg_ctl.exe" -D $DATA status *> $null

# 如果正在运行，先停掉；没运行就跳过
if ($LASTEXITCODE -eq 0) {
    & "$PG\pg_ctl.exe" -D $DATA stop
    "旧的已停掉"
} else {
    "本来就没开，不用停"
}

# 重新启动
& "$PG\pg_ctl.exe" -D $DATA -l $LOG start
```

---

## I. 两台机器的差异（换机器前先看这里）

**这两台机器的路径**盘符都不同** —— 所以在公司写完的命令，回家必须换掉 A 段那块变量。**

| | 公司电脑（机器 A） | 家里电脑（机器 B） |
| --- | --- | --- |
| 盘符 | `G:` | `C:` |
| 程序目录 | `G:\Project\PostgreSQL_pocket\pgsql` | `C:\Users\Admin\Documents\Project\PostgreSQL_pocket\pgsql` |
| 数据目录 | `G:\Project\PostgreSQL_pocket\pgdata` | `C:\Users\Admin\Documents\Project\PostgreSQL_pocket\pgdata` |
| 日志 | `...\pgdata\server.log` | `...\pgdata\server.log` |
| 端口 | 5432 | 5432 |
| PostgreSQL 版本 | 18.6 | 18.6 |

**两台除了"盘符 + 路径前缀"，其余完全一样。** 所以命令本身通用，**只有 A 段那四个变量要换**。

**这份表存在的意义**：下次在某台机器上报错、另一台正常时，**第一件事是翻它。**

**换机器四条纪律**（见 `课程/第1周/第0课.md`）：

| 什么时候 | 做什么 |
| --- | --- |
| 每节课结束 | 就提交、就推送 —— **不留"以后再提交"** |
| 换机器**之前** | `push` |
| 换机器**之后** | 先 `pull` |
| 任何时候 | 数据目录和二进制不进仓库 |

---

## 一页流水线（复制到记事本，每天从上往下粘贴）

```powershell
# ===== 0. 选机器：两台只留一块，另一块用 # 注释掉 =====

# --- 公司电脑 ---
$PG   = "G:\Project\PostgreSQL_pocket\pgsql\bin"
$DATA = "G:\Project\PostgreSQL_pocket\pgdata"

# --- 家里电脑（要用就取消下面两行的注释，并把上面两行注释掉）---
# $PG   = "C:\Users\Admin\Documents\Project\PostgreSQL_pocket\pgsql\bin"
# $DATA = "C:\Users\Admin\Documents\Project\PostgreSQL_pocket\pgdata"

# ===== 1. 派生剩下两个路径 =====
$CONF = "$DATA\postgresql.conf"
$LOG  = "$DATA\server.log"

# ===== 2. 查状态 =====
& "$PG\pg_ctl.exe" -D $DATA status

# ===== 3. 启动 =====
& "$PG\pg_ctl.exe" -D $DATA -l $LOG start

# ===== 4. 确认能连 =====
& "$PG\psql.exe" -U postgres -h 127.0.0.1 -c "SELECT version();"

# ===== 5. 开始干活（进入交互界面）=====
& "$PG\psql.exe" -U postgres -h 127.0.0.1

# ===== 6. 收工（在 psql 里先 \q 退出，再停服务）=====
& "$PG\pg_ctl.exe" -D $DATA stop
```

> **第 1 步为什么能省掉两个路径**：`$CONF` 和 `$LOG` 都是从 `$DATA` 派生的。
> 只改 `$DATA` 一处，另外两个自动跟着变 —— **少一处会写错的地方**。

---

## 生词补充（本文件里新出现的）

| 代码里的词 | 中文短名 | 一句话 |
| --- | --- | --- |
| `status` | 看状态 | 问一句"服务器现在开着吗" |
| `start` / `stop` / `restart` | 启 / 停 / 重启 | `pg_ctl` 的三个动作 |
| `$LASTEXITCODE` | 上条命令的退出码 | 0 一般表示成功，非 0 表示有情况 |
| `*> $null` | 丢弃输出 | 把命令的输出丢掉，不让它打到屏幕上 |
| `Get-Content -Tail` | 看文件末尾 | 看日志最后几行，不刷屏 |
| `Get-ChildItem -Force` | 列目录 | 列出文件夹内容，含隐藏文件 |
| `Test-Path` | 检查存在 | 问一句"这个路径在不在" |
| `-t` | 只要值 | 去掉表头和边框 |
| `-A` | 不对齐 | 输出用 `|` 分隔，方便程序读 |
| `\q` | 退出 | 从 `psql` 交互界面里退出来 |
| `\?` | 元命令手册 | 列出所有反斜杠命令 |
| `\h` | SQL 语法手册 | 给出某条 SQL 的语法 |
| `\e` | 编辑器 | 用外部编辑器写多行 SQL |
| `\i` | 跑脚本 | 执行一个 `.sql` 文件 |
| `\timing` | 计时开关 | 每条 SQL 后面打一行耗时 |
| `\x` | 竖排开关 | 结果改成"字段名：值"竖着显示 |
