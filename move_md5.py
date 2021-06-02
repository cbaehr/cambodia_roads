
import shutil
import os

base_path = "/sciclone/scr20/cbaehr/cambodia_roads/landsat/landsat"

source_dir = os.path.join(base_path, "compressed")
target_dir = os.path.join(base_path, "md5")

file_names = os.listdir(source_dir)

j = [i for i in file_names if i[-3:]=="md5"]

for file_name in j:
	shutil.move(os.path.join(source_dir, file_name), target_dir)


