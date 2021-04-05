

########################################


import tarfile
import os
from subprocess import call

base_path = "/sciclone/data10/aiddata20/projects/cambodia_roads/landsat/landsat/compressed"

files = list(os.walk(base_path))[0][2]

paths = [os.path.join(base_path, i) for i in files]



for i in paths:
	print(i)
	tarfile.open(i)


##########

import tarfile
import os
from subprocess import call

base_path = "/sciclone/data10/aiddata20/projects/cambodia_roads/landsat/landsat/compressed"
os.chdir(base_path)

files_raw = list(os.walk(base_path))[0][2]
files = [i for i in files_raw if i[-2:]=="gz"]

web_path_root="https://edclpdsftp.cr.usgs.gov/orders/espa-cbaehr@aiddata.org-03232021-225524-631/"

for i in files:
	print(i)
	#path = os.path.join(base_path, i)
	result = None
	while result is None:
		try:
			result=tarfile.open(i)
		except:
			call(["rm", i])
			web_path=web_path_root+i
			md5_file=i[:-6]+"md5"
			md5_path=web_path_root+md5_file
			call(["wget", web_path])
			call(["wget", md5_path])


