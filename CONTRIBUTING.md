# Contributing

Thanks for helping improve LTBridge. This guide covers the local setup and checks for working on the project.

## Requirements

- [Node.js](https://nodejs.org/) 22.14.0 or later
- npm (included with Node.js)
- Git

## Set up

Clone the repository and install its dependencies:

```bash
git clone https://github.com/laot7490/ltbridge.git
cd ltbridge
npm install
```

## Make and check changes

Run the type check and test suite before submitting your changes:

```bash
npm run typecheck
npm test
```

`npm test` builds the CLI before running the tests.

## Try the CLI locally

After building, run the CLI from a FiveM resource folder:

```bash
node <path-to-ltbridge>/dist/ltbridge.js init
node <path-to-ltbridge>/dist/ltbridge.js build -w
```

The resource should contain an `fxmanifest.lua`. The watcher stays active while you edit scripts and updates the generated modules as needed.

## Versioning and releases

Update the package version and lockfile together with one of these commands:

```bash
npm run version patch
npm run version minor
npm run version major
```
