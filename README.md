# gmod-addworkshop-collection
Provides a resource add workshop collection to GarrysMod. Note that those addons will not be downloaded on the server, use host_workshop_collection instead.

## Convars
* sv_collection_clients_download (default: "") add this collection to the download list automatically. (Can be changed at runtime to add content or using server.cfg)
* sv_collections_cached (default: 1) does the addons ids for collections get cached (So in case steam has a problem, addons will be added using the cache)

## More collections
* If you want to load more collections on start you should change the addworkshop_collections variable inside the script.

## Global Functions
* Resource_AddWorkshopCollection(string Collection_ID)

## Script output
#### Output prefix : [AWC] (Add Workshop Collection)

* When addons are added to the download list
* When addons list is cached
* When addon fails to do something