#!/usr/bin/env python
########################################################################
##
## Copyright 2014 PMC-Sierra, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License"); you
## may not use this file except in compliance with the License. You may
## obtain a copy of the License at
## http://www.apache.org/licenses/LICENSE-2.0 Unless required by
## applicable law or agreed to in writing, software distributed under the
## License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
## CONDITIONS OF ANY KIND, either express or implied. See the License for
## the specific language governing permissions and limitations under the
## License.
##
########################################################################

########################################################################
##
##   Author: Logan Gunthorpe
##
##   Date: Oct 23, 2014
##
##   Description:
##      Obtain a version string from git information
##
########################################################################

from __future__ import print_function

import os
import subprocess as sp

try:
    from waflib.Task import Task
except:
    Task = object

template = """
#ifndef VERSION_H
#define VERSION_H

#define VERSION "%s"

#endif
"""

def options(opt):
    pass

def configure(conf):
    conf.find_program(["git"], var='GIT', mandatory=False)
    conf.env.append_unique("INCLUDES", ".")

def get_git_version(git="git"):
    if hasattr(get_git_version, "cached"):
        return get_git_version.cached

    p = sp.Popen([git, "describe", "--always"], stdout=sp.PIPE,
                 stderr=open(os.devnull, "w"))
    version = p.communicate()[0].strip()

    if p.wait():
        return "exported"

    status = sp.Popen([git, "status", "--porcelain", "-uno"],
                      stdout=sp.PIPE, stderr=open(os.devnull, "w")).communicate()[0]

    max_length = get_git_version.max_length
    if max_length:
        version=version[:max_length]

    if status.strip():
        if max_length:
            version=version[:max_length-1]
        version += "M"

    get_git_version.cached = version

    return version

get_git_version.max_length = 24

class VersionHeader(Task):
    color = "PINK"

    def __init__(self, *k, **kw):
        Task.__init__(self, *k, **kw)

        if "target" in kw:
            self.set_outputs(kw["target"])

    def run(self):
        rev = self.signature()
        rev = rev.strip()

        for o in self.outputs:
            f = open(o.abspath(), "w")
            print(template % (rev), file=f)
            f.close()

    def signature(self):
        try: return self.cache_sig
        except AttributeError: pass

        if self.env.GIT:
            self.cache_sig = get_git_version(self.env.GIT[0])
        else:
            self.cache_sig = "unknown"

        return self.cache_sig

def build(ctx):
    tsk = VersionHeader(target=ctx.path.find_or_declare("version.h"),
                        env=ctx.env)
    ctx.add_to_group(tsk)

if __name__ == "__main__":
    try:
        print(get_git_version())
    except sp.CalledProcessError:
        print("unknown")
