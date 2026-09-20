# SQL → RAG 学习排期

> **这份文件是什么**：`教学/学习大纲-SQL与RAG.md` 的**每日排期**，不是课程内容本身。
> 这里只有「每天学什么主题」，每天的内容按 `教学/如何教我.md` 的六个环节单独讲。

## 一、总览

| 阶段 | 周 | Day | 内容 |
| --- | --- | --- | --- |
| 准备 | — | 第 0 课 | git、环境、生词本（见 `课程/第1周/第0课.md`） |
| 一、语法与建模 | 第 1–6 周 | Day 1–44 | psql 上手 → 类型建模 → 增删改 → 查询 → JOIN → 聚合窗口 |
| 二、原理与并发 | 第 7–13 周 | Day 45–102 | 索引 → 执行计划 → 百万行实验 → 事务 → 锁 → 项目 → 闭卷 |
| 三、RAG 前置 | 第 14–16 周 | Day 103–122 | 全文检索 → **Docker** → pgvector |
| 四、向 RAG 过渡 | 第 17–19 周 | **未排** | 待 SQL 收尾后细化 |

**已排期 16 周 = 122 天**（Day 1–122）。第 17–19 周只有周主题，等第 16 周做完再拆到天。

## 二、每日排期

### 第 1 周：环境与 psql 上手（6 天）

| 天 | 主题 |
| --- | --- |
| **周** | 把 PostgreSQL 跑起来，用 `psql` 连上去并看懂它 |
| Day 1 | 环境三选一（ZIP / Docker / Installer），跑通 `initdb` + `pg_ctl` + 第一条 `SELECT version()` ✅ 产出 `课程/第1周/第1课.md`、`速查/PostgreSQL速查.md` |
| Day 2 | `psql` 交互界面完整上手：不带 `-c` 进去一直敲，`\l` `\c` `\dt` `\d` 各用一遍；连接排查：`-U -h -d -p` 每个故意敲错一次，把报错收集齐 |
| Day 3 | 建库建角色：`CREATE DATABASE` / `CREATE ROLE` / `GRANT` / `REVOKE` / 最小权限 |
| Day 4 | 数据目录结构：`base/` `pg_wal/` `postgresql.conf` `pg_hba.conf` 各管什么 |
| Day 5 | `\?` 和 `\h SELECT` 自查帮助、`\e` 写多行、`\i` 执行脚本、`\timing` / `\x` |
| Day 6 | 综合实战：把库删掉，用脚本从零重建一次（产出 `init_db.sql`） |

> **Day 2 改过（2026-09-20）**：原主题和 Day 1 重叠 —— 连接参数第 1 课已讲过一半，读报错的方法也教过了。改成：已懂的不重讲，交互界面和元命令升成主场，连接参数降成「排查练习」的材料。第 1 周天数没动，后面排期不受影响。

### 第 2 周：数据类型、建表与数据建模（8 天）

| 天 | 主题 |
| --- | --- |
| **周** | 学会把「需求」变成「表结构」，并知道每列该用什么类型 |
| Day 7 | 类型选择（上）：`NUMERIC` 存金额、`TIMESTAMPTZ` 带时区、`TEXT` vs `VARCHAR` |
| Day 8 | 类型选择（下）：`UUID` vs `BIGSERIAL` 主键、`JSONB` 什么时候该用 |
| Day 9 | DDL：`CREATE TABLE` / `ALTER TABLE` / `DROP TABLE` / `IF NOT EXISTS` |
| Day 10 | 约束（上）：`NOT NULL` / `DEFAULT` / `UNIQUE` / `CHECK` |
| Day 11 | 约束（下）：`PRIMARY KEY` / `FOREIGN KEY`，以及级联 `ON DELETE CASCADE` / `RESTRICT` / `SET NULL` |
| Day 12 | 数据建模（上）：一对多外键放哪边、多对多为什么必须有中间表 |
| Day 13 | 数据建模（下）：反范式的时机与代价 —— 什么时候故意冗余 |
| Day 14 | 综合实战：建博客库（用户 / 文章 / 标签 / 评论），产出 `schema.sql` + ER 图 |

### 第 3 周：增删改、upsert 与 Python 连接（8 天）

| 天 | 主题 |
| --- | --- |
| **周** | 会写数据进去，并能用 Python 程序写进去 |
| Day 15 | `INSERT`：单行、多行、`INSERT ... SELECT` |
| Day 16 | `INSERT ... ON CONFLICT DO UPDATE`（upsert）与 `EXCLUDED` 伪表 |
| Day 17 | `UPDATE` / `DELETE` / `RETURNING` |
| Day 18 | `TRUNCATE` vs `DELETE`：锁、事务、能不能回滚 |
| Day 19 | **Python 环境与 `uv`**：装 `uv`、建项目、`uv add` / `uv run`、`.venv` 是什么 |
| Day 20 | Python 连接（上）：装 `psycopg`，连接、执行、取结果 |
| Day 21 | Python 连接（下）：**参数化查询** —— 亲手写一次 SQL 注入，再改成参数化修好 |
| Day 22 | 综合实战：写 `load_notes.py`，批量 upsert Markdown 笔记，重复跑不产生重复行 |

