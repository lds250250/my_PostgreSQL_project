# SQL → RAG 学习大纲 v2

> **数据库：PostgreSQL 18**（当前稳定版 18.6，支持至 2030-11；13 及以下已于 2025-11 停止支持）
>
> **为什么是 PostgreSQL 而不是 MySQL**：后面 RAG 阶段要用 `pgvector` 存向量，而 **pgvector
> 只有 PostgreSQL 有**。学 MySQL 就要额外再学一个向量库（Qdrant / Chroma / Milvus），
> 变成两套系统、两套运维。用 PostgreSQL 则**一个库同时搞定业务数据、向量检索、全文检索
> 关键词召回**，这三样正好是 RAG 检索层的全部组件。
>
> **版本选择**：用 18。17 可用但没必要。**不要用 13 或更早**（已 EOL，且
> `MERGE`、`jsonb` 部分特性、并行查询能力差异大，教程和实测会对不上）。

---

## 第 0 步：环境（半天，别拖成一周）

**先明确一件事：Docker 不是必需的。但 Windows 上跑 PostgreSQL 只有三条路。**

| 方案 | 装什么 | 卸载干净 | 换版本 | 适合阶段 |
|---|---|---|---|---|
| **C. 官方 ZIP 免安装版** | 解压一个文件夹 | ✅ 删文件夹 | ✅ 多版本并存 | **第 1–6 周（推荐起步）** |
| **A. Docker Desktop** | WSL2 + Docker | ✅ 删卷即可 | ✅ 一行换 tag | **第 7 周起（推荐切换）** |
| **B. EDB 官方 Installer** | 一个 Windows 服务 | ❌ 注册表残留 | ❌ 卸载重装 | 只想点鼠标，不推荐 |

**为什么先 C 后 A**：前 6 周数据库只是教具，别让安装在第一天耗掉热情。ZIP 版无需管理员
权限、不改注册表、半小时出结果。到第 9 周（百万行实验）和第 11 周（复现死锁）时，
Docker 的「秒级建库 + 删卷即回滚」才有真实价值，那时再装。

**Docker 的坑**：PostgreSQL 官方**没有 Windows 原生容器**，`postgres` 镜像跑的是 Linux 版，
所以 Windows 上必须走 WSL2 后端（需要 BIOS 开虚拟化 + 管理员权限装 WSL2）。
镜像约 400MB，**C 盘紧张的话把镜像和卷指到 G 盘**。

**方案 C 具体步骤**（Windows，无需管理员权限）：

```powershell
# 1. 下载（EDB 提供的免安装二进制，与官方 installer 同源）
#    https://www.enterprisedb.com/download-postgresql-binaries
#    选 Windows x86-64 → 下载 postgresql-18.x-x-windows-x64-binaries.zip
#    解压到 G:\Project\my_PostgreSQL_project\pgsql

# 2. 初始化数据目录（-U 指定超级用户，-E 编码，--locale 排序规则）
G:\Project\my_PostgreSQL_project\pgsql\bin\initdb.exe `
  -D G:\Project\my_PostgreSQL_project\pgdata `
  -U postgres -E UTF8 --locale=C

# 3. 启动服务（-l 指定日志文件）
G:\Project\my_PostgreSQL_project\pgsql\bin\pg_ctl.exe `
  -D G:\Project\my_PostgreSQL_project\pgdata `
  -l G:\Project\my_PostgreSQL_project\pgdata\server.log start

# 4. 连接（默认监听 5432，socket 在 localhost）
G:\Project\my_PostgreSQL_project\pgsql\bin\psql.exe -U postgres -h 127.0.0.1 -d postgres
```

> **为什么建议走一遍 ZIP 版**：你会亲眼看到 PostgreSQL 其实是「一个数据目录 + 一个进程」，
> `initdb` 和 `pg_ctl` 正是 Docker 镜像里 entrypoint 帮你做的事。这层认知在第 9 周做
> 实验、第 10 周讲 MVCC 时会回馈你。用 Installer 点几下鼠标是学不到的。

**交付物**：`psql -U postgres -c "SELECT version();"` 能打印出 18.x。

---

# 第一部分：SQL 核心（第 1–13 周）

> **时间投入建议**：每周 6–8 小时（3 次 × 2 小时 + 1 次复盘）。**每周末必须有一个可运行的
> 交付物**，没有交付物的一周等于没学。

