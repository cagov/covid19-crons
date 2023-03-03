//Loading environment variables
const { Values } = require("../local.settings.json");
Object.keys(Values).forEach(x => (process.env[x] = Values[x])); //Load local settings file for testing

var is_debug = process.argv.slice(2).includes("--debug");
process.env.debug = is_debug;

const path = require('path');
const parentDir = path.basename(path.dirname(__filename));
const context = { executionContext: { functionName: parentDir } };

//run the indexpage async
const indexCode = require("./index");

(async () => {
    await indexCode(context, null);
})();
