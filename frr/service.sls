{%- from "frr/map.jinja" import map with context %}

frr_service:
  service.running:
    - name: {{ map.service }}
    - enable: True
    #- reload: True  # would need frr-pythontools
    - watch:
      - pkg: frr_package

frr_reload:
  cmd.run:
    - name: vtysh -b
    - onchanges:
      - service: frr_service
