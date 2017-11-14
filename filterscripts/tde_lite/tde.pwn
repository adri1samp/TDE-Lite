#define SCRIPT_NAME 		"TDE Lite"
#define SCRIPT_VERSION 		"0.01"
#define SCRIPT_VERSION_DATE	"11/Nov/2017"

#define TAG_TEXT			"[TDE]"
#define TAG_COLOR			"6cccfc"
#define TEXT_COLOR			"FFFFFF"


#include <a_samp>
#include <YSI-Includes\YSI\y_text>
#include <YSI-Includes\YSI\y_languages>
#include <YSI-Includes\YSI\y_dialog>
#include <YSI-Includes\YSI\y_inline>
#include <YSI-Includes\YSI\y_commands>

/* Load texts */
loadtext lang[tdelite];

/* Var */
new
	DB:TDE_LITE_DB,
	bool:Database_Connected,
	Loaded_Languages,
	Iterator:Players_Editing<MAX_PLAYERS>,
	Lang_Dialog_String[128],
	text_tag[32]
;

/* P Var */
enum CONTROL_STATES
{
	CONTROL_STATE_NONE,
	CONTROL_STATE_SELECT_LANG,
	CONTROL_STATE_SELECT_PROJECT,
	CONTROL_STATE_EDITING
};

enum TDE_STATES
{
	TDE_STATE_NORMAL
};

enum ENUM_PLAYER_TEMP
{
	CONTROL_STATES:pt_CONTROL_STATE,
	TDE_STATES:pt_TDE_STATE,
	pt_PLAYER_NAME[MAX_PLAYER_NAME]
};
new PLAYER_TEMP[MAX_PLAYERS][ENUM_PLAYER_TEMP];

/* Extra */
#include "./tde_extra/functions"
#include "./tde_extra/commands_alias"
#include "./tde_extra/langs"

public OnFilterScriptInit()
{
	/* Languages */
	AddLanguages();


	/* Load */
	print("\n _______________________________________\n");
	print("\t"SCRIPT_NAME" "SCRIPT_VERSION" ("SCRIPT_VERSION_DATE")");

	/* Languages */
	Loaded_Languages = _:Langs_GetLanguageCount();

	new line_str[24], lang_server[64];
	for(new i = 0; i != Loaded_Languages; i ++)
	{
		format(line_str, sizeof line_str, "> [%s] %s\n", Langs_GetCode(Language:i), Langs_GetName(Language:i));
		strcat(Lang_Dialog_String, line_str);

		format(line_str, sizeof line_str, "%s%s", Langs_GetCode(Language:i), i != Loaded_Languages - 1 ? ", " : "");
		strcat(lang_server, line_str);
	}
	printf("\tLanguages (%d): %s", Loaded_Languages, lang_server);

	/* Database */
	TDE_LITE_DB = db_open("TDE_Lite/tde_db.db");
	if(TDE_LITE_DB == DB:0)
	{
		print
		(
			"\
				\t\tCouldn't open database.\n\
				\t\tIs TDE_Lite directory created?\n\
				\t\tDir: ./scriptfiles/TDE_Lite/\
			"
		);
	}
	else
	{
		new projects = CountProjects();
		printf("\tDB connected (%d projects)", projects);
		Database_Connected = true;
	}

	/* Ok */
	if(!Database_Connected) print("\n\t"SCRIPT_NAME" loaded [BAD (Database not connected)");
	else if(!Loaded_Languages) print("\n\t"SCRIPT_NAME" loaded [BAD (Couldn't load language)");
	else print("\n\t"SCRIPT_NAME" loaded [OK]");
	print(" _______________________________________\n\n");

	if(Database_Connected) CheckDatabaseTables();
	Commands_Alias();
	text_tag = "{"TAG_COLOR"}"TAG_TEXT" {"TEXT_COLOR"}";
	return 1;
}

public OnFilterScriptExit()
{
	foreach(new i : Players_Editing)
	{
		CancelSelectTextDraw(i);
	}

	db_close(TDE_LITE_DB);

	print("\n _______________________________________\n");
	print("\t"SCRIPT_NAME" unloaded");
	print(" _______________________________________\n\n");
	return 1;
}

