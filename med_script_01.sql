use med_bea_kb;


DROP TABLE IF EXISTS project_details_init;
CREATE TABLE project_details_init
(
    projectid                 INT AUTO_INCREMENT PRIMARY KEY COMMENT '项目ID: 每个项目的唯一标识符',
    projectname               varchar(100) comment '项目名称',
    schemeintroduction        text comment '方案介绍: 关于项目方案的详细描述',
    shortcomings              text comment '项目缺点',
    effectiveness             text comment '项目功效',
    sideeffect                text comment '项目副作用',
    suitablepopulation        text comment '适宜人群: 描述哪些人群适合这个方案',
    contraindicatedpopulation text comment '禁忌人群: 描述哪些人群不适合这个方案',
    schemecomparison          text comment '方案对比: 与其他方案的对比分析',
    treatmentexplanation      text comment '治疗说明: 如果涉及治疗，该字段说明治疗的细节',
    postoperativecare         text comment '术后护理',
    question1                 text comment '问题1: 记录一个特定的常见问题',
    answer1                   text comment '回答1: 对问题1的回答',
    commonquestion            text comment '常见问题: 记录关于项目的其他常见问题',
    answer                    text comment '回答: 对常见问题的回答'
);



select *
from project_details_init
where answer = '';

##
update project_details_init
set Answer = Answer1
where Answer = '';


create table project_details_merge
select *
from project_details_init;

ALTER TABLE project_details_merge
    ADD commonQuestionsJSON JSON,
    ADD answersJSON         JSON;


UPDATE project_details_merge
SET commonQuestionsJSON = (SELECT JSON_ARRAYAGG(commonQuestion)
                           FROM (SELECT * FROM project_details_merge) AS TempTable
                           WHERE TempTable.projectname = project_details_merge.projectname),
    answersJSON         = (SELECT JSON_ARRAYAGG(Answer)
                           FROM (SELECT * FROM project_details_merge) AS TempTable
                           WHERE TempTable.projectname = project_details_merge.projectname)
where 1 = 1;


select *
from project_details_merge;

ALTER TABLE project_details_merge
    ADD COLUMN qa_json JSON;


UPDATE project_details_merge
SET qa_json = (SELECT JSON_ARRAYAGG(
                              JSON_OBJECT('question', pq.CommonQuestion, 'answer', pq.Answer)
                          )
               FROM (SELECT * FROM project_details_merge) pq
               WHERE pq.ProjectName = project_details_merge.ProjectName)
where 1 = 1;


create table project_details_end
select *
from project_details_merge;


ALTER TABLE project_details_end
    drop column question1,
    drop column answer1,
    drop column commonquestion,
    drop column answer,
    drop column answersjson,
    drop column commonquestionsjson;


select ProjectName, MAX(ProjectID) as ProjectID
from project_details_end
group by ProjectName;


DELETE t1
FROM project_details_end t1
         JOIN (select ProjectName, MAX(ProjectID) as ProjectID
               from project_details_end
               group by ProjectName) t2
              ON t1.ProjectID != t2.ProjectID
                  AND t1.ProjectName = t2.ProjectName;


select ProjectName               as 项目名称,
       SchemeIntroduction        as 方案介绍,
       SuitablePopulation        as 适宜人群,
       shortcomings              as '项目缺点',
       effectiveness             as '项目功效',
       sideeffect                as '项目副作用',
       ContraindicatedPopulation as 禁忌人群,
       SchemeComparison          as 方案对比,
       TreatmentExplanation      as 治疗说明,
       postoperativecare         as 术后护理,
       QA_JSON                   as 常见问题
from project_details_end;


