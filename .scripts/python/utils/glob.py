import os

# Not necessary (but instructive)---glob module can be used instead
def get_children(parent, extension, exclude_dirs=[".git"]):
    if not os.path.isdir(parent):
        raise ValueError("Argument must be a directory")
    for path, dirs, files in os.walk(parent):
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        for file in files:
            if file.endswith(extension):
                yield file
