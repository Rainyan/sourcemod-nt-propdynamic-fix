# sourcemod-nt-propdynamic-fix
Fix dynamic props ignoring disabled collisions.

# Building
## Requirements
* SourceMod 1.8 or newer
* [Neotokyo include](https://github.com/softashell/sourcemod-nt-include)

> [!IMPORTANT]
> If using SourceMod **older than 1.11**: you also need [the DHooks extension](https://forums.alliedmods.net/showpost.php?p=2588686). Download links are at the bottom of the opening post of the AlliedMods thread. Be sure to choose the correct one for your SM version! You don't need this if you're using SourceMod 1.11 or newer.

# Usage
## For mappers
For a prop_dynamic you wish to disable collisions for, either set its "Collisions" Keyvalue as "Not Solid", or set the spawnflag "Start with collisions disabled".
Also see any exceptions to this rule [below](#for-server-operators).

## For server operators
By default, all dynamic rabbitfrogs will have their solidity disabled regardless of map options, for compatibility with original NT maps.
If you want to disable this, toggle the `FROGHACK` preprocessor define in the source code from `true` to `false` before compiling.

# Shortcomings
Most likely this plugin will break the `EnableCollision` input for any dynamic props which spawn as non-solid, as they wouldn't have their bone followers initialized in the first place. PRs welcome.

# Background
In the Source 2006 engine, any dynamic props using bone followers will incorrectly initialize those bone followers before checking whether the prop should have collisions in the first place:
```cpp
// CDynamicProp::CreateVPhysics, abridged
if ( pkvBoneFollowers )
{
    /* spooky scary bone follower things */
    return true;
}
// ...and only later:
if ( GetSolid() == SOLID_NONE || ((GetSolidFlags() & FSOLID_NOT_SOLID) && HasSpawnFlags(SF_DYNAMICPROP_NO_VPHYSICS)))
{
    // don't create a physics object in this case - saves CPU & memory
}
```
This plugin detours the function call, and bails out if trying to initialize bone followers for a non-solid prop.