### 第 4 周：查询基础与 NULL 语义（7 天）

| 天 | 主题 |
| --- | --- |
| **周** | 会「按条件挑数据」，并搞懂 NULL 这个最大的坑 |
| Day 23 | `SELECT` / `DISTINCT` / `DISTINCT ON` / 别名 |
| Day 24 | `WHERE` 运算符：`BETWEEN` `IN` `LIKE` `ILIKE` `IS DISTINCT FROM` |
| Day 25 | `ORDER BY` / `NULLS FIRST|LAST` / `LIMIT OFFSET` / `FETCH FIRST` |
| Day 26 | **NULL 三值逻辑（上）**：`NULL = NULL` 为什么是 `unknown`，`IS NULL` 怎么用 |
| Day 27 | **NULL 三值逻辑（下）**：`COALESCE` / `NULLIF`；为什么 `<> 'x'` 会漏掉 NULL 行 |
| Day 28 | `CASE WHEN`（简单 vs 搜索）与 `CAST` / `::` |
| Day 29 | 综合实战：字符串与日期函数查表 + 10 条查询，含 2 条日期区间 |

### 第 5 周：JOIN 全套（6 天）

| 天 | 主题 |
| --- | --- |
| **周** | 会从多张表拼出结果，并搞懂 LEFT JOIN 最容易写错的地方 |
| Day 30 | `INNER JOIN` 与 `LEFT JOIN` 基础 |
| Day 31 | `RIGHT` / `FULL OUTER` / `CROSS JOIN` |
| Day 32 | **`ON` 与 `WHERE` 在 `LEFT JOIN` 中的差异**（零订单用户那个经典题） |
| Day 33 | 自连接：同一张表当两张表用（员工-经理、评论-父评论）；`USING (col)` |
| Day 34 | 反连接三种写法：`LEFT JOIN ... IS NULL` / `NOT EXISTS` / `NOT IN` |
| Day 35 | 综合实战：产出「`ON` vs `WHERE` 两种写法结果对比表」 |

### 第 6 周：聚合、子查询、CTE 与窗口函数（9 天）

| 天 | 主题 |
| --- | --- |
| **周** | 从「查出行」升级到「算统计」 |
| Day 36 | `GROUP BY` 与 `HAVING` |
| Day 37 | `COUNT(*)` vs `COUNT(col)` vs `COUNT(DISTINCT)`；`UNION ALL` vs `UNION` |
| Day 38 | 子查询（上）：标量、`IN`、派生表 |
| Day 39 | 子查询（下）：`EXISTS` / `NOT EXISTS` / `LATERAL` |
| Day 40 | **`NOT IN` 遇 NULL 返回空集** —— 亲手复现，再用 `NOT EXISTS` 修好 |
| Day 41 | `WITH` 与 `WITH RECURSIVE`（评论盖楼、组织架构） |
| Day 42 | 窗口函数（上）：`OVER (PARTITION BY ...)`、`ROW_NUMBER` / `RANK` / `DENSE_RANK` |
| Day 43 | 窗口函数（下）：`LAG` / `LEAD` / `SUM() OVER` 累计与移动窗口 |
| Day 44 | **里程碑**：迷你知识库 —— 6 条查询全部跑通，产出 `kb_queries.sql` |

### 第 7 周：索引原理（10 天）

> **全课程最重的一周。** 也是后面三年最常用的技能，宁可多花三天。

| 天 | 主题 |
| --- | --- |
| **周** | 搞懂索引为什么快、什么时候快不起来、代价是什么 |
| Day 45 | **先建立基线**：造 100 万行，量一次没索引有多慢（先撞上问题） |
| Day 46 | B+ 树直觉：为什么范围查询快、为什么写入变慢 |
| Day 47 | 索引类型（一）：B-tree —— 默认的那个，为什么是默认 |
| Day 48 | 索引类型（二）：Hash 与 BRIN —— 各自只擅长一件事 |
| Day 49 | 索引类型（三）：GIN 与 GiST —— 数组、JSONB、全文检索靠谁 |
| Day 50 | 复合索引与**最左前缀**：`(a, b, c)` 能加速哪些、不能加速哪些 |
| Day 51 | 覆盖索引、`INCLUDE` 列、`Index Only Scan` 的前提 |
| Day 52 | 索引选择性：为什么给「性别」建索引毫无意义 |
| Day 53 | 部分索引与表达式索引：`WHERE deleted_at IS NULL`、`lower(email)` |
| Day 54 | 综合实战：给 `kb_documents` 设计索引方案，说清每条服务于哪个查询 |

