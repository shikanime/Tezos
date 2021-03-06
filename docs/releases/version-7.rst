.. _version-7:

Version 7.1
===========

Version 7.0 notably introduces the multinetwork node.

Version 7.1 fixes a few compilation issues that users encountered with version 7.0,
and fixes a few client commands.

Update Instructions
-------------------

To update from sources::

  git fetch
  git checkout v7.1
  make build-deps
  eval $(opam env)
  make

If you are using Docker instead, use the ``v7.1`` Docker images of Tezos.

New Versioning Scheme
---------------------

Starting from this release, we are using a new versioning scheme to name
our releases. Each release is now named "Version X.Y" where X is the major
version number and Y is the minor version number. Minor releases mostly
backport bug fixes into previous major releases.

Before releasing a new major version, we publish release candidates.
For instance, before releasing 7.0 we published 7.0~rc1, the first release
candidate for version 7.0. Once release candidates have been out
long enough to be sufficiently tested and are considered stable,
we publish actual releases. For instance, 7.0~rc1 was published
April 15th 2020, and 7.0 was published May 5th 2020.

Additionnally, we provide a ``latest-release`` branch which will always
be equal to the latest release. Release candidates are not considered
to be releases in this sense, so ``latest-release`` will never
point to a release candidate. In other words, ``latest-release`` points
to the latest stable release. Currently, it thus points to version 7.1.

If you are used to the ``mainnet`` and ``mainnet-staging`` branches,
you can consider release candidates to be the new ``mainnet-staging``
branches, and the ``latest-release`` branch to be the new ``mainnet``
branch.

Note for Remote Signer Users
----------------------------

Note for users of ``tezos-signer``: the 7.0 (or 7.1) client, baker, endorser
and accuser need the 7.0 signer (or 7.1) to work. They are in particular not
compatible with the ``mainnet`` version of ``tezos-signer``. So remember to
update your remote signer too!

Multinetwork Node
-----------------

The node can now be used with any network, including Mainnet (the
default network) and test networks such as Carthagenet or even custom
ones. See the :ref:`multinetwork` documentation page for more information.

Thanks to this, the same release can be used for all networks
instead of having one branch per network. This allows to name this release
Version 7.0 instead of Mainnet April 2020, as releases are no longer tied to Mainnet.
If you are following the ``mainnet`` branch, you should instead follow the
``latest-release`` branch.

If you are using the Docker script (``alphanet.sh``), note that
this script has been renamed ``tezos-docker-manager.sh``. The ``alphanet.sh``
script is still available in the Docker image for the auto-update mechanism.
See :ref:`howtoget` for more information.

Changelog ??? Version 7.1
-----------------------

Source Compilation
~~~~~~~~~~~~~~~~~~

- The ``Makefile`` now ignores directories with no ``lib_protocol/TEZOS_PROTOCOL``
  files when listing protocols to compile. This fixes an error where ``make`` complained
  that it had no rule to build ``TEZOS_PROTOCOL`` for directories that Git
  does not completely remove when switching branches.

- One can now use opam 2.0.0 again. In version 7.0, an error saying that it did not know
  about option ``--silent`` was emitted.

- The repository no longer contains file names which are longer than 140 characters.
  Longer file names prevented users from checking out version 7.0 on encrypted
  file systems in particular.

- Fixed an issue causing ``make build-deps`` to sometimes fail after an update of
  the digestif external library.

Client
~~~~~~

- Optimized the LAMBDA which is built when injecting manager operations.

- Fixed a bug which caused the wrong entrypoint (``set_delegate`` instead of
  ``remove_delegate``) from being used in some cases when setting delegates.

- Command ``activate account ... with`` can now be given a JSON value directly
  as an argument instead of only a filename.

- Syntax for command ``call from <SRC> to <DST>`` has been fixed to match
  the one for ``proto_alpha``. It should now be called as ``call <DST> from <SRC>``.

Changelog ??? Version 7.0
-----------------------

Multinetwork
~~~~~~~~~~~~

- Node and client now come with all current and past protocols that are still
  in use on Mainnet or some active test networks.

- Added option ``--network`` to ``tezos-node config init`` to select which network
  to connect to from a list of built-in networks (e.g. ``carthagenet``). If you do not
  run ``config init`` or run it without the ``--network`` option, the node will
  use the default network (Mainnet).

- Added option ``--network`` to ``tezos-node run`` and ``tezos-node snapshot import``
  which causes the node to check that it is configured to use the given network.

