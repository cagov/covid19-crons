//Loading environment variables
const { Values } = require("../local.settings.json");
Object.keys(Values).forEach(x => (process.env[x] = Values[x])); //Load local settings file for testing

process.env.debug = false; //set to false or remove to run like the real instance

const context = { executionContext: { functionName: "CovidAutoBulder" } };

//run the indexpage async
const indexCode = require("./index");

(async () => {
    await indexCode(context);
})();