## 第一阶段：语法、查询与建模（第 1–6 周）

### 第 1 周：环境与 psql 上手
- 从上面「第 0 步」选一条路走通，记录你选的方案和理由
- `psql` 元命令：`\l` `\d` `\dt` `\du` `\dn` `\c` `\x` `\timing` `\e` `\i`
- `\?` 和 `\h SELECT` 查帮助——**这个习惯比背命令重要**
- 建库、建角色、`GRANT` / `REVOKE` 最小权限
- 数据目录结构（`base/` `pg_wal/` `postgresql.conf` `pg_hba.conf`）各是什么
- **交付物**：一条 `.sql` 脚本，用 `\i` 一键建出 `learn_sql` 库和一个只读角色

### 第 2 周：数据类型、建表与**数据建模**
- 类型选择：`NUMERIC` 存金额（**绝不用 `FLOAT`**）、`TIMESTAMPTZ` vs `TIMESTAMP`
  （**一律用 `TIMESTAMPTZ`**）、`TEXT` vs `VARCHAR(n)`（PG 里性能无差，别用长度限制
  当校验）、`UUID` vs `BIGSERIAL`（分布式 vs 单机）、`JSONB` vs 关系表（**什么时候
  该用 JSONB，什么时候是设计懒惰**）
- DDL：`CREATE` / `ALTER` / `DROP`，`IF NOT EXISTS`、`ADD COLUMN ... DEFAULT`
- 约束：`NOT NULL` / `DEFAULT` / `UNIQUE` / `CHECK` / `PRIMARY KEY` / `FOREIGN KEY`
- 级联行为：`ON DELETE CASCADE` / `RESTRICT` / `SET NULL` —— **每个都手动试错一次**
- **【本次新增】数据建模**（原大纲缺失，会被后面卡住）
  - 一对多：外键放哪边、为什么
  - 多对多：**必须**有中间表，以及中间表要不要自己的主键
  - 反范式的时机：什么时候故意冗余，代价是什么
  - **练习**：把「博客」需求建成表——用户 / 文章 / 标签 / 评论（含文章的标签是多对多）
- **交付物**：`schema.sql`（能重复执行不报错）+ 一张 ER 图（手画拍照即可）

### 第 3 周：增删改、upsert 与 **Python 连接**
- `INSERT` 单行 / 多行 / `INSERT ... SELECT`
- **`INSERT ... ON CONFLICT DO UPDATE`**（upsert）—— 重点理解 `EXCLUDED` 伪表
- `UPDATE` / `DELETE` + `RETURNING`（**`RETURNING` 是 PG 的杀手锏，别只会 `SELECT`**）
- `TRUNCATE` vs `DELETE`（锁、事务、`RESTART IDENTITY`、能不能回滚）
- **【本次新增】Python 连接层**（原大纲第 12 周才提，太晚）
  - 装 `psycopg`（psycopg3）：`pip install "psycopg[binary]"`
  - 连接、执行、取结果、提交
  - **参数化查询**：`cur.execute("... WHERE id = %s", (id,))` —— 亲手写一次字符串
    拼接的 SQL 注入示例，再改成参数化，**这个印象要刻进肌肉记忆**
  - `with psycopg.connect(...) as conn:` 的事务边界语义
  - 连接池（`psycopg_pool`）—— 先会用，原理第 11 周再补
- **交付物**：`load_notes.py`，扫一个 Markdown 目录，把标题/正文/路径 upsert 进数据库，
  重复跑不产生重复行

### 第 4 周：查询基础与 NULL 语义
- `SELECT` / `DISTINCT` / `DISTINCT ON`（PG 特有，很实用）/ 别名
- `WHERE`：`BETWEEN` `IN` `LIKE` `ILIKE` `IS DISTINCT FROM` / `ANY` `ALL`
- **NULL 三值逻辑**：`NULL = NULL` → `unknown`；`IS NULL` / `IS NOT NULL`；
  `COALESCE` / `NULLIF`；**为什么 `WHERE col <> 'x'` 会漏掉 NULL 行**
- `ORDER BY` / `NULLS FIRST|LAST` / `LIMIT OFFSET` / **`FETCH FIRST`**
- `CASE WHEN`（简单 CASE vs 搜索 CASE）
- `CAST` 与 `::`；字符串函数；**`format()` / `concat_ws()`**
- **日期时间（原大纲一句带过，实际高频）**
  - `now()` / `CURRENT_DATE` / `date_trunc('day', ts)` / `EXTRACT` / `date_part`
  - `INTERVAL '7 days'`、`ts > now() - INTERVAL '7 days'` —— **RAG 里「最近 7 天
    的对话」就靠这个**
  - 时区运算：`AT TIME ZONE`，为什么必须存 `TIMESTAMPTZ`
