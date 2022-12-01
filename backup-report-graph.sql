select backup_status, sum(sum_value) TOTAL
from (select  case
           when (NVL(max(backuptype_db),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-7
                or NVL(max(backuptype_arch),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-2) then 'Critical'
           when (NVL(max(backuptype_db),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1 
                or NVL(max(backuptype_arch),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1) then 'Ok!'
           else 'Warning'
       end BACKUP_STATUS, 1 sum_value
   from (
      select a.name DB,dbid,
           decode(b.bck_type,'D',max(b.completion_time),'I', max(b.completion_time)) BACKUPTYPE_db,
           decode(b.bck_type,'L',max(b.completion_time)) BACKUPTYPE_arch
      from  rman.rc_database@rman a, rman.bs@rman b
      where a.db_key=b.db_key
        and b.bck_type is not null
        and b.bs_key not in (select bs_key 
		                      from rman.rc_backup_controlfile@rman 
		                      where AUTOBACKUP_DATE is not null 
							     or AUTOBACKUP_SEQUENCE is not null)
        and b.bs_key not in(select bs_key from rman.rc_backup_spfile@rman)
      group by a.name,dbid,b.bck_type
   ) group by db,dbid
    union all
		select 'Ok!',0 from dual
		union all 
		select 'Critical',0 from dual
		union all 
		select 'Warning',0 from dual)
 group by backup_status
 ORDER BY decode (backup_status,'Critical',1,'Warning',2,3),1