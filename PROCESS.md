# The Rue Build Process
================================================================================

## Target Listing

In this stage,  the project's targets are stored as a "light" version - simply a
collection of the information passed to the `target` declaration.  This stage is
kept simple, as it runs whenever Rue is invoked.


## Target Instantiation

Next, Rue constructs its internal representation of the targets.  Source, target
and object directories are also instantiated.   A  `build`  is required for this
stage,   as the target and object directories depend on the build name.   If not
given, `project.default_build` will be used, which, if not set, is `"default"`.


## Source Instantiation

Once the source directories are known,  Rue can walk the filesystem,  collecting
and instantiating the source files within each.

As Rue instantiates source files, it reads them line by line, finding inter-file
dependencies.   Since this is potentially expensive, these auto dependencies are
cached in `.ruecache`, and files are only crawled if they have changed since the
last crawling.


## Object Instantiation

The source files are gone through once again.   Object files are instantiated in
the object  directory for any source file that will be compiled.   These objects
automatically  depend on their sources,  and are listed as dependencies of their
respective targets.


## Cycle Detection

With the complete dependency graph in place,  Rue can use Tarjan's SCC algorithm
to construct a directed, acyclic graph (DAG) of dependencies. Cycles in the file
graph are collapsed to vertices in the DAG,  allowing for a simple,  depth-first
compilation algorithm.


## Compilation

Finally, Rue performs a depth-first walk on the DAG,  building files as it comes
to them.   It uses a comparison between a file's last modification time  and the
last modification times of all its dependencies to only rebuild when necessary.


