# backup report queries

This is a set of two queries I use to show up the status of the backups.
I took the initial query from Gavin Soorma's website and improve it to produce a detailed report for every database in the RMAN catalog.

The idea is to use BIPublisher or Oracle Analytics Server to create a report and use the two scripts as source. 

With the "backup-report.sql" you get a detailed list of the last successfull backup of every type.
With the "backup-report-graph.sql" you get the total of 'Warning/Ok!/Critical' databases.

As you may see, the criteria may be different for each script, so I use the two criterias I consider clearer to understand the backup situation of the databases.

The idea is getting the last DB Full backup, the last archivelogs backup, the last incremental level 0 and incremental level 1, and then stablish a scoring based on the ages you consider reasonable in your environment.

Here are the steps:

So, you have to run those scripts in the RMAN catalog database, or in the OEM repository database (in which case you need to create a dblink to the catalog owner of the RMAN repository).

1- Download all files in the OMS repository database or the RMAN catalog database.

	backup-report.sql
	backup-report-graph.sql

2- If you're running those scripts in the OEM repository, you should have a database link pointing to the RMAN catalog owner like this:

	SQL> CREATE DATABASE LINK RMAN CONNECT TO <rman_catalog_owner> IDENTIFIED BY <password> USING '<RMAN_CONNECTION_STRING>';
	
**NOTE**: If you have issues, you should ensure you can reach the RMAN catalog like this:

	sqlplus <rman_catalog_owner>/<password>@<RMAN_CONNECTION_STRING>
	
	
3- Run the scripts in sqlplus and check the results.


4- Now you can use those SQL scripts as data sources for your BI Publisher and Oracle Analytics Server reports.
	
Enjoy!
