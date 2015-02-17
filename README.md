# Rue
A quiet but helpful build system.


## Getting Started

You'll need to have Ruby installed, this repository downloaded, and - for best
results - a symlink to the file "rue.rb" somewhere on your path.  If you've done
all of these things, you're ready to configure a project.

Rue uses a configuration file named "ruefile".  Run the `rue` command from the
same directory as that file.  Rue will load the file automatically, read your
project's configuration, and be on its way.

If your project directory looked like this:

    + myproject/
      + src/
        - hello.cpp
        - hello.h
        - main.cpp
      - ruefile

Your ruefile could look like this:

```ruby
Rue.project do |p|
    p.target('hello.out', :srcdir => 'src')
end
```

Then, after running Rue, your directory would look like this:

    + myproject/
      + builds/
        + all/
          + default/
            + obj/
              + hello.out/
                - hello.cpp.o
                - main.cpp.o
            + bin
              - hello.out
        - latest -> all/default/bin
      + src/
        - hello.cpp
        - hello.h
        - main.cpp
      - .ruecache
      - ruefile

Your shiny new executable can be found in "builds/latest".  And all object files
have been stored in the "builds" directory, so cleaning up is as simple as going
in and deleting it (which is exactly what happens when you run `rue clean`).

That's it!


## What just hapened?

You told Rue that your project was made up of one Target (executable / library)
that was called "hello.out" and that had the root of its source tree at "src".
Rue took care of the rest - it found all the source files in that directory,
figured out how they depended on one another, and compiled them down to the
desired executable, keeping cached versions of the intermediate object files so
it won't have to do nearly as much work next time.

You may have seen a message about Rue not being able to load a cache file.  Rue
determines dependencies by going through source files, which is potentially
expensive.  So it keeps a dependency cache as well.  If your compilation was
successful, the cache file was saved, and Rue won't have to parse a bunch of
files next time you run it.

## Details

Rue has two main forms of configuration: Targets and Builds.  A Target, as we've
already seen, is something the compiler is expected to produce.  A Build is a
scope for configuration options you only want in certain situations.  For
example, if you only want debugging info in your debug builds, and only want to
spend cycles optimizing for your release builds, you could write a ruefile like
this:

```ruby
Rue.project do |p|
    p.default_mode = 'debug'
    
    # Global settings:
    p[:cpp][:flags] += ' -Wall -Wextra'
    
    p.build 'debug' do
        # Only for debug builds
        p[:cpp][:flags] += ' -g'
    end
    
    p.build 'release' do
        # Only for release builds
        p[:cpp][:flags] += ' -O3'
    end
    
    p.target 'hello.out', :srcdir => 'src'
end
```

You can build either explicitly with the commands `rue debug` and `rue release`;
the  `default_mode`  setting controls what happens when you run just `rue`  - in
the example above, Rue will run a debug build.

