import System.IO

def PathCombine(*paths as (string)):
	path = paths[0]
	for part in paths[1:]:
		path = Path.Combine(path, part)
	return path
	
def CopyNewerFileToDirectory(fileName as string, outputDir as string):
	targetFile = Path.Combine(outputDir, Path.GetFileName(fileName))
	if File.Exists(targetFile) and (File.GetLastWriteTime(targetFile) >= File.GetLastWriteTime(fileName)):
		return false
	File.Copy(fileName, targetFile)
	return true