### 第 8 周：执行计划与 EXPLAIN（10 天）

> **第二大重的一周。** 「读懂体检报告」是排查一切性能问题的起点。

| 天 | 主题 |
| --- | --- |
| **周** | 学会看数据库的「体检报告」，知道它为什么这么干 |
| Day 55 | `EXPLAIN` vs `EXPLAIN ANALYZE`（后者会真执行，`UPDATE` 上要套事务） |
| Day 56 | 读懂 `cost` / `rows` / `width` / `actual time` / `loops` |
| Day 57 | 扫描方式（一）：`Seq Scan` 与 `Index Scan` |
| Day 58 | 扫描方式（二）：`Index Only Scan` 及其前提（visibility map） |
| Day 59 | 扫描方式（三）：`Bitmap Index Scan` + `Bitmap Heap Scan` |
| Day 60 | 连接算法（一）：`Nested Loop` —— 什么时候是灾难 |
| Day 61 | 连接算法（二）：`Hash Join` 与 `Merge Join` |
| Day 62 | 统计信息与 `ANALYZE`；`EXPLAIN (ANALYZE, BUFFERS)` 看读了多少页 |
| Day 63 | 综合实战（上）：把前 8 天的计划逐个对着读一遍 |
| Day 64 | 综合实战（下）：产出**执行计划速查卡** `explain_cheatsheet.md` |

### 第 9 周：百万行索引实验（7 天）

| 天 | 主题 |
| --- | --- |
| **周** | 不看感觉，只看数字 —— 这一周的产出是表格，不是结论 |
| Day 65 | 造 100 万行数据：`generate_series` vs `COPY`，量导入速度 |
| Day 66 | 测量基线：记录未加索引的耗时、执行计划、`Buffers` |
| Day 67 | 加单列索引，再测一遍，记录前后对比 |
| Day 68 | 加复合索引，测最左前缀的成立与失效 |
| Day 69 | 覆盖索引实验：`Index Only Scan` 到底快多少 |
| Day 70 | **反例实验**：给低选择性列建索引，看优化器拒绝使用它 |
| Day 71 | 综合实战：产出 `experiment_index.md`（含查询、前后耗时、扫描方式、加速比） |

### 第 10 周：事务与隔离级别（7 天）

| 天 | 主题 |
| --- | --- |
| **周** | 搞懂「两个人同时改同一条数据」会发生什么 |
| Day 72 | ACID 的真实含义；`BEGIN` / `COMMIT` / `ROLLBACK` |
| Day 73 | `SAVEPOINT`；PostgreSQL 为什么没有真正的嵌套事务 |
| Day 74 | 四种隔离级别，PostgreSQL 默认 `Read Committed` |
| Day 75 | 四种异常现象：脏读 / 不可重复读 / 幻读 / 丢失更新 |
| Day 76 | 动手：两个窗口制造一次「不可重复读」，再切 `REPEATABLE READ` 看它消失 |
| Day 77 | MVCC 直觉：为什么读不阻塞写 |
| Day 78 | 综合实战：产出「隔离级别 vs 异常现象」对照表 + 实验记录 |

### 第 11 周：锁与并发控制（8 天）

| 天 | 主题 |
| --- | --- |
| **周** | 搞懂「谁在等谁」，并能亲手制造和消除一次死锁 |
| Day 79 | 锁粒度：行锁 / 表锁 / 意向锁；用 `pg_locks` 看当前锁 |
| Day 80 | `SELECT ... FOR UPDATE` / `FOR NO KEY UPDATE` / `FOR SHARE` |
| Day 81 | `SKIP LOCKED`：任务队列的经典实现 |
| Day 82 | 死锁成因：两个事务以相反顺序抢同一组锁 |
| Day 83 | **亲手复现一次死锁**，看报错 `deadlock detected`，读日志 |
| Day 84 | 消除死锁：统一加锁顺序 |
| Day 85 | 悲观锁 vs 乐观锁版本号 —— 各自适用场景 |
| Day 86 | 综合实战：产出 `deadlock_lab.md`（复现 + 消除全过程） |

### 第 12 周：应用到项目（7 天）

| 天 | 主题 |
| --- | --- |
| **周** | 把前 11 周的东西用到真实代码上 |
| Day 87 | 用原生 SQL 重写一段 ORM 查询，对比执行计划 |
| Day 88 | SQLAlchemy 的 `text()` / `bindparam`；ORM 的 N+1 查询什么时候出现 |
| Day 89 | 打开慢查询日志：`log_min_duration_statement` |
| Day 90 | `pg_stat_statements` 扩展：找出最耗时的查询 |
| Day 91 | `COPY` 批量导入导出 |
| Day 92 | `pg_dump` / `pg_restore` 备份与恢复 |
| Day 93 | 综合实战：产出「慢查询清单 + 优化前后对比」 |

