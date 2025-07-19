# What you get with Altadaim

This manual draws inspiration from - among others -
Omakub's [hotkeys section](https://manual.omakub.org/1/read/29/hotkeys).

## Linux

Properly navigating your operating system is already a productivity boost.

- open search bar: `super`
- maximise current window: `super m`
- move current window to left/right screen section: `ctrl super arrow left/right`
- move to next workspace: `ctrl super arrow down`
- move app to next workspace: `shift super arrow down`
- activate full-screen mode in app: `f11`
- in terminal, start Neovim with current directory: `n .`

## Alacritty (your terminal)

### Bash

Being able to interact with a terminal console is helpful
to not be limited by GUI functionality.

- `cd ~/<path_to_folder>`: Jump into a directory.
- `ls -a`: Show all (also hidden) files in directory.
  (Use `ls -a -ll` for a more structured/detailed list.)
- `ctrl + r (keyboard shortcut)`: Reverse i search to find historical bash commands.
- `htop`: See cpu usage (similar to windows task manager, quit with "q").

### Zellij

Zellij lets you easily manipulate your terminal windows.

- open Zellij by entering `zellij` in your terminal
- new vertical/horizontal pane: `ctrl p + r/d`
- increase/decrease current pane size: `alt +/-`
- jump to the next pane (also includes tabs): `alt arrow keys`
- open a floating pane: `alt f`
- create a new tab: `ctrl t + n`

### Lazyvim

Lazyvim is a modern GUI that relies on vim.
In Altadaim, it comes pre-configured with helpful things (e.g. Markdown linting).

If you want to practice vim, ...