YCMD:tdhelp(playerid, params[], help)
{
	if(help) Text_Send(playerid, $MESSAGE_CMD_HELP_HELP, text_tag);
	else
	{
		if(isnull(params))
		{
			new count = Command_GetPlayerCommandCount(playerid), dialog[256];
			for (new i = 0; i != count; ++i)
			{
				new str[32];
				format(str, sizeof str, " - /%s\n", Command_GetNext(i, playerid));
				strcat(dialog, str);
			}

			Text_DialogBox(playerid, DIALOG_STYLE_MSGBOX, using none, $DIALOG_HELP_CAPTION, $DIALOG_HELP_BODY, $DIALOG_HELP_YES, $DIALOG_HELP_NO, Lang_Dialog_String);
		}
		else Command_ReProcess(playerid, params, true);
	}
	return 1;
}

YCMD:tdel(playerid, params[], help) 
{
	if(help) Text_Send(playerid, $MESSAGE_CMD_HELP_TDEL, text_tag);
	else
	{
		switch(PLAYER_TEMP[playerid][pt_CONTROL_STATE])
		{
			case CONTROL_STATE_NONE:
			{
				if(!Loaded_Languages) SendClientMessage(playerid, -1, "[TDE] Couldn't start "SCRIPT_NAME". Error: Couldn't load language.");
				else if(!Database_Connected) Text_Send(playerid, $MESSAGE_ERR_BAD_DB, text_tag);
				else
				{
					GetPlayerName(playerid, PLAYER_TEMP[playerid][pt_PLAYER_NAME], MAX_PLAYER_NAME);
					Iter_Add(Players_Editing, playerid);

					PLAYER_TEMP[playerid][pt_CONTROL_STATE] = CONTROL_STATE_SELECT_LANG;
					Text_DialogBox(playerid, DIALOG_STYLE_LIST, using callback OnPlayerSelectLang, $DIALOG_SELECT_LANG_CAPTION, $DIALOG_SELECT_LANG_BODY, $DIALOG_SELECT_LANG_YES, $DIALOG_SELECT_LANG_NO, Lang_Dialog_String);
				}
			}
			case CONTROL_STATE_SELECT_LANG, CONTROL_STATE_SELECT_PROJECT:
			{
				PLAYER_TEMP[playerid][pt_CONTROL_STATE] = CONTROL_STATE_NONE;
				PLAYER_TEMP[playerid][pt_TDE_STATE] = TDE_STATE_NORMAL;
				Iter_Remove(Players_Editing, playerid);
				Text_Send(playerid, $MESSAGE_INFO_CLOSE, text_tag);
			}
			case CONTROL_STATE_EDITING:
			{
				PLAYER_TEMP[playerid][pt_CONTROL_STATE] = CONTROL_STATE_NONE;
				PLAYER_TEMP[playerid][pt_TDE_STATE] = TDE_STATE_NORMAL;
				Iter_Remove(Players_Editing, playerid);
			}
		}
	}
	return 1;
}

public e_COMMAND_ERRORS:OnPlayerCommandReceived(playerid, cmdtext[], e_COMMAND_ERRORS:success) 
{
	if(success == COMMAND_UNDEFINED)
	{
		Text_Send(playerid, $MESSAGE_CMD_ERROR, text_tag);
		return COMMAND_OK;
	}
	return success;
}

forward OnPlayerSelectLang(playerid, dialogid, response, listitem, inputtext[]);
public OnPlayerSelectLang(playerid, dialogid, response, listitem, inputtext[])
{
	if(response)
	{
		Langs_SetPlayerLanguage(playerid, Language:listitem);
		SendClientMessage(playerid, -1, " ");
		SendClientMessage(playerid, -1, " ");
		Text_Send(playerid, $MESSAGE_INFO_WELCOME, SCRIPT_NAME, SCRIPT_VERSION);
		Text_Send(playerid, $MESSAGE_INFO_LANG, text_tag, Langs_GetName(Language:listitem));

		PLAYER_TEMP[playerid][pt_CONTROL_STATE] = CONTROL_STATE_SELECT_PROJECT;
		Text_DialogBox(playerid, DIALOG_STYLE_LIST, using callback OnPlayerProjectDialog, $DIALOG_SELECT_PROJECT_CAPTION, $DIALOG_SELECT_PROJECT_BODY, $DIALOG_SELECT_PROJECT_YES, $DIALOG_SELECT_PROJECT_NO);
	}
	else
	{
		PLAYER_TEMP[playerid][pt_CONTROL_STATE] = CONTROL_STATE_NONE;
		PLAYER_TEMP[playerid][pt_TDE_STATE] = TDE_STATE_NORMAL;
		Iter_Remove(Players_Editing, playerid);
		Text_Send(playerid, $MESSAGE_INFO_CLOSE, text_tag);
	}
	return 1;
}