- **交付物**：对第 3 周导入的笔记表写 10 条查询，其中至少 2 条含日期区间过滤

### 第 5 周：JOIN 全套
- `INNER` / `LEFT` / `RIGHT` / `FULL OUTER` / `CROSS` / 自连接
- **【核心】`ON` 与 `WHERE` 在 `LEFT JOIN` 中的差异** —— 用「查每个用户及其订单数，
  含零订单用户」这个经典题亲手验证：
  - 条件写在 `ON` → 零订单用户保留，计数为 0
  - 条件写在 `WHERE` → 零订单用户被过滤掉，行为退化成 `INNER JOIN`
- `USING (col)` 与 `NATURAL JOIN`（知道即可，**生产禁用 `NATURAL JOIN`**）
- 反连接三种写法对比：`LEFT JOIN ... IS NULL` / `NOT EXISTS` / `NOT IN`
- **交付物**：一张对比表——同一需求用 `ON` 和 `WHERE` 两种写法，贴出实际结果差异

### 第 6 周：聚合、子查询、CTE 与窗口函数
- `GROUP BY` / `HAVING` / 分组集 `GROUPING SETS` `ROLLUP` `CUBE`（知道存在）
- `COUNT(*)` vs `COUNT(col)` vs `COUNT(DISTINCT col)` —— **三者在有 NULL 时的差异**
- 子查询：标量 / `IN` / `EXISTS` / 派生表 / LATERAL
- **`NOT IN` 遇 NULL 返回空集** —— 亲手复现：造一个含 NULL 的列，`NOT IN` 返回 0 行，
  换成 `NOT EXISTS` 结果正确
- `WITH` 与 `WITH RECURSIVE`（递归查树形结构：评论盖楼 / 组织架构）
- 窗口函数：`OVER (PARTITION BY ... ORDER BY ...)`、
  `ROW_NUMBER` / `RANK` / `DENSE_RANK` / `LAG` / `LEAD` /
  `SUM() OVER` 累计与移动窗口（`ROWS BETWEEN ...`）
- **聚合 vs 窗口的思维差别**：聚合把 N 行压成 1 行，窗口保留 N 行 —— 这一句想通，
  窗口函数就通了
- `UNION ALL` vs `UNION`（**性能差一倍以上，能 `ALL` 就 `ALL`**）
- **交付物**：见下方第 6 周里程碑

### 第 6 周里程碑：迷你知识库（第一个能跑的东西）
> 原大纲第 12 周才有项目产出，前 11 周容易失去动力。这里提前给一个「有反馈」的交付物。

用纯 SQL 建 `kb_documents` 表（标题、正文、来源路径、创建时间、标签），导入 20+ 篇
你自己的 Markdown 笔记，然后写出这 6 条查询：

1. 标题或正文含某关键词（`ILIKE '%x%'`）
2. 最近 7 天新增的文档（日期区间）
3. 按月统计文档数量（`date_trunc` + `GROUP BY`）
4. 列出每个标签下的文档数，**含零文档的标签**（`LEFT JOIN` + `ON` 条件）
5. 找出从未被任何标签引用的文档（**`NOT EXISTS`，不是 `NOT IN`**）
6. 给每篇文档在其标签内按时间排名（窗口函数 `ROW_NUMBER() OVER (PARTITION BY ...)`）

**验收**：6 条查询全部跑通并保存成 `kb_queries.sql`；第 5、6 条能说清为什么这样写。

---

## 第二阶段：原理、性能与并发（第 7–12 周）

### 第 7 周：索引原理
- B+ 树结构直觉（**不用能手写，但要知道为什么范围查询快、为什么写慢**）
- PG 的索引类型：B-tree（默认）/ Hash / **GIN**（数组、JSONB、全文检索）/
  GiST（地理、范围类型）/ BRIN（超大有序表，如时间序列）