- [this video series](https://www.youtube.com/watch?v=X6AR2RMB5tE&list=PLm323Lc7iSW_wuxqmKx_xxNtJC_hJbQ7R)
  gives you a good basic overview.
- [this cheatsheet](https://vim.rtorr.com/) contains many useful commands.

<<<<<<< Updated upstream
=======
#### Lazyvim config

Your Lazyvim setup comes with the following ...

- language linting for Markdown and Python (see plugins/extras.lua)
- coding assistance with Avante (see plugins/avante.lua)
- show hidden files (see plugins/snacks.lua)
- auto-prettify json files (see config/autocmds.lua)

>>>>>>> Stashed changes
#### Lazyvim Commands

- start Lazyvim in your current directory by entering `n .` in your terminal
- open/close the file tree: `space + e`
  - `h` in file tree: show hidden files (.env files remain hidden)
  - `a` in file tree: create a file or folder (add / to create a folder)
  - `d` in file tree: delete a file or folder
- open the file finder: `space + space`
- move the cursor left/down/up/right: `h/j/k/l`
- copy/cut a line: `yy/dd`
- copy/cut 5 lines: `y5y/d5d`
- paste the previously copied/cut lines: `p`
- undo/repeat the previous command: `u/ctrl + r`
- jump ahead/back one word: `w/b`
- jump to top/bottom of file: `gg/G`
- search inside the current file: `/`
- close the current file: `space + b + d`
- close all files but the current one: `space + b + o`
- move to the next file on the left/right: `shift h/l`
- search all files: `space + s + g`
- open lazy git: `space + g + g`

### Psql

Psql is a terminal-based frontend to a Postgresql database.

The easiest way to set up a database connection
for psql is to open your .bashrc and add a
line like this:
`alias psql_NAME='psql CONNECTION_STRING_TO_POSTGRES_DATABASE'`.
Save and close your .bashrc, restart your terminal
and type in `psql_NAME`. Et voilà.

## Git

During the Altadaim installation, you set up your GitHub ssh key.
Version control is a very basic and very useful tool.

- [This video series](https://www.youtube.com/watch?v=rH3zE7VlIMs)
  gives you a good basic overview.
- To test your git knowledge, [clone this repo](https://github.com/juanfresia/git-challenge)
  and complete the challenges.

### Git commands

These are good case practices that we use at Khaldoun.

- When pushing a PR, rebase to the master branch with `git rebase master`
  (make sure you have the most recent master locally!)
  and resolve any merge conflict *before* asking for review.
- When your PR isn't ready for review yet (work in progress)
  but you still want to share it with others, open the PR as `draft`.
- Squash minor git commits into fewer more relevant commits.
  Set "Squash and merge" as default merge option of branches
  (this collapses a branch with many commits into one feature commit in master).
- Where helpful, use gitmojis in your commit messages (e.g. :bug:): <https://gitmoji.dev/>.
- Don't open PRs without descriptions.
  Make sure to minimise typos and formatting issues.
- PRs that are too large cannot be merged (extreme case: 5000+ files are too large).
- Once you dealt with a PR comment,
  click on "Resolve conversation" to indicate that you consider it resolved.
  Either resolve all comments or provide responses.
- Close open issues with a reference to the PRs
  in which they are resolved after you've resolved them.
- use at least these pre-commit hooks: end-of-file-fixer,
  trailing-whitespace, black, isort.
  Always make sure pre-commit hooks have run *before* asking for a review.

## Sql

Never never never write a query like this
  `select * from table Where column = 'text' ORDER by id desc`;
  instead write it like this:

``` sql
select * 
from table 
where column = 'text'
order by id desc
;
```

## Python

- use intention-revealing names:
  in most cases `df` or `data` are terrible names for dataframes;
  be precise and specific in your naming (also for variables, function names, etc.)
- when you want to use global variable names,
  define them in all caps after your import statements: `GLOBAL_VAR = 42`

### Running tests

We write basic unit tests for our products using `pytest` ([link](https://docs.pytest.org/en/stable/)).
Tests are stored in a folder called `tests`,
which is on the same level as the `src` folder.
To run your tests, simply run `pytest` in your repo.

## Docker

Containerising applications with Docker removes
many of the headaches around server configuration.
If the docker runs on one system, it will run on another.

- `docker build -t NAME .`:
  build a container & give it the name NAME
- `docker run NAME`: run the NAME container
  (not additional parameters like `-p`, `-d`, `--env-file`, etc.)
- `docker ps`: see a list of running docker containers
- `docker exec -it INITIAL_DIGITS_OF_CONTAINER sh`:
  jump inside a container & get terminal access

## Github Actions

For Continuous Delivery, we rely on Github Actions.
As one example, check [Lugha's deploy script](https://github.com/khaldoun-xyz/lugha/blob/main/.github/workflows/deploy.yml).
Whenever we merge anything into our `main` branch, the `main` branch
is automatically deployed on our Digital Ocean droplet.

## Power Point

When used properly, Microsoft Power Point is a useful tool for concept work
and to quickly visualise what you have in mind.

### Thoughts on Power Point presentations

- never forget: the only reason to create a presentation is *to sell*
- if it is unclear what the presentation is for, make it clear or cancel the presentation
- before creating slides, write down the key messages of your presentation
  (no more than 3); if they aren't clear, make them clear or cancel the presentation
- for each slide, write down its key message;
  if the key message isn't clear, make it clear or remove the slide
- move everything that doesn't support the key messages into the backup,
  the last section of the presentation
- whatever the time frame of your presentation, plan ~1/3 for the actual presentation
  and ~2/3 for discussion

### Power Point shortcuts

[This Youtube video](https://www.youtube.com/watch?v=-Ab-HYN0WUo) is a good primer
on the power of shortcuts in Power Point.

- `alt` = *the one key to rule them all:* show ribbon key bindings
- `ctrl + shift + ./,` = increase/decrease font size
- `ctrl + shift + g/h` = group/ungroup selection
- `ctrl + shift + c/v` = copy/paste formatting
- `ctrl + backspace` = delete entire word
- `ctrl + mouse wheel` = zoom
- `shift + arrow keys` = increase/decrease box size
- `ctrl + mouse movement` = duplicate box
- `ctrl + shift + mouse movement` = duplicate box & move it in straight line
- `ctrl + alt + m` = create new comment
- `F4` = repeat last command
- `alt` = activate & show quick travel keys

## Plotting

Great graphs help understand the underlying data. [This Youtube video](https://www.youtube.com/watch?v=hVimVzgtD6w&t=57s)
is very educational thanks to graphs.

### Thoughts on great graphs

- good graphs provide easy-to-understand answers to simple qs;
  great graphs provide easy-to-understand answers to complex qs
