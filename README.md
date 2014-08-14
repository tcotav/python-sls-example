## Writing Salt Formulas in Python

### The Scenario

We've got some legacy environments or rather legacy code.  Let's pretend for a moment that we can't or don't want to go with the standard location for the installs and assume that we're manually plopping these files in.  Play along.  

We are installing alternate packages in /opt.  We then symlink any binaries from there to the system path (`/usr/bin`).  Could we have just added each `/opt/<blah>/bin` to the system path?  Sure.  Should we have?  Probably.  Did we?  Hell no.

So, what we need to do is symlink all of the binaries from `/opt/mongo`.  At the 10k ft view though, we're applying a state to a list of items.  How do we get that list though?

### Requirements

You just need this repo and a working salt install.  I'm a fan of [masterless salt minions](http://salt.readthedocs.org/en/latest/topics/tutorials/quickstart.html) for simple local dev work. 


### init.sls using python

First, there are [docs on using python for writing your templates](http://salt.readthedocs.org/en/latest/ref/renderers/all/salt.renderers.py.html). 

If you take a look at `init.sls` in our test repo, you'll see some of the stuff related to using python for writing your sls.  The first line of the file has to be:

    #!py


From there, the only requirement (that I'm aware of) is that you have a `run()` function.

    def run():

That's it.  Let's take a look at the rest of our example file.
    
    import os

You can use any of the python libs on your machine.  Go crazy -- use all the libraries (no, don't...).  

    def gen_symlink_struct(filename, basepath, targetdir):

It's python -- you can use helper functions.  You can call out and pull stuff from a database.  You can sleep for 20 seconds as a very unfunny joke.  

You can also apply states iteratively using a for loop that iterates over a list of files it pulls up from the os which we do with this bit of code:

    for f in [f for f in os.listdir(installdir)]:
      retdict["%s_symlink" % f] = gen_symlink_struct(f, installdir, "/usr/bin")


Of course we have TWO cases where we need to do this -- in two separate states.  The easy road is to just copy it entirely off to the other case and change the pillar data used.  Duplicate code copypaste :(

### The biggest thing to note

The biggest thing to note is that you are going to return a data struct that parallels the `YAML` you would've used to do the same thing.

Look at what we do in our `init.sls` file -- we generate python that looks like the following:

    'bsondump_symlink': {
      'file.symlink': [
        {'target': '/opt/mongo/bin/bsondump'}, 
        {'name': '/usr/bin/bsondump'}
      ]
    }

compare that with the same YAML:

    bsondump_symlink:
      file.symlink:
        - target: '/opt/mongo/bin/bsondump' 
        - name: /usr/bin/bsondump

I know which one I'd rather use.  If only I could somehome wedge that os.listdirs in there.  (I just took a minute right there to ask in `#salt` irc channel.  Crickets... so hopefully this isn't a silly example/use-case).


### Running it

This is dependent on your environment.  I usually work on a local masterless salt-minion vagrant box.  To test it, I just `state.sls` the state

    salt-call --local state.sls test

You'll get a list of all the files it changed and finally:

    Summary
    -------------
    Succeeded: 14
    Failed:     0
    -------------
    Total:     14


### Conclusion

In the end, this isn't all that great of a solution for us as the creation of symlinks is one task in a larger series.  I guess I could modify the main .sls file by importing this sls:

    include:
      - test

or after renaming it and dropping it into the `mymongo` state directory's `init.sls`:

    include:
      - mymongo.symlink_mongo_bins.sls

but the real conclusion I reached is that I'll just avoid the whole shebang because the file list don't change all that often if ever:

    # symlink binaries from /opt/mongo/bin -> /usr/bin
    {% for bin in ["bsondump","mongo","mongod","mongodump","mongoexport","mongofiles","mongoimport","mongooplog","mongoperf","mongorestore","mongos","mongosniff","mongostat","mongotop"] %}

    {{bin}}_symlink:
      file.symlink:
        - target: {{ install_dir }}/bin/{{ bin }}
        - name: /usr/bin/{{ bin }}
        - require:
          - file: /opt/mongo

    {% endfor %}

(that's right -- a gold star to the student who wrote down 'hardcode that').
