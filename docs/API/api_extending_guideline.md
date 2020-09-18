### Overview

The intention of this document is to standartize adding new API endpoints and extending schemas.

Given the current state of increasing number of Pleroma clients, Pleroma, as a project, needs to be more careful on API changes. At the moment of writing this document, it's hard for client developer to tell if an API endpoint or scheme will not be changed or broke in the next versions of Pleroma. This document was written in-mind with existing API and proposes a guideline to make various parts of API more future-proof and pollute legacy code as minimum as possible.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

### Contributors
- a1batross, Husky
- ...

### New concepts

This document describes these endpoint groups of client API:

| Group             | Versioned path  | Unversioned path |
| ----------------- | --------------- | ---------------- |
| OAuth             | /oauth/         | N/A              |
| MastoAPI          | /api/vN/        | N/A              |
| PleromaAPI(extensions, AdminAPI, etc) | /api/vN/pleroma | /api/pleroma     |

* Group paths are excluding each other, i.e. endpoint cannot relate to several groups.

* MastoAPI or OAuth SHOULD NOT be extended, as they aren't under Pleroma Project control.

* PleromaAPI is considered stable as it available in at least one release and located under versioned path. These endpoints SHALL NOT be changed, only extended or deprecated. Endpoints SHOULD be deprecated only in major releases.

* Unversioned endpoints MAY be changed between releases and intended for testing solutions.

* NodeInfo, WebFinger or ActivityPub endpoints are not considered as client API and aren't affected by this document.

### API endpoint extension requirements

0. The endpoint MUST be accessed through path according to the base group it belongs to. 

1. Endpoints MUST be accessed through versioned path of their base group if they are considered *stable* and through unversioned path otherwise.

2. New parameters taken by existing endpoint are REQUIRED to be OPTIONAL.

3. Parameters of existing versioned endpoint MUST NOT be removed or have their data type changed.

### Schema extension requirements

0. Objects returned by MastoAPI MUST be extended only through `"pleroma"` object.

1. Fields of objects returned by MastoAPI or versioned Pleroma API MUST NOT be removed or have their data type changed. (exception: Flake IDs)

### Issues

0. Is OAuth should be affected by this document?
Although, OAuth is described by RFC 6749, Pleroma does support refreshing tokens, which aren't supported by Mastodon. In my opinion, in comparison to Mastodon, this is an extension.

1. TBD?

### Revision history

* 2020-09-18: Initial revision
