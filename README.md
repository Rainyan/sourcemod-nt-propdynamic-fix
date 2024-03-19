# sourcemod-nt-propdynamic-fix
Fix dynamic props ignoring disabled collisions.

## Usage (for mappers)
For a prop_dynamic you wish to disable collisions for, either set its "Collisions" Keyvalue as "Not Solid", or set the spawnflag "Start with collisions disabled".

## Shortcomings
Most likely this plugin will break the `EnableCollision` input for any dynamic props which spawn as non-solid, as they wouldn't have their bone followers initialized in the first place. PRs welcome.

## Background
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
