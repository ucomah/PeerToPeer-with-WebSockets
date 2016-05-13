# Peer-to-peer chat with WebSockets

This project demonstrates the way to discover another iOS device in local network using Bonjour and establish a connection via WebSockets to transfer any kind of data.
Any iOS device can be the server and the client in the same time.

### Usage

You should have at least 2 iOS devices to try this sample. Both devices should start "listening" for incoming connections and discover each other over the network before they will be able to connect. Once one device is discovered by another - connection can be made and exchange can be started.

NOTE: Even in the background mode, iOS will shout down your app after a 3 minutes of activity. So if you will minimize your app, and raise later, all connections could be lost.

### TODO
1. Ping connections after app resigned active and cleanup the list.
2. Possible crash when using UIApplication background modes.
3. Peers list: swipe to disconnect.
4. Activity indicator when connecting to peer (Peer status update).