- **复合索引与最左前缀** —— `(a, b, c)` 能加速哪些查询、不能加速哪些
- 覆盖索引与 **`INCLUDE` 列**、`Index Only Scan` 的前提（visibility map）
- 索引选择性：为什么给「性别」建索引毫无意义
- 部分索引（`WHERE deleted_at IS NULL`）、表达式索引（`lower(email)`）
- **写放大**：每个索引都是 INSERT/UPDATE 的成本，索引不是越多越好
- **交付物**：为第 6 周的 `kb_documents` 表设计索引方案，写清每条索引服务于哪个查询

### 第 8 周：执行计划与 EXPLAIN
- `EXPLAIN` vs `EXPLAIN ANALYZE`（**后者会真正执行，`UPDATE` 上要套事务**）
- 读懂 `cost=startup..total rows= width=` 与 `actual time=.. rows=.. loops=`
- **`rows` 估算和 `actual rows` 差一个数量级 = 统计信息过期或选择性误判**
- 扫描方式：`Seq Scan` / `Index Scan` / `Index Only Scan` / `Bitmap Heap Scan` /
  `Bitmap Index Scan`（**Bitmap 是「先攒行号再批量回表」，理解它就知道为什么
  `IN` 多值有时走 Bitmap 而不是 Index Scan**）
- 连接算法：`Nested Loop` / `Hash Join` / `Merge Join` —— 各自适用规模
- 统计信息与 `ANALYZE`、`pg_statistic`、`EXPLAIN (ANALYZE, BUFFERS)`
- **交付物：执行计划速查卡**（一页纸，见附录 D）—— 这个别省，三个月后你会感谢自己

### 第 9 周：百万行索引实验
- 造 100 万行数据（`generate_series` 最快；对比 `COPY` 批量导入速度）
- 同一查询加索引前后耗时对比，**必须记录**：
  - 耗时（`\timing` 或 `EXPLAIN ANALYZE` 的 `Execution Time`）
  - 执行计划变化（前后各贴一次计划）
  - `Buffers` 差异（读了多少页）
- **【本次新增】反例实验**：给低选择性的列建索引，观察优化器**拒绝使用**它
- **交付物**：**带数字的实验表格**（Markdown 表格，含查询、加索引前耗时、加索引后
  耗时、扫描方式、加速比），存为 `experiment_index.md`

### 第 10 周：事务与隔离级别
- ACID 的真实含义（**尤其是「隔离性」到底隔离什么**）
- `BEGIN` / `COMMIT` / `ROLLBACK` / `SAVEPOINT` / 嵌套事务的真相（PG 没有真嵌套）
- 四种隔离级别；**PostgreSQL 默认 Read Committed**
- 异常现象：脏读 / 不可重复读 / 幻读 / **丢失更新** / 写偏斜（知道名词即可）
- MVCC 直觉：为什么读不阻塞写、**为什么长事务会让表膨胀（bloat）**
- **动手**：开两个 `psql` 窗口，手工制造一次「不可重复读」，再切到
  `REPEATABLE READ` 观察现象消失
- **交付物**：一份「隔离级别 vs 异常现象」对照表 + 两个终端的实验记录

### 第 11 周：锁与并发控制
- 锁粒度：行锁 / 表锁 / 意向锁 / 页级锁；`pg_locks` 怎么看
- `SELECT ... FOR UPDATE` / `FOR NO KEY UPDATE` / `FOR SHARE` / `SKIP LOCKED`
  （**`SKIP LOCKED` 是任务队列的经典实现，很实用**）
- 死锁成因（**两个事务以相反顺序获取同一组锁**）与避免策略（统一加锁顺序）
- 悲观锁 vs 乐观锁版本号 —— 各自适用场景
- **【核心交付物】亲手复现一次死锁，再消除它**：
  1. 终端 A、B 交叉加锁，观察 PG 报 `deadlock detected` 并自动回滚一方
  2. 查看 `pg_locks` 和日志中的死锁详情
  3. 改成统一加锁顺序，确认死锁消失
  - 全程记录成 `deadlock_lab.md`

### 第 12 周：应用到项目
- 用原生 SQL 重写一段 ORM 查询，**对比执行计划**并解释差异
- SQLAlchemy 中写 `text()`、`bindparam`，以及**什么时候 ORM 会生成 N+1 查询**
- 打开慢查询日志：`log_min_duration_statement = 200`（`ALTER SYSTEM SET ...`）
- 用 `pg_stat_statements` 扩展找出最耗时的查询（**生产环境第一排查手段**）
- `COPY` 批量导入 / 导出、`pg_dump` / `pg_restore` 备份与恢复
- **交付物**：一份「本项目慢查询清单 + 优化前后对比」

