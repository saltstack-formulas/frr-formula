{%- from "frr/map.jinja" import map with context %}
{%- from "frr/macros.jinja" import service_dependencies %}

{%- macro flag_args(flags) %}
{%-   for flag, value in flags.items() %}
--{{ flag }} {{ value }}
{%-   endfor %}
{%- endmacro %}

{%- set frr = salt['pillar.get']('frr', {}) %}
{%- set common_flags = frr.get('common_flags', {}) %}

{%- set alltheflags = {} %}
{%- for protocol, cfg in frr.get('services', {}).items() %}
{%-   if protocol == "zebra" %}
{%-     set service = protocol %}
{%-   else %}
{%-     set service = "{}d".format(protocol) %}
{%-   endif %}
{%-   set merged_flags = {} %}
{%-   do merged_flags.update(common_flags) %}
{%-   do merged_flags.update(cfg.get('flags', {})) %}
{%-   if merged_flags | length > 0 %}
{%-     do alltheflags.update({service: merged_flags}) %}
{%-   endif %}
{%- endfor %}

{%- if map.manage_sysrc %}

{%-   for service, flags in alltheflags.items() %}
frr_flags_{{ service }}:
  sysrc.managed:
    - name: {{ service }}_flags
    - value: "{{ flag_args(flags) }}"
    {{ service_dependencies(service) |indent(4) }}
{%-   endfor %}

{%- elif grains['os_family'] == 'Debian' %}

{%-   for service, flags in alltheflags.items() %}
frr_flags_{{ service }}:
  file.replace:
    - name: {{ map.default_file }}
    - pattern: '^{{ service|upper }}_OPTIONS=.*$'
    - repl: '{{ service|upper }}_OPTIONS="{{ flag_args(flags) }}"'
    - append_if_not_found: True
    {{ service_dependencies(service) |indent(4) }}
{%-   endfor %}

{%- endif %}
