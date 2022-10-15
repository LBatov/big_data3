
--Данные предварительно положил в хдфс 

DROP TABLE IF EXISTS lastfm_raw;
CREATE EXTERNAL TABLE IF NOT EXISTS lastfm_raw(
    mbid STRING,
    artist_mb STRING,
    artist_lastfm STRING,
    country_mb STRING,
    country_lastfm STRING,
    tags_mb STRING,
    tags_lastfm STRING,
    listeners_lastfm STRING,
    scrobbles_lastfm STRING,
    ambiguous_artis STRING
)
  ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
    WITH SERDEPROPERTIES (
       "separatorChar" = ","
    )
  STORED AS TEXTFILE
  LOCATION '/user/hive/warehouse/ext/lastfm/'
  TBLPROPERTIES ("skip.header.line.count"="1");
  
create table last_fm(
    mbid STRING,
    artist_mb STRING,
    artist_lastfm STRING,
    country_mb STRING,
    country_lastfm STRING,
    tags_mb array<string>,
    tags_lastfm array<string>,
    listeners_lastfm int,
    scrobbles_lastfm int,
    ambiguous_artis STRING
)
stored as ORC;

insert into last_fm
select 
    mbid ,
    artist_mb ,
    artist_lastfm ,
    country_mb ,
    country_lastfm ,
    split(tags_mb, ';'),
    split(tags_lastfm, ';'),
    cast(listeners_lastfm as int),
    cast(scrobbles_lastfm as int),
    ambiguous_artis 
from lastfm_raw;



1) Больше всего скробблов у he Beatles
select l.artist_lastfm,l.scrobbles_lastfm  from last_fm l order by l.scrobbles_lastfm desc limit 1;

 --The Beatles	517126254

2) Популярный тэг: seen live	встретился 81394 раз

select TagName, count(*) c  from last_fm l
LATERAL VIEW explode(tags_lastfm) tagz AS TagName
where tagname <> ''
group by TagName
order by c desc limit 1;

-- seen live	81394

3) Топ 10 тэгов с исполнителями

with exploded as 
(
select  TagName, artist_lastfm,  listeners_lastfm  from last_fm l
LATERAL VIEW explode(tags_lastfm) tagz AS TagName
where tagname <> ''
),
top_tags as (
select TagName, count(*) c from exploded group by TagName order by c desc limit 10
) 
select * 
from 
(
    select 
        ex.tagname
        , ex.artist_lastfm
        , row_number() over (partition by ex.tagname order by listeners_lastfm desc) rn
        , listeners_lastfm
    from exploded ex
    join top_tags tg on ex.tagname = tg.tagname 
) t0
where rn = 1;
/*
t0.tagname	        t0.artist_lastfm	t0.rn	t0.listeners_lastfm
All	                    Jason Derülo		1	    1872933
alternative	            Coldplay	    	1	    5381567
electronic	            Coldplay	    	1	    5381567
experimental	        Radiohead	    	1	    4732528
female vocalists	    Rihanna	        	1	    4558193
indie	                Coldplay	    	1	    5381567
pop	                    Coldplay	    	1	    5381567
rock	                Radiohead	    	1	    4732528
seen live	            Coldplay			1		5381567
under 2000 listeners	Diddy - Dirty Money	1		503188*/

4) Есть случаи? когда теги встречаются по несколько раз у одного исполнителя, но происходит это редко и на результат не влияет.

select mbid,artist_lastfm, TagName, count(*) c  from last_fm l
LATERAL VIEW explode(tags_lastfm) tagz AS TagName
where tagname <> ''
group by mbid, artist_lastfm, TagName
order by c desc limit 10;


/*
mbid	                                artist_lastfm	tagname     	c
0f44b3bd-ba69-4c2e-9165-f97ced47f67f	Fat Tulips	    Twee	        5
0f44b3bd-ba69-4c2e-9165-f97ced47f67f	Fat Tulips	    Nottingham	    5
0942098d-71a2-48de-89c4-df635c02e04e	Sonny Fisher	50s	            2
05c30124-8117-41c9-90f2-5271ed69cc53	Filth	        beatdown	    2
ffc6e5c1-bce9-42f6-8fb6-319b6cb56763	Breach The Void	metal	        2
0e680488-516c-422d-b08d-19e2e37ea1ff	Phantom	        50s	            2
0c30f358-5e4b-4135-85bd-8e1b2940588e	Planks	        post metal      2
0404fdd9-b36f-45aa-9756-d7cb8b2ef4f9	Commonwealth    Jones	50s	    2
0e93c2eb-77e2-4cbf-b039-3a956debed04	Cherokee	    heavy metal	    2
fe510fc7-60aa-4006-9497-1bca204ae6da	Don Wade	    50s	            2

*/