---

## 第三阶段：复习与自测（第 13 周）

> 原大纲把「项目应用」和「闭卷复习」塞在第 12 周同一周，五件事挤一周必然都做不透。
> 拆开。

### 第 13 周：闭卷复习
- **闭卷测试**（限时 60 分钟，不给提示、不许查文档）
  - 2 条 `JOIN` 题（含零匹配行的保留）
  - 2 条聚合题（含 `HAVING` 与 `COUNT` 的 NULL 陷阱）
  - 2 条窗口函数题
  - 2 条 CTE / 递归题
  - 2 条日期区间题
- **自检标准**：写完用 `EXPLAIN` 验证，**大表上不应出现 `Seq Scan`**；
  每条查询都能口头解释执行顺序
- 错题本：把写错的题和根因记下来（是语法忘、还是语义理解错）
- 完成后重读一遍本大纲第 4–6 周的加粗项，确认全部内化

---

# 第二部分：RAG 前置扩展（第 14–18 周）

> 这部分对应原大纲「RAG 阶段要用」的落点。原大纲只在理由里提了全文检索，
> 但 12 周计划里一次都没讲 —— 这里补上。

### 第 14 周：全文检索（PostgreSQL 原生）
- `to_tsvector('simple', text)` / `to_tsquery` / `plainto_tsquery` / `websearch_to_tsquery`
- **`tsvector` 的存储方式**：生成列（`GENERATED ALWAYS AS ... STORED`）vs 触发器维护
- **GIN 索引**（第 7 周只见过名词，这里实操）：`CREATE INDEX ... USING GIN (tsv)`
- 排名：`ts_rank` / `ts_rank_cd`，`ts_headline` 生成高亮片段
- **中文分词问题**：`simple` 配置对中文只按空格切；方案对比——
  `pg_jieba` / `zhparser` 扩展 vs 应用层分词后写入
- `pg_trgm` 扩展：`%` 相似度、`similarity()`、GIN trgm 索引支持 `LIKE '%x%'`
  （**模糊查询走索引的关键，很实用**）
- **交付物**：给 `kb_documents` 加全文检索，实现「关键词召回 Top 10 + 高亮片段」

### 第 15 周：pgvector 与向量检索
- 装 `pgvector` 扩展（ZIP 版需要自己编译或用带扩展的镜像 —— **这就是第 7 周后
  切 Docker 的实际理由**）
- `vector` 类型、维度约束、`CREATE EXTENSION vector`
- 距离算子：`<->` L2 / `<#>` 内积 / `<=>` 余弦距离
- 索引：**HNSW** vs **IVFFlat**（构建速度、召回率、内存占用的三角权衡）
- 混合检索雏形：全文检索 + 向量检索的加权融合
- **交付物**：`chunks` 表（分块 + 向量 + 元数据），能查「最相似的 5 个分块」

### 第 16–18 周：向 RAG 过渡
> 这部分已超出纯 SQL 范围，此处仅占位，等 SQL 部分收尾后再细化。

- 第 16 周：文档分块策略与元数据建模（chunk 表设计、文档-分块一对多）
- 第 17 周：混合检索 + 重排序的数据层实现
- 第 18 周：会话/消息表设计、检索日志与评估

---

# 附录

## A. 核心心智模型（必须内化，其余可查）

**1. 书写顺序 ≠ 执行顺序**

```
写法：SELECT → FROM → JOIN → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT
执行：FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT
```

这一条能解释 80% 的困惑：
- 为什么 `WHERE` 里不能用 `SELECT` 的别名（WHERE 先执行，别名还不存在）
- 为什么窗口函数不能写在 `WHERE` 里（SELECT 阶段才算出来）
- 为什么 `HAVING` 能用聚合结果而 `WHERE` 不能
- 为什么 `LEFT JOIN` 后 `COUNT(*)` 对不匹配行返回 1（JOIN 阶段就补了 NULL 行）

**2. NULL 三值逻辑** —— `NULL = NULL` 是 `unknown`，不是 `true`。任何含 NULL 的
比较都可能让整行消失。`NOT IN` 遇 NULL 返回空集是它的直接推论。

**3. 索引不是免费的** —— 每个索引都在为读加速的同时为写收费。

## B. 必须亲手复现的 5 个「坑」

