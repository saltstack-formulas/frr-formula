{%- from "frr/map.jinja" import map with context %}

{%- set routers_defaults = {
  "zebra": True
}%}

{#- There may be 'babel' or 'ospf', but also i.e. 'bgp 65000' #}
{%- set processed_services = [] %}
{%- for name, config in salt['pillar.get']('frr:routers', routers_defaults, True).items() %}
{%-   set yesno = 'yes' if config else 'no' %}
{%-   set service = name.split(' ')[0] %}
{%-   if not service in processed_services %}
{%-     do processed_services.append(service) %}
{%-     if not service == "zebra" %}
{%-       set service = "{}d".format(service) %}
{%-     endif %}

frr_service_{{ name }}_activation:
  file.replace:
    - name: {{ map.conf_dir }}/daemons
    - pattern: '{{ "^{}=.*$".format(service) }}'
    - repl: '{{ "{}={}".format(service, yesno) }}'
    - append_if_not_found: True
    - watch_in:
      - service: frr_service
    - onchanges_in:
      - cmd: frr_reload

{%-   endif %}
{%- endfor %}

# http://docs.frrouting.org/en/latest/vtysh.html#integrated-configuration-mode
frr_service_config:
  file.managed:
    - name: {{ map.conf_dir }}/frr.conf
    - source: salt://frr/files/frr.conf.jinja
    - template: jinja
    - require_in:
      - service: frr_service
    - onchanges_in:
      - cmd: frr_reload
