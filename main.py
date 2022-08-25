
import argparse
import os
import subprocess
import sys
from json import loads

TEMP_FILE_NAME=".temporalpatchfileABI0612"

parser=argparse.ArgumentParser()

parser.add_argument('--method')
parser.add_argument('--repo')
parser.add_argument('--pwd')
parser.add_argument('--file')

args=parser.parse_args()

def unify():
	with open(args.file, 'r+') as file:
		unified = set(file.read().split('\n'))
		file.truncate(0)
		file.write('\n'.join(unified))

def apply_patch():
	for patch in loads(sys.stdin.read()):
		with open(TEMP_FILE_NAME, 'w') as patch_file:
			patch_file.write(patch['patch'])
		subprocess.run(['patch', args.pwd + '/' + patch['filename'], TEMP_FILE_NAME])
		os.remove(TEMP_FILE_NAME)


def cat_addons_path():
	extra_addons = ','.join([
		args.pwd + '/' + directory.split('/')[-1]
		for directory in sys.stdin.read().split('\n')
		if directory and directory not in ('.', '..', args.repo)
	])
	repo_path = ',' + args.pwd + '/' + args.repo
	print(extra_addons + repo_path)


if __name__ == '__main__':
	if args.method == 'patch':
		apply_patch()
	if args.method == 'addons':
		cat_addons_path()
	if args.method == 'unify':
		unify()
