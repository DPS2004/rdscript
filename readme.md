# rdScript
rdScript is a scripting language for making advanced Rhythm Doctor levels.


## Requirements
All this program requires is an installation of Lua, which can be gotten here: http://luabinaries.sourceforge.net/
Alternatively, you can download a compiled version for Windows in the Releases tab.

## Basic Usage
```
rdscript yourscript.rdscript yourlevel.rdlevel [outputlevel.rdlevel]
```
If no output file is provided, it will be saved to out.rdlevel

## Commands
### define(tag_name)
Makes a new tag. Code containted in the block will be added to the tag.

### if(expression)
If the expression evaluates to true, the code contained in the if block will be executed.

### for(bar, beat, duration)
Starting at the provided bar and beat and lasting for the duration, code in this block will be executed every frame.

### setcondensed(true/false)
Provide true to enable condensed loops (the default) and false to disable condensed loops. Uncondensed loops execute frame-accurately, but there may be bugs. Use at your own risk.

### python_mode(true/false)
See below for more information.

### end
Ends a block. ¯\\\_(ツ)_/¯

### levelend(bar)
Put this at the top of your script, and set bar to the bar number with the *last* end level event of the level. Hopefully I can autodetect this in the future...

### tag(tag_name)
Runs a tag.

### run(method)
Runs a custom method.

## Python Mode
Since some dislike putting end at the end of blocks, put python_mode(True) at the top of your rdscript file to enable Python Mode. This will cause the program to interpret one line having a smaller indent than the last line as an end command. See pytest.rdscript for an example of this.

Check out test.rdlevel and test.rdscript for an example on how to put it all together.

If you have suggestions on how this can be improved, let me know!