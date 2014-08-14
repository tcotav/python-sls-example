#!py

'''
What are we doing here: basically using python to generate the same YAML structure
except jumping the whole jinja/YAML step and creating the raw python to which it maps  
'''

import os

"""
gen_symlink_struct 
  function to generate YAML equivalent to the file.symlink state invocation
"""
def gen_symlink_struct(filename, basepath, targetdir):
  retdir= {
    'file.symlink': [
      {"target" : "%s/%s" % (basepath, filename)},
      {"name" :  "%s/%s" % (targetdir, filename)}
    ]
  }
  return retdir

def run():
  retdict={}
  installdir="%s/bin" % pillar['site-mongodb_install_dir']
  for f in [f for f in os.listdir(installdir)]:
    retdict["%s_symlink" % f] = gen_symlink_struct(f, installdir, "/usr/bin")

  #print retdict  # <<<<--- this is cool because we can just dump this to stdout
  return retdict
