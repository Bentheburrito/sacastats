import { build } from "esbuild";
//import { devDependencies, peerDependencies } from './package.json';

import pkg from 'glob';
const { sync } = pkg;
const entryPoints = sync('./src/**/*.ts');

// custom text colors
const reset = "\x1b[0m";

const fgYellow = "\x1b[33m";
const fgMagenta = "\x1b[35m";

const yellowText = fgYellow + "%s" + reset;
const magentaText = fgMagenta + "%s" + reset;

// const nodeModules = ["three"];
// const nodeEntries = [];

// const nodeModuleConfig = {
//     entryPoints: nodeEntries,
//     bundle: true,
//     minify: true,
//     external: []//Object.keys(devDependencies).concat(Object.keys(peerDependencies))
// };
// nodeModules.forEach(module => {
//     nodeEntries.push("./node_modules/" + module)
// });
// console.log(nodeModuleConfig)
// build({
//     ...nodeModuleConfig,
//     outfile: './vendor/vendor.js',
//     platform: 'neutral', // for ESM
//     format: "esm",
//     external: [],
//     watch: false,
// });

const sharedConfig = {
    entryPoints: entryPoints,
    bundle: false,
    minify: true, //set to true for production; set to false for debugging
    external: []//Object.keys(devDependencies).concat(Object.keys(peerDependencies))
};

console.log(magentaText, "*** Compiling TypeScript ****\n");
build({
    ...sharedConfig,
    outbase: '',
    outdir: '../priv/static/assets/dist',
    platform: 'node', // for CJS
    external: [],
    watch: false,
});
entryPoints.forEach(entryPoint => {
    console.log(yellowText, "Compiling '" + entryPoint + "'...");

    // ******** keep for custom building ********** //

    // sharedConfig.entryPoints = [entryPoint];
    // let outfile = entryPoint.replace("./src", "../priv/static/assets/dist");
    // outfile = outfile.replace(".ts", ".js");

    //const filesThatUseNodeModules = ["./src/character/model.ts"];
    // if (filesThatUseNodeModules.includes(entryPoint)) {
    //     sharedConfig.bundle = true;
    //     build({
    //         ...sharedConfig,
    //         outfile: outfile,
    //         platform: 'neutral', // for ESM
    //         format: "esm",
    //         external: [],
    //         watch: false,
    //     });
    // } else {
    //     sharedConfig.bundle = false;
    //     build({
    //         ...sharedConfig,
    //         outfile: outfile,
    //         platform: 'node', // for CJS
    //         external: [],
    //         watch: false,
    //     });
    // }
});
console.log(magentaText, "\n*** Finished Compiling TypeScript ****\n");
