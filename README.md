# Env::Dot

## SYNOPSIS

    use Env::Dot;

    print $ENV{'VAR_DEFINED_IN_DOTENV_FILE'};

## DESCRIPTION

More flexibility in how you manage and use your F<.env> file.

**Attn. Existing environment variables always take precedence to dotenv variables!**
A dotenv variable (variable from a file) does not overwrite
an existing environment variable. This is by design because
a dotenv file is to augment the environment, not to replace it.

This means that you can override a variable in `.env` file by creating
its counterpart in the environment. For instance:

    unset VAR
    echo "VAR='Good value'" >> .env
    perl -e 'use Env::Dot; print "VAR:$ENV{VAR}\n";'
    # VAR:Good value
    VAR='Better value'; export VAR
    perl -e 'use Env::Dot; print "VAR:$ENV{VAR}\n";'
    # VAR:Better value

### Features

* If no B<.env> file is present, then do nothing
    By default, Env::Dot will do nothing if there is no `.env` file.
    You can also configure Env::Dot to emit an alarm
    or break execution, if you want.

* Specify the other dotenv files with path
    If your `.env` file is located in another path,
    not the current working directory,
    you can use the environment variable
    **ENVDOT_FILEPATHS> to tell where your dotenv file is located.
    You can specify several file paths; just separate
    them by B<:>. Env::Dot will load all the files in the order
    you specify them, starting from the last, i.e. in reversed order.
    This is the same ordering as used in B<PATH> variable:
    the first overrules the following ones, that is, when reading from the last path
    to the first path, if same variable is present in more than one file, the later
    one replaces the one already read.

* Support different types of .env files
    Unix Shell `source` command compatible dotenv files use double or single quotation marks
    (`"` or `'`) to define a variable which has spaces. But, for instance,
    Docker compatible `.env` files do not use quotation marks. The variable's
    value begins with `=` sign and ends with linefeed.

You can specify in the dotenv file itself - by using meta commands -
which type of file it is.

Read .env file and turn its content into
environment variables for different shells.

# envdot

## DESCRIPTION

**envdot** reads your `.env` file and converts it
into environment variable commands suitable for
different shells (shell families): **sh**, **csh** and **fish**.

`.env` files can be written in different flavors.
**envdot** supports the often used **sh** compatible flavor and
the **docker** flavor which are not compatible with each other.

If you have several `.env` files, you can read them in at one go
with the help of the environment variable **ENVDOT_FILEPATHS**.
Separate the full paths with **:** character.

If you have set the variable **ENVDOT_FILEPATHS**, then **envdot** will use that.
Otherwise, it respects the command line parameter.
If no parameter, then default value is used. Default is the file
`.env` in the current directory.

## SYNOPSIS

envdot [options]

    eval `envdot`

    eval `envdot --no-export --shell csh --dotenv subdir/.env`

    ENVDOT_FILEPATHS=../.env:subdir/.env:.env eval `envdot`

Options:
    --help
    --man
    --version
    --export --no-export
    --shell -s
    --dotenv -e

### CLI interface without dependencies

The **envdot** command is also available
as self contained executable.
You can download it and run it as it is without
additional installation of CPAN packages.
Of course, you still need Perl, but Perl comes with any
normal Linux installation.

This can be convenient if you want to, for instance,
include **envdot** in a docker container build.

    curl -LSs -o envdot https://raw.githubusercontent.com/mikkoi/env-dot/main/envdot.self-contained
    chmod +x ./envdot

### How to Create a FatPacker Executable

    PERL5LIB=lib fatpack pack script/envdot >envdot.self-contained
