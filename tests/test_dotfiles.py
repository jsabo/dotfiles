import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Dotfiles(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.env = dict(os.environ, HOME=str(self.home), PATH='/usr/bin:/bin')
        self.env.pop('DOTFILES_BASH_INITIALIZED', None)
        shutil.copytree(ROOT / '.config/bash', self.home / '.config/bash')

    def shell(self, code, **overrides):
        env = dict(self.env, **overrides)
        result = subprocess.run(['bash', '--noprofile', '--norc', '-c', 'set -e; '+code], env=env,
                                text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        return result

    def helpers(self, code):
        return self.shell('. "$HOME/.config/bash/teleport.sh"; ' + code)

    def test_cluster_selectors_without_persona(self):
        self.helpers('unset TELEPORT_DEMO_USER; tcloud >/dev/null; test $? = 0; tself >/dev/null; test $? = 0')

    def test_persona_is_preserved_and_switches_cluster(self):
        self.shell('. "$HOME/.config/bash/teleport.sh"; test "$TELEPORT_DEMO_USER" = bob; '
                   'tself >/dev/null; test "$TELEPORT_HOME" = "$HOME/.tsh-bob-sh"; '
                   'tnone >/dev/null; test -z "${TELEPORT_HOME:-}"', TELEPORT_DEMO_USER='bob')

    def test_startup_missing_optional_dependencies_and_repeat(self):
        result = self.shell('mkdir -p "$HOME/.local/bin"; . "$HOME/.config/bash/init.sh"; '
                            'before=$PATH; . "$HOME/.config/bash/init.sh"; '
                            'test "$before" = "$PATH"; test "$HISTSIZE" = 10000')
        self.assertEqual(result.stderr, '')

    def test_noninteractive_bashrc_does_not_reset_persona(self):
        shutil.copy(ROOT / '.bashrc', self.home / '.bashrc')
        self.shell('. "$HOME/.bashrc"; test "$TELEPORT_DEMO_USER" = bob; '
                   'test -z "${DOTFILES_BASH_INITIALIZED:-}"', TELEPORT_DEMO_USER='bob')

    def test_interactive_login_and_nonlogin_share_prompt(self):
        # Use -i with no job control (-m) and a controlled rcfile; no user's files.
        executable = self.home / 'bin/oh-my-posh'
        executable.parent.mkdir()
        executable.write_text('#!/bin/sh\nprintf "PROMPT_MARKER=ready\\n"\n')
        executable.chmod(0o755)
        shutil.copy(ROOT / '.bashrc', self.home / '.bashrc')
        shutil.copy(ROOT / '.bash_profile', self.home / '.bash_profile')
        for rc in ['.bash_profile', '.bashrc']:
            command = 'set -e; source "$HOME/' + rc + '"; test "$PROMPT_MARKER" = ready'
            run = subprocess.run(['bash', '--noprofile', '--norc', '-i', '-c', command],
                                 env=dict(self.env, PATH=str(executable.parent)+':/usr/bin:/bin'),
                                 capture_output=True, text=True, timeout=10)
            self.assertEqual(run.returncode, 0, run.stderr)

    def connect_setup(self, contents):
        app = self.home / 'connect-app'
        app.write_text('#!/bin/sh\nexit 0\n')
        app.chmod(0o755)
        path = self.home / '.connect-bob/userData/app_config.json'
        path.parent.mkdir(parents=True)
        if contents is not None:
            path.write_text(contents)
        self.env['TELEPORT_CONNECT_BIN'] = str(app)
        # jq is a required dependency, unlike the GUI app which is faked here.
        self.assertIsNotNone(shutil.which('jq'))
        return path

    def test_connect_preserves_preferences(self):
        path = self.connect_setup(json.dumps({'theme':'dark', 'usageReporting.enabled':True}))
        self.helpers('tconnect bob >/dev/null')
        config = json.loads(path.read_text())
        self.assertEqual(config['theme'], 'dark')
        self.assertTrue(config['usageReporting.enabled'])
        self.assertEqual(config['tshHome'], str(self.home / '.tsh-bob'))

    def test_connect_creates_defaults_and_separates_clusters(self):
        path = self.connect_setup(None)
        self.helpers('tconnect bob >/dev/null; tself >/dev/null; tconnect bob >/dev/null')
        self.assertFalse(json.loads(path.read_text())['usageReporting.enabled'])
        other = self.home / '.connect-bob-sh/userData/app_config.json'
        self.assertEqual(json.loads(other.read_text())['tshHome'], str(self.home / '.tsh-bob-sh'))

    def test_connect_rejects_invalid_config_without_overwrite(self):
        for contents in ['{broken', '', '[]', '{} {}']:
            with self.subTest(contents=contents):
                path = self.home / '.connect-bob/userData/app_config.json'
                if not path.exists():
                    self.connect_setup(contents)
                else:
                    path.write_text(contents)
                self.helpers('if tconnect bob; then exit 1; fi')
                self.assertEqual(path.read_text(), contents)

    def test_toml_and_key_uniqueness(self):
        for path in (ROOT / '.config').rglob('*.toml'):
            config = tomllib.loads(path.read_text())
            if path.parent.name == 'herdr':
                keys = [item['key'] for item in config['keys']['command']]
                self.assertEqual(len(keys), len(set(keys)))

    def test_stow_lifecycle(self):
        if not shutil.which('stow'):
            self.fail('stow is required to validate link behavior')
        shutil.rmtree(self.home / '.config/bash')
        for action in ['--simulate', '', '--restow', '--delete']:
            argv = ['stow', '--no-folding', '--target='+str(self.home)]
            if action:
                argv.append(action)
            result = subprocess.run(argv+['.'], cwd=ROOT, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            if action == '':
                self.assertTrue((self.home / '.bashrc').is_symlink())
                self.assertFalse((self.home / '.config/herdr').is_symlink())
                for name in ['README.md', '.git', '.github', 'scripts', 'tests', 'archive', 'Brewfile', 'LICENSE']:
                    self.assertFalse((self.home / name).exists(), name)
                (self.home / '.config/herdr/sentinel').write_text('runtime')
        self.assertTrue((self.home / '.config/herdr/sentinel').exists())
        self.assertFalse((self.home / '.bashrc').is_symlink())

    def test_vim_preserves_markdown_and_uses_local_make_options(self):
        if not shutil.which('vim'):
            self.skipTest('Vim unavailable locally; installed by CI')
        markdown = self.home / 'test.md'
        markdown.write_text('hard break  \n')
        script = self.home / 'vim-test.vim'
        script.write_text('source '+str(ROOT/'.vimrc')+'\nsource '+str(ROOT/'.vimrc')+'\n'
                          'edit '+str(markdown)+'\nsetfiletype markdown\nwrite\n'
                          'new test.mk\nsetfiletype make\n'
                          'if &l:expandtab | cquit 2 | endif\n'
                          'new test.py\nsetfiletype python\n'
                          'if !&l:expandtab | cquit 3 | endif\nqa!\n')
        result = subprocess.run([shutil.which('vim'),'-Nu','NONE','-n','-es','-S',str(script)], env=self.env,
                                capture_output=True,text=True, timeout=10)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(markdown.read_text(),'hard break  \n')

    def test_legacy_migration_removes_only_checkout_links(self):
        legacy = self.home / '.zshrc'
        legacy.symlink_to(ROOT / '.zshrc')
        independent = self.home / '.colorprompt'
        independent.write_text('personal settings')
        result = subprocess.run([shutil.which('python3'), str(ROOT / 'scripts/remove-legacy-links.py'),
                                 '--target', str(self.home)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(legacy.is_symlink())
        self.assertEqual(independent.read_text(), 'personal settings')

    def test_tsh_completion_ignores_only_missing_generic_command(self):
        bindir = self.home / 'bin'
        bindir.mkdir()
        tsh = bindir / 'tsh'
        tsh.write_text("""#!/bin/sh
cat <<'COMPLETION'
__bash_autocomplete() { :; }
_tsh_bash_autocomplete() { :; }
PROG=
complete -F __bash_autocomplete -o default $PROG
complete -F __bash_autocomplete -o default "$PROG"
complete -F __bash_autocomplete -o default bundled-agent
complete -F _tsh_bash_autocomplete -o default tsh
COMPLETION
""")
        tsh.chmod(0o755)
        for previous in ['', 'complete() { builtin complete "$@"; }; ']:
            result = self.shell(previous +
                                'saved="$(declare -f complete || :)"; '
                                '. "$HOME/.config/bash/init.sh"; '
                                'test "$(declare -f complete || :)" = "$saved"; '
                                'complete -p tsh; complete -p bundled-agent',
                                PATH=str(bindir)+':/usr/bin:/bin')
            self.assertEqual(result.stderr, '')
            self.assertIn('-F _tsh_bash_autocomplete tsh', result.stdout)
            self.assertIn('-F __bash_autocomplete bundled-agent', result.stdout)

    def test_homebrew_prefix_discovery(self):
        bindir = self.home / 'fake-bin'
        bindir.mkdir()
        prefix = self.home / 'custom-brew'
        (prefix / 'bin').mkdir(parents=True)
        (prefix / 'sbin').mkdir()
        brew = bindir / 'brew'
        brew.write_text('#!/bin/sh\nprintf "%s\\n" "'+str(prefix)+'"\n')
        brew.chmod(0o755)
        self.shell('. "$HOME/.config/bash/init.sh"; '
                   'test "$HOMEBREW_PREFIX" = "$HOME/custom-brew"; '
                   'case ":$PATH:" in *":$HOME/custom-brew/bin:$HOME/custom-brew/sbin:"*) ;; *) exit 1 ;; esac; '
                   'original_path="$PATH"; unset DOTFILES_BASH_INITIALIZED; '
                   '. "$HOME/.config/bash/init.sh"; test "$PATH" = "$original_path"',
                   PATH=str(bindir)+':/usr/bin:/bin')

    def test_native_tsh_cluster_is_preserved_and_helper_selection_is_inherited(self):
        self.shell('''
            . "$HOME/.config/bash/teleport.sh"
            tself >/dev/null
            test "$TELEPORT_CLUSTER" = native-cluster
            bash --noprofile --norc -c '. "$HOME/.config/bash/teleport.sh"; test "$DOTFILES_TELEPORT_CLUSTER" = selfhosted'
        ''', TELEPORT_CLUSTER='native-cluster')
