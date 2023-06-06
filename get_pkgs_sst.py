#!/bin/env python3

"""
Author: Honza Horak <hhorak@redhat.com>
Copyright 2021 Red Hat, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


A tool to filter packages from the definition files
===================================================
An example of the usage for a useful report of what is specified in the config
but not available in the compose:

./get_pkgs_sst.py --filter-sst=sst_cs_apps configs/*.yaml 2>/dev/null >/tmp/sst
for r in BaseOS AppStream ; do
  dnf repoquery --refresh --available --repofrompath="a,https://odcs.stream.centos.org/test/latest-CentOS-Stream/compose/$r/x86_64/os/" \
                --disablerepo=\* --enablerepo=a --qf '%{name}'
done | sort -u >/tmp/supported

for r in BaseOS AppStream CRB ; do
  dnf repoquery --refresh --available --repofrompath="a,https://odcs.stream.centos.org/test/latest-CentOS-Stream/compose/$r/x86_64/os/" \
                --disablerepo=\* --enablerepo=a --qf '%{name}'
done | sort -u >/tmp/shipped

cat /tmp/sst | while read -r c ; do
  if ! grep -q -e "^$c$" /tmp/supported ; then
    if ! grep -q -e "^$c$" /tmp/shipped ; then
      echo "$c not shipped at all"
    else
      echo "$c not fully supported (CRB only)"
    fi
  fi
done
"""

import yaml
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description='Filter packages from the content resolver input.')
    parser.add_argument('input_files', metavar='FILE', type=str, nargs='+',
                        help='input files')
    parser.add_argument('--filter-sst', dest='filter_sst', default=None,
                        help='Filter data only for a specific sst (e.g.: sst_cs_apps)')
    parser.add_argument('--unwanted', action='store_true')
    parser.add_argument('--label', default='eln', help='Filter only specific distro if label is specified in the yaml: eln[default], c9s')

    args = parser.parse_args()

    for f in args.input_files:
        with open(f, 'r') as stream:
            try:
                data = yaml.safe_load(stream)
                try:
                    if args.filter_sst:
                        if data['data']['maintainer'] != args.filter_sst:
                            continue
                    if 'labels' in data['data'] and args.label not in data['data']['labels']:
                        continue
                    if args.unwanted and 'unwanted_packages' in data['data']:
                        print('\n'.join(data['data']['unwanted_packages']))
                    elif not args.unwanted and 'packages' in data['data']:
                        print('\n'.join(data['data']['packages']))
                    else:
                        # no packages nor unwanted_packages found, ignore
                        continue
                except KeyError as exc:
                    print('Wrong format in {}'.format(f), file=sys.stderr)
                    print(exc, file=sys.stderr)
                    continue

            except yaml.YAMLError as exc:
                print(exc)
                exit(1)

if __name__ == "__main__":
    main()

# vim :set ts=4 sw=4 sts=4 et :
