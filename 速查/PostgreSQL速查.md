# PostgreSQL 日常操作速查

> **这份文件是什么**：把每天都要敲的 PostgreSQL 命令固定下来，**按顺序一条条粘贴即可**。
> 每段都能独立粘贴 —— 但**换新窗口必须重跑 A 段**。
>
> **配套**：概念和原理见 `课程/第1周/第1课.md`；这份只管"怎么敲"。

---

## A. 开场（每开一个新 PowerShell 窗口，先跑这一段）

**不跑这段，后面所有 `$PG` 都会是空值，报错会是"不是内部或外部命令"。**

```powershell
# 可执行程序在哪个文件夹
$PG   = "G:\Project\PostgreSQL_pocket\pgsql\bin"

# 数据目录（数据库的数据放哪）
$DATA = "G:\Project\PostgreSQL_pocket\pgdata"

# 主配置文件（改端口、改内存都改它）
$CONF = "G:\Project\PostgreSQL_pocket\pgdata\postgresql.conf"

# 运行日志（起不来时看它）
$LOG  = "G:\Project\PostgreSQL_pocket\pgdata\server.log"
```

**确认生效 —— 应该原样打印出四个路径：**

```powershell
$PG; $DATA; $CONF; $LOG
```

---

## B. 看状态（先查，再动手）

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

**不确定的时候，用 `psql` 实测一下最准**（能打印版本号就是开着）：

```powershell
& "$PG\psql.exe" -U postgres -h 127.0.0.1 -c "SELECT version();"
```

> ⚠️ 和直觉相反：`status` 在"没运行"时**不是报错**，它返回退出码 `3`。
> 所以脚本里用 `if ($LASTEXITCODE -eq 0)` 判断是可靠的；
> 但如果你只看到一行中文就以为出事了，会白白慌一场。

### 三种典型报错，一眼对照

| psql 报错里出现 | 真正的原因 | 怎么办 |
| --- | --- | --- |
| `Connection refused (0x0000274D/10061)` | 那个端口上没有程序在听 | 服务没开 → C 段启动；或端口不对 → 加 `-p` |
| `database "xxx" does not exist` | 服务是好的，但**没有这个库** | 检查 `-d` 写的库名，或先用 `\l` 看有哪些库 |
| `password authentication failed` | 服务是好的，库也在，但**身份不对** | 检查 `-U` 写的用户名 |

**读报错的顺序（从后往前）：先看冒号后面的结论，再看带具体动词的那句（真正原因），最后才是 `Is the server running...?` 那种问句（提示，不是原因）。**

---

## C. 启动

```powershell
# -D 数据目录   -l 日志写到哪   start 动作
& "$PG\pg_ctl.exe" -D $DATA -l $LOG start
```

**成功时应该看到：**

```
等待服务器进程启动 .... 完成
服务器进程已经启动
```

**看到「服务器进程已经启动」才算成功。** 只看到第一行然后卡住，说明启动失败 —— 去 D 段看日志。

---

## D. 起不来 / 出问题 → 看日志

```powershell
# 看最后 30 行
Get-Content $LOG -Tail 30
```

**常见的几种，对照着看：**

| 日志里出现 | 什么意思 | 怎么办 |
| --- | --- | --- |
| `could not create any TCP/IP sockets` | 端口被占了 | 换端口，见 F 段 |
| `Address already in use` | 同上，5432 上已经有别的 PostgreSQL | 同上 |
| `invalid configuration parameter` | `postgresql.conf` 改坏了 | `notepad $CONF` 回去检查 |
| `syntax error` | 同上，多半是漏了引号或写错单词 | 同上 |

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

进去之后：

| 想干什么 | 敲 |
| --- | --- |
| 退出 | `\q` |
| 看有哪些库 | `\l` |
| 切到某个库 | `\c 库名` |
| 看当前库有哪些表 | `\dt` |
| 看某张表的结构 | `\d 表名` |
| 查帮助 | `\?` |
| 查某条 SQL 的语法 | `\h SELECT` |

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

## G. 停止

```powershell
& "$PG\pg_ctl.exe" -D $DATA stop
```

**成功时：**

```
等待服务器进程关闭 .... 完成
服务器进程已经关闭
```

---

## H. 重启（改完配置用这个最快）

```powershell
& "$PG\pg_ctl.exe" -D $DATA -l $LOG restart
```

---

## I. 不管当前开没开，都想要它是"开着"的状态

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

## 一页流水线（复制到记事本，每天从上往下粘贴）

```powershell
# ===== 1. 开场 =====
$PG   = "G:\Project\PostgreSQL_pocket\pgsql\bin"
$DATA = "G:\Project\PostgreSQL_pocket\pgdata"
$CONF = "G:\Project\PostgreSQL_pocket\pgdata\postgresql.conf"
$LOG  = "G:\Project\PostgreSQL_pocket\pgdata\server.log"

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

---

## 生词补充（本文件里新出现的）

| 代码里的词 | 中文短名 | 一句话 |
| --- | --- | --- |
| `status` | 看状态 | 问一句"服务器现在开着吗" |
| `start` / `stop` / `restart` | 启 / 停 / 重启 | `pg_ctl` 的三个动作 |
| `$LASTEXITCODE` | 上条命令的退出码 | 0 一般表示成功，非 0 表示有情况 |
| `*> $null` | 丢弃输出 | 把命令的输出丢掉，不让它打到屏幕上 |
| `Get-Content -Tail` | 看文件末尾 | 看日志最后几行，不刷屏 |
| `-t` | 只要值 | 去掉表头和边框 |
| `-A` | 不对齐 | 输出用 `|` 分隔，方便程序读 |
| `\q` | 退出 | 从 `psql` 交互界面里退出来 |
