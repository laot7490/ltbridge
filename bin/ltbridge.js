#!/usr/bin/env node

const { program } = require('commander');
const { version } = require('../package.json');
const { initProject, addModule, removeModule, refreshModules, pruneModules, watchProject, generateFullApi, listModules, interactiveSelect, explainModule } = require('../src/index');

program
  .name('ltbridge')
  .description('LT Bridge CLI tool for managing Lua modules and intellisense stubs')
  .version(version);

program
  .command('init')
  .description('Initialize LTBridge in the current directory and generate Master API stubs')
  .action(async () => {
    const cwd = process.cwd();
    await initProject(cwd);
  });

program
  .command('build')
  .alias('refresh')
  .alias('install')
  .alias('sync')
  .description('Resolve dependencies, rebuild bundles, and regenerate API stubs')
  .option('-w, --watch', 'Watch project mode for continuous bundling')
  .option('-d, --details', 'Show detailed bundling sequence')
  .action((options) => {
    const cwd = process.cwd();
    if (options.watch) {
      watchProject(cwd, options);
    } else {
      refreshModules(cwd, options);
    }
  });

program
  .command('api')
  .description('Regenerate the API stubs for IDE intellisense (Internal use for developers)')
  .action(() => {
    const cwd = process.cwd();
    console.log(`\n\x1b[36m⚡ ltbridge\x1b[0m \x1b[32mRegenerating API stubs...\x1b[0m`);
    generateFullApi(cwd);
    console.log(`\x1b[32m✓ API reference successfully updated.\x1b[0m\n`);
  });

program
  .command('add <name>')
  .description('Add a module to your project')
  .action((name) => {
    addModule(process.cwd(), name);
  });

program
  .command('remove <name>')
  .description('Remove a module from your project')
  .action((name) => {
    removeModule(process.cwd(), name);
  });

program
  .command('why <name>')
  .alias('explain')
  .description('Explain why a module is included in your project (dependency graph)')
  .action((name) => {
    explainModule(process.cwd(), name);
  });

program
  .command('list')
  .description('List installed and available modules')
  .action(() => {
    listModules(process.cwd());
  });

program
  .command('prune')
  .description('Prune unused modules from your project bundles')
  .action(() => {
    pruneModules(process.cwd());
  });

if (process.argv.length <= 2) {
  interactiveSelect(process.cwd());
} else {
  program.parse(process.argv);
}
