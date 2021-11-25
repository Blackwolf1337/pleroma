# Nodeinfo

## `/.well-known/nodeinfo`
### The well-known path
* Method: `GET`
* Authentication: not required
* Params: none
* Response: JSON
* Example response:
```json
{
   "links":[
      {
         "href":"https://example.com/nodeinfo/2.0.json",
         "rel":"http://nodeinfo.diaspora.software/ns/schema/2.0"
      },
      {
         "href":"https://example.com/nodeinfo/2.1.json",
         "rel":"http://nodeinfo.diaspora.software/ns/schema/2.1"
      }
   ]
}
```

