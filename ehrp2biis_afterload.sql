col datetime new_value datetime;
select to_char(sysdate, 'YYYY-MM-DD_HH24-MI-SS') datetime
  from dual;

------ (Step 04)   @C:\EHRP2B\UPDATE_NWK_actsec_RETAINED_STEP   

SPOOL /home/sa-biisint/data/int/log/EHRP2BIIS_UPDATE_AFTERLOAD_&&datetime..log

UPDATE nknight.nwk_action_secondary_tbl a
SET a.retnd1_step_cd = NULL
WHERE a.event_id  IN (SELECT b.event_id
                       FROM nknight.nwk_action_primary_tbl b
                       WHERE b.load_date = trunc(SYSDATE) AND 
                             b.event_id < 9000000000)
AND 
       a.retnd1_step_cd = '0.0000000000000';
COMMIT;


-----  (Step 05)   @C:\EHRP2B\EHRP2BIIS_UPDATE_AFTLOAD;                         

set feedback on
set echo on
set serveroutput on size 1000000
SET PAGESIZE 60
SET TIMING ON

col datetime new_value datetime;
select to_char(sysdate, 'YYYY-MM-DD_HH24-MI-SS') datetime
from dual;


-- SPOOL /home/sa-biisint/data/int/log/EHRP2BIIS_UPDATE_AFTERLOAD_&&datetime..log

Prompt  Display the contents of the sequence number table before sequence number update procedure

Select * from NKNIGHT.SEQUENCE_NUM_TBL 
order by 1;



Prompt Compile and run the procedure to update the sequence numbers before next update!!!!

alter procedure update_sequence_number_tbl_p compile;

execute update_sequence_number_tbl_p;


Prompt Display the contents of the sequence number table after the update.

Select * from NKNIGHT.SEQUENCE_NUM_TBL 
order by 1;


Prompt  Please logon to BIIS and run procedures to complete the formatting of the newly
Prompt  records!!!!!!!!!


EXEC HISTDBA.UPDT_ERP2BIIS_CRE8_REMARKS01_P; 
commit;        

EXEC HISTDBA.UPDATE_ERP2BIIS_NO900S01_p;
commit;

EXEC HISTDBA.ERP2BIIS_CRE8_REMARKS_900s01;
commit;

EXEC HISTDBA.UPDATE_ERP2BIIS_900SONLY01_P;
commit; 

Prompt Just Ran all 4 procedures to format newly loaded records.

EXEC HISTDBA.UPDT_ORIG_CANCELLED_TRANS01_P;
COMMIT;

col datetime new_value datetime;
select to_char(sysdate, 'YYYY-MM-DD_HH24-MI-SS') datetime
  from dual;
set echo on;

PROMPT UPDATE PROCESS_TABLE
PROMPT SET P_STARTDT  = NULL;

UPDATE PROCESS_TABLE
SET P_STARTDT  = NULL;

COMMIT;


PROMPT UPDATE PROCESS_TABLE
PROMPT    SET P_STARTDT = (SELECT effdt 
PROMPT                     FROM (select a.biis_event_id, a.emplid,
PROMPT                                  a.empl_rcd, a.effdt, a.effseq, b.deptid,
PROMPT                                  a.gvt_wip_status "OLD STATUS",
PROMPT                                  b.gvt_wip_status "NEW STATUS"
PROMPT                           from nknight.ehrp_recs_tracking_tbl a, ehrp.ps_gvt_job b
PROMPT                           where a.emplid = b.emplid and
PROMPT                                 a.empl_rcd = b.empl_rcd and
PROMPT                                 a.effdt = b.effdt and
PROMPT                                 a.effseq = b.effseq and
PROMPT                                 a.gvt_wip_status <> b.gvt_wip_status and
PROMPT                                 a.changed_wip_status is null
PROMPT                          order by 4, 1) 
PROMPT                    WHERE ROWNUM < 2);
PROMPT

UPDATE PROCESS_TABLE
       SET P_STARTDT =
  (SELECT effdt FROM
(
select a.biis_event_id, a.emplid,
       a.empl_rcd, a.effdt, a.effseq, b.deptid,
       a.gvt_wip_status "OLD STATUS",
       b.gvt_wip_status "NEW STATUS"
from nknight.ehrp_recs_tracking_tbl a, ehrp.ps_gvt_job b
where --a.load_date > '20-jun-2013' and
      a.emplid = b.emplid and
      a.empl_rcd = b.empl_rcd and
      a.effdt = b.effdt and
      a.effseq = b.effseq and
      a.gvt_wip_status <> b.gvt_wip_status and
      a.changed_wip_status is null
order by 4, 1
) WHERE ROWNUM < 2
);

commit;

UPDATE PROCESS_TABLE
      SET P_STARTDT  = trunc(sysdate) + 10000
   where P_STARTDT  is null ;

commit;

PROMPT alter procedure chk_ehrp2biis_wip_status_p compile;
alter procedure chk_ehrp2biis_wip_status_p compile;
PROMPT 

PROMPT EXEC chk_ehrp2biis_wip_status_p;

EXEC chk_ehrp2biis_wip_status_p;

PROMPT
PROMPT *******************************************
Prompt Update BIIS with new data from today's load
PROMPT *******************************************
PROMPT

PROMPT insert into action_primary_all b
PROMPT select * from nknight.nwk_action_primary_tbl c
PROMPT where c.load_date = trunc(sysdate);
PROMPT

insert into action_primary_all b
select * from nknight.nwk_action_primary_tbl c
where c.load_date = trunc(sysdate);


