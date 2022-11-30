//import packages
import { build } from "esbuild";
import * as SharedBuild from "./build-shared.js";

//set config
let config = {
    ...SharedBuild.sharedConfig,
    splitting: true,
    watch: {
        onRebuild(error, result) {
            if (error) {
                console.error(SharedBuild.redText, 'watch build failed:', error);
            } else {
                console.log(SharedBuild.greenText, 'watch build succeeded:', result);
            }
        }
    }
};

//build entry points with extra Dev only configs
build(config).then(_result => {
    console.log(SharedBuild.cyanText, 'watching...')
});

//display config
delete config.entryPoints;
console.log(SharedBuild.cyanText, "\nUsing build config: '" + JSON.stringify(config, undefined, 1));

//display files being converted
console.log(SharedBuild.magentaText, "\n*** Compiling Development TypeScript ****\n");
SharedBuild.entryPoints.forEach(entryPoint => {
    console.log(SharedBuild.yellowText, "Compiling '" + entryPoint + "'...");

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
console.log(SharedBuild.magentaText, "\n*** Finished Compiling Development TypeScript ****\n");
