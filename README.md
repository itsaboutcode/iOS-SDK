Currently this file holds the project goals for this repo, once the initial pass is complete this will turn into a normal README.

**Goals:**
* A __simple__ API targeted at iOS developers with only 1-2 years experience in the field
  * The developer does not need to understand the OAuth flow
  * The developer does not need to manage the access token
  * The developer can easily post back out to a network
  * The developer has full access to the singly API

**Implementation:**
The implementation is going to be designed around a similar concept to Apple's Game Center APIs.
The API will have a simple SinglySession interface to do token management and interact with the API.
Configuration of this object will be achieved with a SinglyLoginViewController which will guide the user
through the login experience, both Singly itself and other networks.


