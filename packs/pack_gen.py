#!/usr/bin/env python3
import os
import glob
import struct

FORMAT_VERSION = 0

def convertObj(filename):
	f = open(filename, 'r')
	vertices = []
	normals = []
	uvs = []
	faces = []
	for line in f:
		line = line.strip().split()
		if len(line) < 1:
			continue
		if line[0] == 'v':
			vertices.append(list(map(lambda n: float(n), line[1:])))
		elif line[0] == 'vn':
			normals.append(list(map(lambda n: float(n), line[1:])))
		elif line[0] == 'vt':
			uvs.append(list(map(lambda n: float(n), line[1:])))
		elif line[0] == 'f':
			faces.append(list(map(lambda n: list(map(lambda m: int(m), n.split('/'))), line[1:])))
	f.close()
	data = b''
	cnt = 0
	for face in faces:
		for i in range(2, len(face)):
			for n in [0, i-1, i]:
				v = vertices[face[n][0] - 1]
				vt = uvs[face[n][1] - 1]
				vn = normals[face[n][2] - 1]
				cnt += 1
				data += struct.pack('@ffffffff', v[0], v[2], v[1], vn[0], vn[2], vn[1], vt[0], 1.0 - vt[1])
	data = struct.pack('>i', cnt) + data
	return data, os.path.splitext(filename)[0] + b'.model'

def buildPack(name):
	os.chdir(name)
	filenames = glob.glob('*') + glob.glob('*/*') + glob.glob('*/*/*')
	files = {}
	for filename in filenames:
		filename = filename.encode('ascii')
		filename = filename.replace(b'\\', b'/')
		if os.path.isfile(filename):
			ext = os.path.splitext(filename)[1]
			if ext == b'.obj':
				data, filename = convertObj(filename)
			elif ext == b'.rar' or ext == b'.zip':
				continue
			else:
				f = open(filename, "rb")
				data = f.read()
				f.close()
			files[filename] = data
	os.chdir('..')
	f = open(name + '.pack', 'wb')
	flog = open(name + '.packlist', 'wb')
	f.write(struct.pack('>i', FORMAT_VERSION))
	f.write(struct.pack('>i', len(files)))
	offset = 8
	for filename, data in files.items():
		offset += 1 + len(filename) + 8
	for filename, data in files.items():
		f.write(struct.pack('>B', len(filename)))
		f.write(filename)
		flog.write(filename + b'\n')
		f.write(struct.pack('>ii', offset, len(data)))
		print(offset, filename)
		offset += len(data)
	for filename, data in files.items():
		f.write(data)
	f.close()
	flog.close()

def main():
	for dir in os.listdir("."):
		if os.path.isdir(dir):
			buildPack(dir)

main()