- Added ``network`` configuration field to select which network to connect to,
  similar to ``--network``. This field also lets you specify an entirely custom,
  non-built-in network and is especially useful to run private networks.
  For instance, LabNet (https://forum.tezosagora.org/t/introducing-labnet-a-rapid-iteration-testnet-for-tezos/1522)
  uses such a custom configuration.

- The ``network`` configuration field also allows to specify user-activated upgrades
  and user-activated protocol overrides. In the past, those upgrades and overrides
  required you to upgrade the node; now, you can just edit the configuration file
  instead. You can also disable built-in upgrades by specifying the configuration
  explicitly.

- The ``network`` configuration field also allows to specify the parameters
  of the genesis protocol, such as the activation key of ``proto_genesis``.
  This allows to use the same genesis protocol for several test networks
  with different activation keys.

- The network name is printed in the logs on startup.

For more information, see: http://tezos.gitlab.io/user/multinetwork.html

Node
~~~~

- Added RPC ``/version`` which returns the version of the node, the version
  of the P2P protocol, the version of the distributed DB, the commit hash
  and the commit date. Other RPCs which returned version numbers
  (``/network/version``, ``/network/versions`` and ``/monitor/commit_hash``)
  are deprecated: use ``/version`` instead.

- RPCs which returned ``treated`` and ``completed`` fields now return durations
  (relative to the value of the ``pushed`` field) instead of timestamps.

- Improved various log messages and errors.

- Fixed a memory leak causing greylisted addresses to be stored several times
  unnecessarily.

- Fixed a small memory leak causing each new worker to store a logger section name
  forever.

- When exporting snapshots, you can now specify the block not only by its hash
  but also by its level or using an alias such as: ``caboose``, ``checkpoint``,
  ``save_point`` or ``head``.

- Fixed a bug which caused snapshots to fail if the checkpoint was a protocol
  transition block.

- Added ``--status`` flag to ``upgrade storage``. This flag causes the node to
  tell you whether a storage upgrade is available.

- Allow more files to exist in the data directory when starting a node from
  an empty storage: ``version.json``, ``identity.json``, ``config.json`` and ``peers.json``.
  Before, only ``identity.json`` was allowed.

- Fixed a bug which caused the check of the ``version.json`` file to be performed
  incorrectly.

- The external validator process now dynamically loads the new protocol after
  a protocol upgrade.

- Sandbox mode may now be used with the external validator process.
  Before, it required ``--singleprocess``.

- The mempool RPC for preapplication now actually sorts operations when the flag is set.

- Changed the format of the peer-to-peer protocol version number.
  Nodes which are running a version older than Mainnet December 2019
  can no longer connect to nodes running this new version and should upgrade.

- Added new peer-to-peer message type: Nack, that carries a list of
  alternative peers and can be returned by nodes with no room for your connection.

- If maximum number of connections has been reached, before rejecting peers,
  authenticate them and memorize their point information.

- Improved the behavior of the greylist of peers.

- The node is now capable of recovering from some cases of storage corruption that
  could in particular occur if the disk became full or if the node was killed.

- Fixed a bug which caused the peer-to-peer layer to send the wrong acknowledgement
  message in response to swap requests.

- Nodes built for Docker images should now correctly contain the version number.

- Removed non-read-only Babylon client commands as they are no longer useful.

- If the node connects to a peer of another network (e.g. if a Mainnet node
  connects to a Carthagenet node), it now removes this peer from its list of known peers.
  This in particular means that it will no longer advertize this peer or try to connect
  to it again.

- In private mode, do not try to discover the local network peers as they will not
  be trusted anyway.

- Fixed a bug which caused the node to stop with a segmentation fault.

Client
~~~~~~

- Added protocol command ``expand macros in`` to expand macros in Michelson code.

- Added command ``tezos-admin-client protocol environment`` which displays the
  version of the environment used by a given protocol.

- Greatly reduce the time the client takes to load.

- Added option ``--mode mockup`` which can be used to run client commands,
  such as commands to typecheck Michelson code, without a running node.

- Added commands ``create mockup for protocol`` and ``list mockup protocols`` to
  manage mockup environments used by ``--mode mockup``.

- Multisig commands can now be used both with contract aliases and addresses
  instead of only with aliases.

- Added a timeout to signature operations using a remote signer, which could otherwise
  block the baker, endorser or accuser.

Protocol
~~~~~~~~

- Added safety checks against code injection when compiling downloaded or injected
  protocols. This was mostly a security concern for nodes with publicly available RPCs.

- Added new demo protocol: ``proto_demo_counter``.

- Prepared the shell to be able to handle multiple protocol environment versions.

Docker Script
~~~~~~~~~~~~~

- Renamed script ``alphanet.sh`` into ``tezos-docker-manager.sh``.
  You should still use ``mainnet.sh`` and ``carthagenet.sh`` as they are now
  symbolic links to ``tezos-docker-manager.sh`` instead of ``alphanet.sh``.

- Removed script ``zeronet.sh`` as Zeronet is using an older version of Babylon
  (PsBABY5H) for which the baker, endorser and accuser binaries are no longer available.
  If you need to connect to Zeronet, use the ``zeronet`` branch instead, which still
  has the ``zeronet.sh`` script.

Miscellaneous
~~~~~~~~~~~~~

- Remove outdated nginx.conf.
