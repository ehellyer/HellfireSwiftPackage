# Hellfire

Author:     Ed Hellyer
Date:       July 6th 2020

Hellfire is a simple networking package that includes caching, reachability and built-in JSON serialization.  A centeralized service interface handles all concurrent networking calls.  A service interface delegate protocol implemented by your application allows freedom of simple session management at the app layer.  The service interface implements a disposable singleton pattern.  This allow the service interface to be implemented by framework code as needed, then deallocated when done.  The service interface also supports multiple instances in the rare cases that might be needed, such as when a parent app and framework component need to use a networking layer that is independant from each other.  In this rare case only the DiskCache is shared between instances.