| # | 坑 | 复现方式 | 周次 |
|---|---|---|---|
| 1 | `NOT IN` 遇 NULL 返回空集 | 含 NULL 的列做 `NOT IN` 子查询 | 6 |
| 2 | `LEFT JOIN` 条件是 `ON` 还是 `WHERE` | 零订单用户查询两种写法 | 5 |
| 3 | 字符串拼接导致 SQL 注入 | 拼接 vs 参数化对比 | 3 |
| 4 | 长事务导致表膨胀 | 开着事务不提交，另开会话反复更新 | 10 |
| 5 | 死锁 | 两终端交叉加锁 | 11 |

## C. 交付物清单（每完成一项打勾）

- [ ] `schema.sql` —— 博客表结构，可重复执行
- [ ] `load_notes.py` —— Python + psycopg 导入脚本
- [ ] `kb_queries.sql` —— 第 6 周里程碑 6 条查询
- [ ] `experiment_index.md` —— 百万行索引实验数字表格
- [ ] `explain_cheatsheet.md` —— 执行计划速查卡
- [ ] `deadlock_lab.md` —— 死锁复现与消除记录
- [ ] `slow_query_report.md` —— 慢查询清单 + 优化对比
- [ ] 闭卷测试错题本

## D. 执行计划速查卡（第 8 周产出，此处为模板）

| 计划节点 | 意味着什么 | 什么时候是问题 |
|---|---|---|
| `Seq Scan` | 全表顺序扫描 | 大表 + 有可用索引时 |
| `Index Scan` | 走索引 + 回表 | 一般正常 |
| `Index Only Scan` | 索引里就有全部数据，不回表 | 理想状态 |
| `Bitmap Index Scan` + `Bitmap Heap Scan` | 先攒行号位图再批量回表 | 返回行数多时优于 Index Scan |
| `Nested Loop` | 外层每行扫一次内层 | 外层行数大时灾难 |
| `Hash Join` | 小表建哈希表探测大表 | 大表连接常用 |
| `Merge Join` | 两侧已排序归并 | 有排序索引时高效 |
| `Sort` / `Sort Method: external merge` | 排序 / **落磁盘排序** | 出现 `external` 说明 `work_mem` 不够 |

**判断法则**：`rows=` 估算值与 `actual rows=` 差 > 10 倍 → 先 `ANALYZE`，再怀疑
选择性估算，最后才考虑改索引。

## E. 参考资料

- PostgreSQL 官方文档（**唯一权威，中文教程多为二手**）：https://www.postgresql.org/docs/current/
- Use The Index, Luke（索引与查询优化，免费在线）：https://use-the-index-luke.com/
- PostgreSQL 版本支持策略：https://www.postgresql.org/support/versioning/
- pgvector 仓库：https://github.com/pgvector/pgvector
- Windows 免安装二进制（EDB）：https://www.enterprisedb.com/download-postgresql-binaries

---

## 与原大纲的差异（v1 → v2）

| # | 改动 | 原因 |
|---|---|---|
| 1 | 新增第 0 步环境方案对比（ZIP / Docker / Installer） | 原大纲默认 Docker，实际非必需 |
| 2 | 第 2 周补「数据建模」 | 原大纲只讲类型和约束，没讲怎么把需求变表 |
| 3 | 第 3 周补 `psycopg` + SQL 注入实验 | 原大纲第 12 周才碰 Python，太晚 |
| 4 | 第 4 周日期函数展开 | RAG 高频用「最近 N 天」，原大纲一句带过 |
| 5 | 新增第 6 周里程碑「迷你知识库」 | 原大纲前 11 周无产出，动力易断 |
| 6 | 新增第 14 周全文检索 | 原大纲在理由里提了全文检索，计划里却没有 |
| 7 | 新增第 15 周 pgvector | 明确 RAG 落点，同时解释「为何要切 Docker」 |
| 8 | 第 12 周拆出第 13 周复习 | 原第 12 周五件事挤一周，且闭卷标准模糊 |
| 9 | 每周增加「交付物」 | 原大纲只有第 9、11、12 周有交付物 |
| 10 | 新增附录 A–E | 心智模型、必踩坑、交付物清单、速查卡模板 |
| 11 | 锁定版本 PostgreSQL 18 | 原大纲未指定版本；13 及以下已 EOL |
| 12 | 新增低选择性索引反例实验（第 9 周） | 只验证「加索引变快」会形成错误认知 |
