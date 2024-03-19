#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.1.2"

#define SOLID_NONE 0
#define FSOLID_NOT_SOLID 4
#define SF_DYNAMICPROP_NO_VPHYSICS 128
#define SF_DYNAMICPROP_DISABLE_COLLISION 256


public Plugin myinfo = {
	name = "NT prop_dynamic collision fix",
	description = "Fix dynamic props ignoring disabled collisions.",
	author = "Rain",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rainyan/sourcemod-nt-propdynamic-fix"
};

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrContains(classname, "prop_dynamic") != 0)
	{
		return;
	}

	static DynamicHook dh = null;
	if (!dh)
	{
		dh = new DynamicHook(139, HookType_Entity, ReturnType_Bool,
			ThisPointer_CBaseEntity);
		if (!dh)
		{
			SetFailState("Failed to create dynamic hook");
		}
	}

	if (INVALID_HOOK_ID ==
		dh.HookEntity(Hook_Pre, entity, CDynamicProp__CreateVPhysics))
	{
		SetFailState("Failed to hook: %d (%s)", entity, classname);
	}
}

MRESReturn CDynamicProp__CreateVPhysics(int pThis, DHookReturn hReturn)
{
	if (IsNotSolid(pThis))
	{
		hReturn.Value = true;
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

bool IsNotSolid(int entity)
{
	if (GetEntProp(entity, Prop_Send, "m_nSolidType") == SOLID_NONE)
	{
		return true;
	}
	if (GetEntProp(entity, Prop_Send, "m_usSolidFlags") & FSOLID_NOT_SOLID)
	{
		return true;
	}
	if (GetEntProp(entity, Prop_Data, "m_spawnflags") &
		(SF_DYNAMICPROP_NO_VPHYSICS | SF_DYNAMICPROP_DISABLE_COLLISION))
	{
		return true;
	}
	return false;
}