PROMPT insert into action_secondary_all b
PROMPT select * from nknight.nwk_action_secondary_tbl c
PROMPT where c.event_id in (select a.event_id
PROMPT                      from nknight.nwk_action_primary_tbl a
PROMPT                      where a.load_date = trunc(sysdate));
PROMPT

insert into action_secondary_all b
select * from nknight.nwk_action_secondary_tbl c
where c.event_id in (select a.event_id
                     from nknight.nwk_action_primary_tbl a
                     where a.load_date = trunc(sysdate));
                     
PROMPT insert into action_remarks_all b
PROMPT select * from nknight.nwk_action_remarks_tbl c
PROMPT where c.event_id in (select a.event_id
PROMPT                      from nknight.nwk_action_primary_tbl a
PROMPT                      where a.load_date = trunc(sysdate));     
PROMPT

insert into action_remarks_all b
select * from nknight.nwk_action_remarks_tbl c
where c.event_id in (select a.event_id
                     from nknight.nwk_action_primary_tbl a
                     where a.load_date = trunc(sysdate)); 

commit;    

PROMPT EXEC HISTDBA.GATHER_EHRP2BIIS_RUNCOUNTS_P;
PROMPT

EXEC HISTDBA.GATHER_EHRP2BIIS_RUNCOUNTS_P(NULL);
commit;

PROMPT ***************************

Prompt Update cancelled actions

PROMPT
set echo on;


PROMPT delete PROMPT ACTION_secondary_aLL d
PROMPT WHERE d.EVENT_ID IN (select B.biis_event_id
PROMPT                      from nknight.ehrp_recs_tracking_tbl B
PROMPT                      where B.biis_wip_status_changed_dt = trunc(sysdate));
PROMPT

delete from
 ACTION_secondary_aLL d
WHERE d.EVENT_ID IN
(select B.biis_event_id
   from nknight.ehrp_recs_tracking_tbl B
  where B.biis_wip_status_changed_dt =trunc(sysdate));


PROMPT delete ACTION_remarks_aLL d
PROMPT WHERE d.EVENT_ID IN (select B.biis_event_id 
PROMPT                      from nknight.ehrp_recs_tracking_tbl B
PROMPT                      where B.biis_wip_status_changed_dt = trunc(sysdate));
PROMPT

delete from
 ACTION_remarks_aLL d
WHERE d.EVENT_ID IN
(select B.biis_event_id 
   from nknight.ehrp_recs_tracking_tbl B
  where B.biis_wip_status_changed_dt =trunc(sysdate));

PROMPT delete ACTION_primary_aLL d 
PROMPT WHERE d.EVENT_ID IN (select B.biis_event_id 
PROMPT                      from nknight.ehrp_recs_tracking_tbl B
PROMPT                      where B.biis_wip_status_changed_dt = trunc(sysdate));
PROMPT

delete from
 ACTION_primary_aLL d 
WHERE d.EVENT_ID IN
(select B.biis_event_id 
   from nknight.ehrp_recs_tracking_tbl B
  where B.biis_wip_status_changed_dt =trunc(sysdate));


PROMPT insert into ACTION_primary_aLL 
PROMPT SELECT * FROM NKNIGHT.NWK_ACTION_primary_TBL D
PROMPT WHERE d.EVENT_ID IN (select B.biis_event_id 
PROMPT                      from nknight.ehrp_recs_tracking_tbl B
PROMPT                       where B.biis_wip_status_changed_dt = trunc(sysdate));
PROMPT

insert into ACTION_primary_aLL 
SELECT * FROM NKNIGHT.NWK_ACTION_primary_TBL D
WHERE d.EVENT_ID IN (select B.biis_event_id 
                     from nknight.ehrp_recs_tracking_tbl B
                     where B.biis_wip_status_changed_dt = trunc(sysdate));

PROMPT insert into ACTION_secondary_aLL 
PROMPT SELECT * FROM NKNIGHT.NWK_ACTION_secondary_TBL D
PROMPT WHERE d.EVENT_ID IN (select B.biis_event_id
PROMPT                      from nknight.ehrp_recs_tracking_tbl B
PROMPT   where B.biis_wip_status_changed_dt = trunc(sysdate));
PROMPT

insert into ACTION_secondary_aLL 
SELECT * FROM NKNIGHT.NWK_ACTION_secondary_TBL D
WHERE d.EVENT_ID IN (select B.biis_event_id
                     from nknight.ehrp_recs_tracking_tbl B
                     where B.biis_wip_status_changed_dt = trunc(sysdate));


PROMPT insert into ACTION_remarks_aLL 
PROMPT SELECT * FROM NKNIGHT.NWK_ACTION_remarks_TBL D
PROMPT WHERE d.EVENT_ID IN (select B.biis_event_id 
PROMPT                      from nknight.ehrp_recs_tracking_tbl B
PROMPT                      where B.biis_wip_status_changed_dt = trunc(sysdate));
PROMPT

insert into ACTION_remarks_aLL 
SELECT * FROM NKNIGHT.NWK_ACTION_remarks_TBL D
WHERE d.EVENT_ID IN (select B.biis_event_id 
                     from nknight.ehrp_recs_tracking_tbl B
                     where B.biis_wip_status_changed_dt = trunc(sysdate));

commit;

PROMPT Truncating  NEW_EHRP_ACTIONS_TABLE before next load  - To avoid a load on Sunday

truncate table nknight.nwk_new_ehrp_actions_tbl
/
Spool off;
