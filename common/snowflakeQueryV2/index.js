const snowflake = require('snowflake-sdk');
//https://docs.snowflake.com/en/user-guide/nodejs-driver.html

/**
 * Runs a name/SQL object and returns a matching object with name/Results.
 * @example
 * const sqlWork = {
 *     myFirstDataset: `select * from data`,
 *     mySecondDataset: `select * from otherdata`
 * }
 * @param {(string|{})} sqlWork single SQL statement string OR name/sql attributes.
 * @param {snowflake.Connection} connection active snowflake.Connection.
 */
const queryDataset = async (sqlWork, connection) => {
    if(!connection) {
        throw new Error('connection is required : use getDatabaseConnection.');
    }

    const singleResult = typeof sqlWork === 'string';
    const queries = singleResult ? {RESULT1 : sqlWork} : sqlWork;

    const dataPromises = [];
    for(let name of Object.keys(queries)) {
        dataPromises.push(getDbPromise(connection,name,queries[name]));
    }

    const resultDatasets = await Promise.all(dataPromises);

    const result = {};

    //flatten results
    for(let promiseResult of resultDatasets) {
        for(let name of Object.keys(promiseResult)) {
            result[name] = promiseResult[name];
        }
    }

    return singleResult ? result.RESULT1 : result;
};

/**
 * creates a new Snowflake Db Promise with the result set name.
 * @param {snowflake.Connection} connection Active snowflake.Connection.
 * @param {string} name Result set name to return
 * @param {string} sqlText Query to execute
 */
const getDbPromise = (connection, name, sqlText) => new Promise((resolve, reject) => {
    connection.execute({
        sqlText,
        complete: function(err, stmt, rows) {
            if (err) {
                console.error(`Failed to execute statement: ${stmt.getSqlText()}`);
                reject(err);
            } else {
                console.log(`Successfully executed statement: ${stmt.getSqlText()}`);
                const result = {};
                result[name] = rows;
                resolve(result);
            }
        }
    });
});

/**
 * Returns a configured snowflake.Connection
 * @param {(string|{})} ConnectionOptions_OR_EnvironmentVariable an object with connection info or an enviornment var ref for the JSON connection string
 * @example let conn = getDatabaseConnection("MY_DATA_CONNECTION");
 * @example 
 * let conn = getDatabaseConnection({account:"MYACCOUNT", warehouse:"MYWAREHOUSE", username:"MYUSER", password:"12345"});
 */
const getDatabaseConnection = ConnectionOptions_OR_EnvironmentVariable => {
    const errMessage = 'You need local.settings.json to contain a JSON connection string {account,warehouse,username,password} to use the dataset features';
    let ConnectionOptions = {};
    if (typeof ConnectionOptions_OR_EnvironmentVariable === "string") {
        const varData = process.env[ConnectionOptions_OR_EnvironmentVariable];
        if(!varData) {
            throw new Error(errMessage);
        }
        ConnectionOptions = JSON.parse(varData);
    } else {
        ConnectionOptions = ConnectionOptions_OR_EnvironmentVariable;
    }

    if (!ConnectionOptions.username || !ConnectionOptions.password || !ConnectionOptions.account | !ConnectionOptions.warehouse) {
        throw new Error(errMessage);
    }

    const connection = snowflake.createConnection(ConnectionOptions);

    // Try to connect to Snowflake, and check whether the connection was successful.
    connection.connect(err => {
        if (err) {
            console.error(err);
        } else {
            console.log(`Successfully connected to Snowflake (${ConnectionOptions.account}-${ConnectionOptions.warehouse}).`);
        }
    });

    return connection;
};

module.exports = {
    getDatabaseConnection,
    queryDataset,
    getDbPromise
};