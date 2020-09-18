# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import pycharm with context %}
{%- from tplroot ~ "/files/macros.jinja" import format_kwargs with context %}

pycharm-package-archive-install:
                 {%- if grains.os == 'Windows' %}
  chocolatey.installed:
    - force: False
                 {%- else %}
  pkg.installed:
                 {%- endif %}
    - names: {{ pycharm.pkg.deps|json }}
    - require_in:
      - file: pycharm-package-archive-install

             {%- if pycharm.flavour|lower == 'windows' %}

  file.managed:
    - name: {{ pycharm.dir.tmp }}/pycharm.exe
    - source: {{ pycharm.pkg.archive.source }}
    - makedirs: True
    - source_hash: {{ pycharm.pkg.archive.source_hash }}
    - force: True
  cmd.run:
    - name: {{ pycharm.dir.tmp }}/pycharm.exe
    - require:
      - file: pycharm-package-archive-install

             {%- else %}

  file.directory:
    - name: {{ pycharm.dir.path }}
    - mode: 755
    - makedirs: True
    - clean: True
    - require_in:
      - archive: pycharm-package-archive-install
                   {%- if grains.os == 'Windows' %}
    - user: {{ pycharm.identity.rootuser }}
    - group: {{ pycharm.identity.rootgroup }}
    - recurse:
        - user
        - group
        - mode
                   {%- endif %}

  archive.extracted:
    {{- format_kwargs(pycharm.pkg.archive) }}
    - retry: {{ pycharm.retry_option|json }}
                   {%- if grains.os == 'Windows' %}
    - user: {{ pycharm.identity.rootuser }}
    - group: {{ pycharm.identity.rootgroup }}
    - recurse:
        - user
        - group
                   {%- endif %}
             {%- endif %}
    - require:
      - file: pycharm-package-archive-install

    {%- if grains.kernel|lower == 'linux' and pycharm.linux.altpriority|int == 0 %}

pycharm-archive-install-file-symlink-pycharm:
  file.symlink:
    - name: /usr/local/bin/pycharm
    - target: {{ pycharm.dir.path }}/{{ pycharm.command }}
    - force: True
    - onlyif: {{ grains.kernel|lower != 'windows' }}
    - require:
      - archive: pycharm-package-archive-install

    {%- elif pycharm.flavour|lower == 'windowszip' %}

pycharm-archive-install-file-shortcut-pycharm:
  file.shortcut:
    - name: C:\Users\{{ pycharm.identity.rootuser }}\Desktop\{{ pycharm.dirname }}.lnk
    - target: {{ pycharm.dir.archive }}\{{ pycharm.dirname }}\{{ pycharm.command }}
    - working_dir: {{ pycharm.dir.archive }}\{{ pycharm.dirname }}\bin
    - icon_location: {{ pycharm.dir.archive }}\{{ pycharm.dirname }}\bin\pycharm.ico
    - makedirs: True
    - force: True
    - user: {{ pycharm.identity.rootuser }}
    - require:
      - archive: pycharm-package-archive-install

    {%- endif %}
