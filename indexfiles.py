import os

"""
Simple script used to index all of the files to place on the website.
If any update to the files is observed, this script must be run again
(or the files manually placed into the resulting files.tf file)
and updated using terraform apply before they can be observed on 
the aws server.

Note: currently the root directory is hardcoded as ../root and the resulting
file is hardcoded as files.tf
"""


def det_mine_type(str):
    """ Simple method for determining mime type from given file ext
    :param str: the extension of the file to translate
    :return: mime type
    i.e. txt -> /text/plain or html -> /text/html
    """
    if str == 'html' or str == 'htm':
        return 'text/html'
    elif str == 'css':
        return 'text/css'
    elif str == 'js' or str == 'map':
        return 'application/javascript'
    elif str == 'json':
        return 'application/json'
    else:
        return 'text/plain'


if __name__ == '__main__':
    path_to_root = "../root/"
    s3_obj_tf = "files.tf"

    count = 0
    with open(s3_obj_tf, "w+") as tf:
        for root, _subdirs, files in os.walk(path_to_root):
            for file in files:
                path = os.path.join(root, file).replace('\\', '/')
                tf.write("resource \"aws_s3_bucket_object\" \"file_" + str(count) + "\" {\n")
                tf.write("  bucket = \"${aws_s3_bucket.www_bucket_main.bucket}\"\n")
                tf.write("  key = \"" + path[len(path_to_root):] + "\"\n")
                tf.write("  source = \"" + path + "\"\n")
                tf.write("  content_type = \"" + det_mine_type(file[file.find('.') + 1:]) +"\"\n")
                tf.write("}\n\n")

                count += 1
