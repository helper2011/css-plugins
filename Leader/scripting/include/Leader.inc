#if defined _leader_included
	#endinput
#endif
#define _leader_included

#define MAIN_COLOR "\x07FFF673"
#define COLOR_FIRST "\x07FFA473"
#define COLOR_SECOND "\x075FD4B1"


native bool Leader_IsClientLeader(int iClient);
native bool Leader_IsClientPossibleLeader(int iClient);
native void Leader_GiveClientLeader(int iClient);

forward void Leader_OnClientActionLeader(int iClient, bool bBecame);


public SharedPlugin __pl_Leader =
{
	name = "Leader",
	file = "Leader.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_Leader_SetNTVOptional()
{
	MarkNativeAsOptional("Leader_IsClientLeader");
	MarkNativeAsOptional("Leader_IsClientPossibleLeader");
	MarkNativeAsOptional("Leader_GiveClientLeader");
}
#endif