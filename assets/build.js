const { build } = require("esbuild");
const { devDependencies, peerDependencies } = require('./package.json')
const { Generator } = require('npm-dts');

new Generator({
    entry: 'src/index.ts',
    output: '../priv/static/assets/dist/index.d.ts',
}).generate();

const sharedConfig = {
    entryPoints: ["src/index.ts"],
    bundle: true,
    minify: true,
    external: Object.keys(devDependencies).concat(Object.keys(peerDependencies)),
};

build({
    ...sharedConfig,
    platform: 'node', // for CJS
    outfile: "../priv/static/assets/dist/index.js",
});

build({
    ...sharedConfig,
    outfile: "../priv/static/assets/dist/index.esm.js",
    platform: 'neutral', // for ESM
    format: "esm",
});