forward OnPlayerProjectDialog(playerid, dialogid, response, listitem, inputtext[]);
public OnPlayerProjectDialog(playerid, dialogid, response, listitem, inputtext[])
{
	if(response)
	{
		switch(listitem)
		{
			case 0: //new
			{
				Text_DialogBox(playerid, DIALOG_STYLE_INPUT, using callback OnPlayerNewProjectDialog, $DIALOG_NEW_PROJECT_CAPTION, $DIALOG_NEW_PROJECT_BODY, $DIALOG_NEW_PROJECT_YES, $DIALOG_NEW_PROJECT_NO);
			}
			case 1: //load
			{
				new projects = CountProjects();
				if(!projects)
				{
					Text_Send(playerid, $MESSAGE_ERR_NO_PROJECTS, text_tag);
					Text_DialogBox(playerid, DIALOG_STYLE_LIST, using callback OnPlayerProjectDialog, $DIALOG_SELECT_PROJECT_CAPTION, $DIALOG_SELECT_PROJECT_BODY, $DIALOG_SELECT_PROJECT_YES, $DIALOG_SELECT_PROJECT_NO);
				}
				else
				{

				}
			}
			case 2: //exit
			{
				PLAYER_TEMP[playerid][pt_CONTROL_STATE] = CONTROL_STATE_NONE;
				PLAYER_TEMP[playerid][pt_TDE_STATE] = TDE_STATE_NORMAL;
				Iter_Remove(Players_Editing, playerid);
				Text_Send(playerid, $MESSAGE_INFO_CLOSE, text_tag);
			}
		}
	}
	else
	{
		PLAYER_TEMP[playerid][pt_CONTROL_STATE] = CONTROL_STATE_SELECT_LANG;
		Text_DialogBox(playerid, DIALOG_STYLE_LIST, using callback OnPlayerSelectLang, $DIALOG_SELECT_LANG_CAPTION, $DIALOG_SELECT_LANG_BODY, $DIALOG_SELECT_LANG_YES, $DIALOG_SELECT_LANG_NO, Lang_Dialog_String);
	}
	return 1;
}

forward OnPlayerNewProjectDialog(playerid, dialogid, response, listitem, inputtext[]);
public OnPlayerNewProjectDialog(playerid, dialogid, response, listitem, inputtext[])
{
	if(response)
	{
		if(isnull(inputtext))
		{
			Text_Send(playerid, $MESSAGE_ERR_NO_INPUTTEXT, text_tag);
			Text_DialogBox(playerid, DIALOG_STYLE_INPUT, using callback OnPlayerNewProjectDialog, $DIALOG_NEW_PROJECT_CAPTION, $DIALOG_NEW_PROJECT_BODY, $DIALOG_NEW_PROJECT_YES, $DIALOG_NEW_PROJECT_NO);
			return 1;
		}

		new DBResult:Result, DB_Query[128], bool:exists;
		format(DB_Query, sizeof DB_Query, "SELECT `id` FROM `project` WHERE `name` = '%q';", inputtext);
		print(DB_Query);
		Result = db_query(TDE_LITE_DB, DB_Query);

		if(db_num_rows(Result)) exists = true; 
		db_free_result(Result);

		if(exists)
		{
			// existe, mostrar dialogo para cargar
			return 1;
		}

		format(DB_Query, sizeof DB_Query, 
			"INSERT INTO `project` (`name`, `creator`, `last_editor`) VALUES ('%q', '%q', '%q');",
			inputtext, PLAYER_TEMP[playerid][pt_PLAYER_NAME], PLAYER_TEMP[playerid][pt_PLAYER_NAME]
		);
		db_query(TDE_LITE_DB, DB_Query);
	}
	else Text_DialogBox(playerid, DIALOG_STYLE_LIST, using callback OnPlayerProjectDialog, $DIALOG_SELECT_PROJECT_CAPTION, $DIALOG_SELECT_PROJECT_BODY, $DIALOG_SELECT_PROJECT_YES, $DIALOG_SELECT_PROJECT_NO);
	return 1;
}