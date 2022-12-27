//import packages
import pkg from 'glob';
const { sync } = pkg;

// custom text colors
const reset = "\x1b[0m";

const fgYellow = "\x1b[33m";
const fgMagenta = "\x1b[35m";
const fgCyan = "\x1b[36m";
const fgGreen = "\x1b[32m";
const fgRed = "\x1b[31m";

export const yellowText = fgYellow + "%s" + reset;
export const magentaText = fgMagenta + "%s" + reset;
export const cyanText = fgCyan + "%s" + reset;
export const greenText = fgGreen + "%s" + reset;
export const redText = fgRed + "%s" + reset;

//Dev and Prod Configs
export const entryPoints = sync('./src/**/*.ts');
export const sharedConfig = {
    entryPoints: entryPoints,
    bundle: true,
    outbase: '',
    outdir: '../priv/static/assets/dist',
    format: 'esm',
    treeShaking: true,
    external: []
};
