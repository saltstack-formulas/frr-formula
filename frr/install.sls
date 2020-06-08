{%- from "frr/map.jinja" import map with context %}

{%- if map.package_url and map.package_hash %}
{%-   set use_repo = False %}
{%- else %}
{%-   set use_repo = True %}
{%- endif %}

{%- if map.custom_repos and use_repo %}
{%-   set custom_repos = True %}
{%- else %}
{%-   set custom_repos = False %}
{%- endif %}

{%- if custom_repos %}
{%-   for repo in map.custom_repos %}
frr_custom_repo_{{ repo.name }}:
  pkgrepo.managed:
{%-     for key, value in repo.items() %}
    - {{ key }}: {{ value }}
{%-     endfor %}
    - require_in:
      - pkg: frr_package
{%-   endfor %}
{%- endif %}

{%- if not use_repo %}
# Cache the file in order to verify its integrity:
frr_package_cached:
  file.cached:
    - name: {{ map.package_url }}
    - source_hash: {{ map.package_hash }}
{%- endif %}

frr_package:
  pkg.{% if map.package_auto_upgrade and not map.package_url %}latest{% else %}installed{% endif %}:
{%- if use_repo %}
    - name: {{ map.package }}
{%- else %}
    - sources:
      - {{ map.package }}: {{ map.package_url }}
{%- endif %}

frr_logdir:
  file.directory:
    - name: {{ map.log_dir }}
    - user: {{ map.user }}
    - group: {{ map.vtygroup }}
    - mode: '0750'
    - require:
      - pkg: frr_package

frr_confdir:
  file.directory:
    - name: {{ map.conf_dir }}
    - user: root
    - group: {{ map.group }}
    - mode: '0750'
    - require:
      - pkg: frr_package

frr_rundir:
  file.directory:
    - name: {{ map.run_dir }}
    - user: {{ map.user }}
    - group: {{ map.group }}
    - mode: '0750'
    - require:
      - pkg: frr_package