### 第 13 周：闭卷复习（6 天）

| 天 | 主题 |
| --- | --- |
| **周** | 不上新内容。只看自己是不是真的会了 |
| Day 94 | 复习：JOIN 与 NULL 语义（重读大纲第 4–5 周加粗项） |
| Day 95 | 复习：聚合、子查询、CTE、窗口函数 |
| Day 96 | 复习：索引原理与执行计划 |
| Day 97 | 复习：事务、隔离级别、锁 |
| Day 98 | **闭卷测试**：限时 60 分钟，10 条查询（JOIN / 聚合 / 窗口 / CTE / 日期 各 2 条） |
| Day 99 | 讲一遍 + 错题本：不看书用自己的话讲一遍，记下错在哪、根因是什么 |

### 第 14 周：全文检索（8 天）

| 天 | 主题 |
| --- | --- |
| **周** | 让数据库自己会「按关键词找文档」 |
| Day 100 | `to_tsvector` / `to_tsquery` / `plainto_tsquery` / `websearch_to_tsquery` |
| Day 101 | `tsvector` 怎么存：生成列 vs 触发器维护 |
| Day 102 | **GIN 索引**：`CREATE INDEX ... USING GIN (tsv)` |
| Day 103 | 排名与高亮：`ts_rank` / `ts_rank_cd` |
| Day 104 | `ts_headline`：把命中的词标出来给用户看 |
| Day 105 | 中文分词：`simple` 配置的局限，`pg_jieba` / `zhparser` 方案对比 |
| Day 106 | `pg_trgm` 扩展：让 `LIKE '%x%'` 也能走索引 |
| Day 107 | 综合实战：给 `kb_documents` 加全文检索，实现「关键词召回 Top 10 + 高亮片段」 |

### 第 15 周：Docker（7 天）

| 天 | 主题 |
| --- | --- |
| **周** | 把数据库装进一个「随时能删、随时重建」的盒子里 |
| Day 108 | 容器是什么：镜像 vs 容器（用「类和实例」打比方） |
| Day 109 | 在 Windows 上装 Docker Desktop（含 WSL2 后端） |
| Day 110 | 跑第一个 PostgreSQL 容器：`docker run` 各参数含义 |
| Day 111 | 数据卷：为什么容器删了数据还在，怎么故意让数据消失 |
| Day 112 | `docker compose`：把配置写进 `compose.yml` 一键起库 |
| Day 113 | 用 Docker 重做第 9 周实验和第 11 周死锁实验（删卷即回滚） |
| Day 114 | 综合实战：产出 `compose.yml`，能一键重建整个学习库 |

### 第 16 周：pgvector 与向量检索（8 天）

| 天 | 主题 |
| --- | --- |
| **周** | 让 PostgreSQL 会算「两段文字有多像」 |
| Day 115 | 装 pgvector：用 `pgvector/pgvector:pg18` 镜像；`CREATE EXTENSION vector` |
| Day 116 | `vector` 类型、维度约束、写入与 `COPY` 批量导入 |
| Day 117 | 距离算子（一）：`<->` L2 与 `<#>` 内积 |
| Day 118 | 距离算子（二）：`<=>` 余弦；三者选哪个 |
| Day 119 | 精确检索先跑通：`ORDER BY embedding <=> '[...]' LIMIT 5` |
| Day 120 | HNSW 索引：参数 `m` / `ef_construction`，构建时间与召回率 |
| Day 121 | IVFFlat 索引：`lists` / `probes`，和 HNSW 的取舍 |
| Day 122 | 综合实战：建 `chunks` 表（分块 + 向量 + 元数据），能查最相似的 5 个分块 |

### 第 17–19 周：向 RAG 过渡

> **未排期**。这部分内容依赖第 16 周的实际结果，等 SQL 核心收尾后再细化。
> 按大纲 v2：第 17 周文档分块策略与元数据建模，第 18 周混合检索 + 重排序，第 19 周会话表与检索评估。

| 周 | 主题 |
| --- | --- |
| 第 17 周 | 文档分块策略与元数据建模（chunk 表设计、文档-分块一对多） |
| 第 18 周 | 混合检索 + 重排序的数据层实现 |
| 第 19 周 | 会话/消息表设计、检索日志与评估 |

---

## 三、改计划时怎么改

按 `教学/如何教我.md` 的 `8.8 改了计划，三件事一起做`：

1. 当场说一声
2. 写进这份文件
3. **写清为什么改** —— 不是「改成了什么」（表里已经有了），是当时为什么这么判断

**理由比结论活得久。** 三个月后你会问「当初为什么这么排」，而不是「当初排的是什么」。
