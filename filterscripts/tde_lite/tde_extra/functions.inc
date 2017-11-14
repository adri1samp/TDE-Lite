CheckDatabaseTables()
{
	db_query
	(
		TDE_LITE_DB,
		"\
			CREATE TABLE IF NOT EXISTS `config`\
			(\
				`varName` VARCHAR(24),\
				`varValue` VARCHAR(24)\
			);\
		"
	);

	db_query
	(
		TDE_LITE_DB,
		"\
			CREATE TABLE IF NOT EXISTS `project`\
			(\
				`id` INTEGER PRIMARY KEY AUTOINCREMENT,\
				`name` VARCHAR(128),\
				`creator` VARCHAR(24),\
				`last_editor` VARCHAR(24),\
				`date` VARCHAR(24) DEFAULT CURRENT_TIMESTAMP,\
				`date_last_edit` VARCHAR(24) DEFAULT CURRENT_TIMESTAMP\
			);\
		"
	);
	return 1;
}

CountProjects()
{
	new DBResult:Result, projects;
	Result = db_query(TDE_LITE_DB, "SELECT COUNT() FROM `project`;");

	if(db_num_rows(Result))
	{
		projects = db_get_field_int(Result, 0);
	}
	db_free_result(Result);
	return projects;
}