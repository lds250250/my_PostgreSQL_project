-- =============================================================
-- init_db.sql —— 重建学习用的数据库环境
--
-- 可重复执行：不管现在什么状态，跑完都得到同一个结果。
-- 靠什么做到：开头的 DROP ... IF EXISTS 把旧的拆干净，后面全在空环境上建。
-- （所以 CREATE TABLE 的 IF NOT EXISTS 只是保险，真正起作用的是开头的 DROP）
--
-- 怎么跑（必须用超管，因为要建角色和库）：
--   从外面跑：psql -U postgres -h 127.0.0.1 -f init_db.sql
--   进了 psql 再跑：\i init_db.sql    （跑完会停在 learn_sql 里）
-- =============================================================

-- 第 1 段：把旧的全部拆掉（顺序不能反！）
-- DROP DATABASE 必须在"没有别人连着它"时才能成功
DROP DATABASE IF EXISTS learn_sql;

-- 角色也要拆。注意顺序：库的 owner 是 learn_user，
-- 所以必须先删库、再删角色 —— 反了会被拒绝（还有对象依赖它）
DROP ROLE IF EXISTS learn_user;

-- 第 2 段：建角色
-- 注意：CREATE ROLE 没有 IF NOT EXISTS，所以"可重复"靠的是上面那句 DROP
CREATE ROLE learn_user LOGIN PASSWORD 'learn_pass';

-- 第 3 段：建库
-- OWNER 指定的角色必须已经存在 —— 这就是第 2 段必须在第 3 段前面
CREATE DATABASE learn_sql OWNER learn_user;

-- 第 4 段：切到新库里
-- \c 是 psql 的元命令，不带分号
\c learn_sql

-- 第 5 段：建表
-- 注意：下面这些都发生在 learn_sql 库里了
CREATE TABLE IF NOT EXISTS notes (
    -- id = 每条笔记的唯一编号
    -- BIGSERIAL 是"自动往上加的大整数"
    id BIGSERIAL PRIMARY KEY,

    -- title = 标题，不能留空
    title TEXT NOT NULL,

    -- body = 正文，可以很长
    body TEXT,

    -- created_at = 创建时间，带时区（Day 7 细讲为什么必须带）
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
\dt
SELECT count(*) AS 行数 FROM notes;
-- 第 6 段：建索引
-- 让"按标题搜"变快
CREATE INDEX IF NOT EXISTS notes_title_idx ON notes (title);

-- 第 7 段：塞两条示例数据
INSERT INTO notes (title, body) VALUES
    ('第一条笔记', '这是重建脚本塞进来的'),
    ('第二条笔记', '每次跑脚本，这两行都是重新插入的');

-- 第 8 段：自检 —— 应该看到 notes 表和它里面的两行
-- 自检：应该看到 notes 表和它里面的两行
\dt

-- 四列都看：body 有值，created_at 是自动填的（INSERT 里没给它）
SELECT * FROM notes ORDER BY id;

-- 再看一眼结构：\d 告诉你这张表"允许"存什么
\d notes