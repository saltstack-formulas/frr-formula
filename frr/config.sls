{%- from "frr/map.jinja" import map with context %}

{%- set services_defaults = {
  "zebra": True
}%}

{%- macro service_dependencies(service_name=False) -%}
- watch_in:
{%-   if service_name and not map.one_service_to_start_them_all %}
  - service: frr_{{ service_name }}_service
{%-   else %}
  - service: frr_service
{%-   endif %}
{%-   if map.use_integrated_mode %}
  - cmd: frr_reload
{%-   endif %}
{%- endmacro %}

{%- set services = [] %}{# used below in 'frr_daemons' #}
{%- for protocol, config in salt['pillar.get']('frr:services', services_defaults, True).items() %}
{%-   set yesno = 'yes' if config else 'no' %}
{%-   if protocol == "zebra" %}
{%-     set service = protocol %}
{%-   else %}
{%-     set service = "{}d".format(protocol) %}
{%-   endif %}
{%-   do services.append(service) %}


{%-   if map.use_daemons_file %}

frr_service_{{ service }}_activation_existance:
  file.managed:
    - name: {{ map.conf_dir }}/daemons
    - user: {{ map.user }}
    - group: {{ map.group }}
    - require_in:
      - file: frr_service_{{ service }}_activation
    - require:
      - file: frr_service_config
frr_service_{{ service }}_activation:
  file.replace:
    - name: {{ map.conf_dir }}/daemons
    - pattern: '{{ "^{}=.*$".format(service) }}'
    - repl: '{{ "{}={}".format(service, yesno) }}'
    - append_if_not_found: True
    {{ service_dependencies(service) |indent(4) }}

{%-   endif %}


frr_service_config_{{ service }}:
{%-     if config %}
{%-   if not map.use_integrated_mode %}
  file.managed:
    - source: salt://frr/files/frr.conf.jinja
    - template: jinja
    - context:
        protocol: {{ protocol }}
{%-     else %}
  file.absent:
{%-     endif %}
{%-   else %}
  file.absent:
{%-   endif %}
    - name: {{ map.conf_dir }}/{{ service }}.conf
    {{ service_dependencies(service) |indent(4) }}

{%-   if map.manage_sysrc %}
frr_service_{{ service }}_activation:
  sysrc.managed:
    - name: {{ service }}_enable
    - value: "YES"
    {{ service_dependencies(service) |indent(4) }}
{%-   endif %}

{%-   if not map.one_service_to_start_them_all %}
frr_{{ service }}_service:
{%-     if config %}
  service.running:
    - enable: True
{%-     else %}
  service.dead:
    - enable: False
{%-     endif %}
    - name: {{ service }}
    - watch:
      - pkg: frr_package
{%-   endif %}

{%- endfor %}


frr_vtysh_config:
{%- if map.use_integrated_mode or map.use_vtysh %}
  file.managed:
    - mode: '0644'
    - user: {{ map.user }}
    - group: {{ map.vtygroup }}
    - contents: |
        service integrated-vtysh-config
        username cumulus nopassword
{%- else %}
  file.absent:
{%- endif %}
    - name: {{ map.conf_dir }}/vtysh.conf
    - watch_in:
      - service: frr_service

{%- if map.use_integrated_mode %}

# http://docs.frrouting.org/en/latest/vtysh.html#integrated-configuration-mode
frr_service_config:
  file.managed:
    - name: {{ map.conf_dir }}/frr.conf
    - source: salt://frr/files/frr.conf.jinja
    - template: jinja
    - require:
      - pkg: frr_package
    - watch_in:
      - service: frr_service

frr_reload:
  cmd.run:
    - name: vtysh -b
    - onchanges:
      - service: frr_service

{%-   if map.manage_sysrc %}
frr_vtysh_boot:
  sysrc.managed:
    - value: "{{ "YES" if map.use_integrated_mode else "NO" }}"
    - require_in:
       - service: frr_service
{%-   endif %}

{%- else %}{# not map.use_integrated_mode #}

frr_service_config:
  file.absent:
    - name: {{ map.conf_dir }}/frr.conf

{%- endif %}


{%- if map.one_service_to_start_them_all %}

{%-   if map.manage_sysrc %}
frr_daemons:
  sysrc.managed:
    - name: frr_daemons
    - value: {{ services | join(' ') }}
    - require_in:
       - service: frr_service

frr_enable:
  sysrc.managed:
    - value: "YES"
    - require_in:
       - service: frr_service
{%-   endif %}

frr_service:
  service.running:
    - name: {{ map.service }}
{%-   if not map.manage_sysrc %}
    - enable: True
{%-   endif %}
    #- reload: True  # would need frr-pythontools
    - watch:
      - pkg: frr_package

{%- endif %}
