#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

// Always set the dynamic version of the rabbitfrog as non-solid.
// This fixes vanilla maps like nt_rise without requiring map edits.
// Switch to false to disable this behaviour.
#define FROGHACK true

#define SOLID_NONE 0
#define FSOLID_NOT_SOLID 4
#define SF_DYNAMICPROP_NO_VPHYSICS 128
#define SF_DYNAMICPROP_DISABLE_COLLISION 256
#define COLLISION_GROUP_DEBRIS 1

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
		SetEntityCollisionGroup(pThis, COLLISION_GROUP_DEBRIS);
		hReturn.Value = true;
		return MRES_Supercede;
	}

#if FROGHACK // Set all dynamic rabbitfrogs as non-solid, for vanilla compat
	char mdl[47+1];
	GetEntPropString(pThis, Prop_Data, "m_ModelName", mdl, sizeof(mdl));
	if (StrEqual(mdl, "models/nt/props_vehicles/rabbitfrog_dynamic.mdl"))
	{
		SetEntityCollisionGroup(pThis, COLLISION_GROUP_DEBRIS);
		hReturn.Value = true;
		return MRES_Supercede;
	}
#endif

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

// Backported for old SM compat
#if SOURCEMOD_V_MAJOR <= 1 && SOURCEMOD_V_MINOR <= 10
void SetEntityCollisionGroup(int entity, int collisiongroup)
{
	static Handle call = INVALID_HANDLE;
	if (call == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Entity);
		char sig[] = "\x56\x8B\xF1\x8B\x86\xF4\x01\x00\x00";
		PrepSDKCall_SetSignature(SDKLibrary_Server, sig, sizeof(sig) - 1);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		call = EndPrepSDKCall();
		if (call == INVALID_HANDLE)
		{
			SetFailState("Failed to prep SDK call");
		}
	}
	SDKCall(call, entity, collisiongroup);
}
#endif