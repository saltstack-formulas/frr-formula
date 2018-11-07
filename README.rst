===========
frr-formula
===========

A SaltStack formula that installs and manages Quagga.

**NOTE**

See the full `Salt Formulas installation and usage instructions
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``frr``
-------

Installs the frr package, and configures the associated frr service(s) and starts them.

It is split into several sub-states which should allow easy re-use or replacement of parts of this formula.

The various deamons are entirely configured using Pillar. Please see ``pillar.example``.
