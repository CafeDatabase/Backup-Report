select DB NAME,
       to_char(dbid,'999999999999') dbid,
       TO_CHAR(max(backuptype_db),'DD/MM/YYYY HH24:MI') FULL_BACKUP,
       TO_CHAR(max(backuptype_arch),'DD/MM/YYYY HH24:MI') ARCH_BACKUP,
       TO_CHAR(max(backuptype_inc_0),'DD/MM/YYYY HH24:MI') INCR_LEVEL_0_BACKUP,
       TO_CHAR(max(backuptype_inc_1),'DD/MM/YYYY HH24:MI') INCR_LEVEL_1_BACKUP,
       case     -- Depending on the last full backup age, the column will show "within 24 hours, 48 hours, 1 week or older
             when (NVL(max(backuptype_db),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1 
			    or NVL(max(backuptype_inc_0),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1) then 'Within last 24 hours'
             when (NVL(max(backuptype_db),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-2 
			    or NVL(max(backuptype_inc_0),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-2) then 'Within last 48 hours'
             when (NVL(max(backuptype_db),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-7 
			    or NVL(max(backuptype_inc_0),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-7)  then 'Within 1 week'
             else 'Older than 1 week'
         end FULL_BACKUP_AGE,
         case  -- Depending on the last archivelog backup age, the column will show "within 24 hours, 48 hours, 1 week or older
            when (NVL(max(backuptype_arch),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1 
			   or NVL(max(backuptype_inc_1),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1) then 'Within last 24 hours'
            when (NVL(max(backuptype_arch),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-2 
			   or NVL(max(backuptype_inc_1),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-2) then 'Within last 48 hours'
            when (NVL(max(backuptype_arch),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-7 
			   or NVL(max(backuptype_inc_1),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-7) then 'Within 1 week'
            else 'Older than 1 week'
        end ARCH_BACKUP_AGE,
         case  -- Scoring considering that having a backup full within 7 days and archivelog backup within 1 day is considered Ok!
            when (NVL(max(backuptype_db),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-7 
		           and NVL(max(backuptype_inc_0),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-7)
                 or NVL(max(backuptype_arch),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-2 then 'Critical'
            when (NVL(max(backuptype_db),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1 
                 or NVL(max(backuptype_arch),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1
				or NVL(max(backuptype_inc_1),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1) then 'Ok!'
            else 'Warning'
        end BACKUP_STATUS,
         case  -- Message info. Change at your consideration.
            when (NVL(max(backuptype_db),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-7 
		        or NVL(max(backuptype_inc_0),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1000) 
				and (NVL(max(backuptype_inc_0),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-7) 
				then 'Full database or incremental level 0 backup older than 1 week. Risk of being unable to recover database.'
            when (NVL(max(backuptype_db),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-7
                 and NVL(max(backuptype_arch),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-2) 
				or (NVL(max(backuptype_inc_0),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-7 
				and NVL(max(backuptype_inc_1),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-2)
				then 'Last archivelog or incremental level 1 backup older than 2 days. High risk of incomplete recovery if any archivelogs / backup files in host are lost.'
		   when (NVL(max(backuptype_inc_0),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-7 
		         and NVL(max(backuptype_inc_0),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1000
				 and (NVL(max(backuptype_inc_1),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-1 
		         and NVL(max(backuptype_inc_1),to_date('01/01/0001','DD/MM/YYYY'))>sysdate-1000) 
				 and NVL(max(backuptype_db),to_date('01/01/0001','DD/MM/YYYY')) between sysdate-7 and sysdate-2
                 and NVL(max(backuptype_arch),to_date('01/01/0001','DD/MM/YYYY'))<sysdate-1) 
				 then 'Full, incremental or archivelog backups too old. Risk of incomplete recovery if any archivelogs in host are lost.'
        end MESSAGE
   from (
       select a.name DB,dbid,
              decode(b.bck_type,'D',max(b.completion_time)) BACKUPTYPE_db,
              decode(b.bck_type||b.incr_level,'I0',max(b.completion_time)) BACKUPTYPE_INC_0,
              decode(b.bck_type||b.incr_level,'I1',max(b.completion_time)) BACKUPTYPE_INC_1,
              decode(b.bck_type,'L',max(b.completion_time)) BACKUPTYPE_arch
       from rman.rc_database@rman a, rman.bs@rman b
       where a.db_key=b.db_key
         and b.bck_type is not null
         and b.bs_key not in (Select bs_key 
		                       from rman.rc_backup_controlfile@rman 
							   where AUTOBACKUP_DATE is not null 
							      or AUTOBACKUP_SEQUENCE is not null)
              and b.bs_key not in (select bs_key 
			                         from rman.rc_backup_spfile@rman)
              group by a.name,dbid,b.bck_type,incr_level
              ) 
  group by db,dbid
  ORDER BY decode (backup_status,'Critical',1,'Warning',2,3),1;