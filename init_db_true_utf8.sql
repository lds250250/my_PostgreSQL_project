-- =============================================================
-- init_db.sql 鈥斺€?閲嶅缓瀛︿範鐢ㄧ殑鏁版嵁搴撶幆澧?
--
-- 鍙噸澶嶆墽琛岋細涓嶇鐜板湪浠€涔堢姸鎬侊紝璺戝畬閮藉緱鍒板悓涓€涓粨鏋溿€?
-- 闈犱粈涔堝仛鍒帮細寮€澶寸殑 DROP ... IF EXISTS 鎶婃棫鐨勬媶骞插噣锛屽悗闈㈠叏鍦ㄧ┖鐜涓婂缓銆?
-- 锛堟墍浠?CREATE TABLE 鐨?IF NOT EXISTS 鍙槸淇濋櫓锛岀湡姝ｈ捣浣滅敤鐨勬槸寮€澶寸殑 DROP锛?
--
-- 鎬庝箞璺戯紙蹇呴』鐢ㄨ秴绠★紝鍥犱负瑕佸缓瑙掕壊鍜屽簱锛夛細
--   浠庡闈㈣窇锛歱sql -U postgres -h 127.0.0.1 -f init_db.sql
--   杩涗簡 psql 鍐嶈窇锛歕i init_db.sql    锛堣窇瀹屼細鍋滃湪 learn_sql 閲岋級
-- =============================================================

\encoding UTF8

-- 绗?1 娈碉細鎶婃棫鐨勫叏閮ㄦ媶鎺夛紙椤哄簭涓嶈兘鍙嶏紒锛?
-- DROP DATABASE 蹇呴』鍦?娌℃湁鍒汉杩炵潃瀹?鏃舵墠鑳芥垚鍔?
DROP DATABASE IF EXISTS learn_sql;

-- 瑙掕壊涔熻鎷嗐€傛敞鎰忛『搴忥細搴撶殑 owner 鏄?learn_user锛?
-- 鎵€浠ュ繀椤诲厛鍒犲簱銆佸啀鍒犺鑹?鈥斺€?鍙嶄簡浼氳鎷掔粷锛堣繕鏈夊璞′緷璧栧畠锛?
DROP ROLE IF EXISTS learn_user;

-- 绗?2 娈碉細寤鸿鑹?
-- 娉ㄦ剰锛欳REATE ROLE 娌℃湁 IF NOT EXISTS锛屾墍浠?鍙噸澶?闈犵殑鏄笂闈㈤偅鍙?DROP
CREATE ROLE learn_user LOGIN PASSWORD 'learn_pass';

-- 绗?3 娈碉細寤哄簱
-- OWNER 鎸囧畾鐨勮鑹插繀椤诲凡缁忓瓨鍦?鈥斺€?杩欏氨鏄 2 娈靛繀椤诲湪绗?3 娈靛墠闈?
CREATE DATABASE learn_sql OWNER learn_user;

-- 绗?4 娈碉細鍒囧埌鏂板簱閲?
-- \c 鏄?psql 鐨勫厓鍛戒护锛屼笉甯﹀垎鍙?
\c learn_sql

-- 绗?5 娈碉細寤鸿〃
-- 娉ㄦ剰锛氫笅闈㈣繖浜涢兘鍙戠敓鍦?learn_sql 搴撻噷浜?
CREATE TABLE IF NOT EXISTS notes (
    -- id = 姣忔潯绗旇鐨勫敮涓€缂栧彿
    -- BIGSERIAL 鏄?鑷姩寰€涓婂姞鐨勫ぇ鏁存暟"
    id BIGSERIAL PRIMARY KEY,

    -- title = 鏍囬锛屼笉鑳界暀绌?
    title TEXT NOT NULL,

    -- body = 姝ｆ枃锛屽彲浠ュ緢闀?
    body TEXT,

    -- created_at = 鍒涘缓鏃堕棿锛屽甫鏃跺尯锛圖ay 7 缁嗚涓轰粈涔堝繀椤诲甫锛?
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
\dt
SELECT count(*) AS 琛屾暟 FROM notes;
-- 绗?6 娈碉細寤虹储寮?
-- 璁?鎸夋爣棰樻悳"鍙樺揩
CREATE INDEX IF NOT EXISTS notes_title_idx ON notes (title);

-- 绗?7 娈碉細濉炰袱鏉＄ず渚嬫暟鎹?
INSERT INTO notes (title, body) VALUES
    ('绗竴鏉＄瑪璁?, '杩欐槸閲嶅缓鑴氭湰濉炶繘鏉ョ殑'),
    ('绗簩鏉＄瑪璁?, '姣忔璺戣剼鏈紝杩欎袱琛岄兘鏄噸鏂版彃鍏ョ殑');

-- 绗?8 娈碉細鑷 鈥斺€?搴旇鐪嬪埌 notes 琛ㄥ拰瀹冮噷闈㈢殑涓よ
-- 鑷锛氬簲璇ョ湅鍒?notes 琛ㄥ拰瀹冮噷闈㈢殑涓よ
\dt

-- 鍥涘垪閮界湅锛歜ody 鏈夊€硷紝created_at 鏄嚜鍔ㄥ～鐨勶紙INSERT 閲屾病缁欏畠锛?
SELECT * FROM notes ORDER BY id;

-- 鍐嶇湅涓€鐪肩粨鏋勶細\d 鍛婅瘔浣犺繖寮犺〃"鍏佽"瀛樹粈涔?
\d notes