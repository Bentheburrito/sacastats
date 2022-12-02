//import packages
import { build } from "esbuild";
import * as SharedBuild from "./build-shared.js";

//set config
let config = {
    ...SharedBuild.sharedConfig,
    splitting: true,
    minify: true,
};

//build entry points with extra Prod only configs
build(config);

//display config
delete config.entryPoints;
console.log(SharedBuild.cyanText, "\nUsing build config: '" + JSON.stringify(config, undefined, 1));

//display files being converted
console.log(SharedBuild.magentaText, "\n*** Compiling Production TypeScript ****\n");
SharedBuild.entryPoints.forEach(entryPoint => {
    console.log(SharedBuild.yellowText, "Compiling '" + entryPoint + "'...");
});
console.log(SharedBuild.magentaText, "\n*** Finished Compiling Production TypeScript ****\n");
