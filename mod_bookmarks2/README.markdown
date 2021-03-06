---
labels:
- 'Stage-Alpha'
summary: Synchronise bookmarks between Private XML and PEP
...

Introduction
------------

This module fetches users’ bookmarks from Private XML and pushes them
to PEP on login, and then redirects any Private XML query to PEP.  This
allows interop between older clients that use [XEP-0048: Bookmarks
version 1.0](https://xmpp.org/extensions/attic/xep-0048-1.0.html) and
recent clients which use
[XEP-0402](https://xmpp.org/extensions/xep-0402.html).

Configuration
-------------

Simply [enable it like most other
modules](https://prosody.im/doc/installing_modules#prosody-modules), no
further configuration is needed.

Compatibility
-------------

  ------- ---------------
  trunk   Works
  0.11    Works
  0.10    Does not work
  0.9     Does not work
  ------- ---------------
