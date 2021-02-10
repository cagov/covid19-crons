const { queryDataset,getSQL } = require('../common/snowflakeQuery');
const GitHub = require('github-api');
const githubUser = 'cagov';
const githubRepo = 'covid-static';
const committer = {
  name: process.env["GITHUB_NAME"],
  email: process.env["GITHUB_EMAIL"]
};
const masterBranch = 'master';
const SnowFlakeSqlPath = 'CDTCDPH_VACCINE/';
const targetPath = 'data/vaccine-equity/';

//Check to see if we need stats update PRs, make them if we do.
const doCovidVaccineEquity = async () => {
    const gitModule = new GitHub({ token: process.env["GITHUB_TOKEN"] });
    const gitRepo = await gitModule.getRepo(githubUser,githubRepo);

    const todayDateString = new Date().toLocaleString("en-US", {year: 'numeric', month: '2-digit', day: '2-digit', timeZone: "America/Los_Angeles"}).replace(/\//g,'-');
    const todayTimeString = new Date().toLocaleString("en-US", {hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit', timeZone: "America/Los_Angeles"}).replace(/:/g,'-');

    const branchPrefix = 'data-';
    const BranchName = `${branchPrefix}${todayDateString}-${todayTimeString}-vaccineequity`;
    const CommitText = 'Update Vaccine Equity Data';
    const PrTitle = `${todayDateString} Vaccine Equity`;

    const DbSqlWork = {
        vaccines_by_age : getSQL(`${SnowFlakeSqlPath}vaccines_by_age`),
        vaccines_by_gender : getSQL(`${SnowFlakeSqlPath}vaccines_by_gender`),
        vaccines_by_race_eth: getSQL(`${SnowFlakeSqlPath}vaccines_by_race_eth`)
    };

    const allData = await queryDataset(DbSqlWork,process.env["SNOWFLAKE_CDTCDPH_VACCINE"]);
    const newTree = [];

    const getTreeValue = (path,value) => {
        return {
             mode : '100644', //code for tree blob
             type : 'blob',
             path,
             content : JSON.stringify(value,null,2)
        };
    };

    const customAddDatsetToTree = (dataset, path_prefix, tree, sortMap) => {
        const regions = dataset
            .map(x=>x.REGION)
            .filter((value, index, self) => 
                self.indexOf(value) === index);
            
        regions.forEach(r =>
            {
                const rows = dataset.filter(d=>d.REGION===r);
                const REGION = r.replace(/ County/,'');
                const LATEST_ADMIN_DATE = todayDateString; //TODO: Pull this from data

                const path = `${path_prefix+REGION.toLowerCase().replace(/ /g,'_')}.json`;
                const data = rows.map(x=>({
                    CATEGORY:x.CATEGORY,
                    METRIC_VALUE:x.METRIC_VALUE
                }));

                if(sortMap) {
                    const sortMapA = sortMap.map(x=>x.FROM||x.CATEGORY);

                    //Add 0s for missing mapped values
                    sortMapA
                        .filter(a=>!data.some(s=>s.CATEGORY===a))
                        .forEach(CATEGORY=>{
                            data.push({CATEGORY,METRIC_VALUE:0});
                        });

                    const sortFunction = (a,b) => sortMapA.indexOf(a.CATEGORY)-sortMapA.indexOf(b.CATEGORY);
                    data.sort(sortFunction);

                    data.forEach(x=>{
                        x.CATEGORY = sortMap[sortMapA.indexOf(x.CATEGORY)].CATEGORY;
                    });
                }

                const result = {
                    meta: {
                        REGION,
                        LATEST_ADMIN_DATE
                    },
                    data
                };

                tree.push(getTreeValue(path,result));
            }
            );
    };

    const sortMap_Race = [
        {
            CATEGORY: "American Indian or Alaska Native (AI/AN)",
            FROM: "American Indian or Alaska Native"
        },
        {
            CATEGORY: "Asian American",
            FROM: "Asian"
        },
        {
            CATEGORY: "Black",
            FROM: "Black or African American"
        },
        {
            CATEGORY: "Latino"
        },
        {
            CATEGORY: "Multi-race",
            FROM: "Multiracial"
        },
        {
            CATEGORY: "Native Hawaiian or Other Pacific Islander (NHPI)",
            FROM: "Native Hawaiian or Other Pacific Islander"
        },
        {
            CATEGORY: "White"
        },
        {
            CATEGORY: "Other",
            FROM: "Other Race"
        },
        {
            CATEGORY: "Unknown"
        }
    ];

    const sortmap_Age = [
        {
            CATEGORY: "0-17"
        },
        {
            CATEGORY: "18-49"
        },
        {
            CATEGORY: "50-64"
        },
        {
            CATEGORY: "65+"
        },
        {
            CATEGORY: "Unknown"
        }
    ];

    const sortmap_Gender = [
        {
            CATEGORY: "Female"
        },
        {
            CATEGORY: "Male"
        },
        {
            CATEGORY: "Unknown/undifferentiated"
        }
    ];

    customAddDatsetToTree(allData.vaccines_by_age,`${targetPath}age/vaccines_by_age_`,newTree,sortmap_Age);
    customAddDatsetToTree(allData.vaccines_by_gender,`${targetPath}gender/vaccines_by_gender_`,newTree,sortmap_Gender);
    customAddDatsetToTree(allData.vaccines_by_race_eth,`${targetPath}race-ethnicity/vaccines_by_race_ethnicity_`,newTree,sortMap_Race);

    //function to return a new branch if the tree has changes
    const branchIfChanged = async (tree, branch, commitName) => {
        const refResult = await gitRepo.getRef(`heads/${masterBranch}`);
        const baseSha = refResult.data.object.sha;

        console.log(`Creating tree for ${commitName}`);
        const createTreeResult = await gitRepo.createTree(tree,baseSha);
        const commitResult = await gitRepo.commit(baseSha,createTreeResult.data.sha,commitName,committer);
        const commitSha = commitResult.data.sha;

        //Compare the proposed commit with the trunk (master) branch
        const compare = await gitRepo.compareBranches(baseSha,commitSha);
        if (compare.data.files.length) {
            console.log(`${compare.data.files.length} changes.`);
            //Create a new branch and assign this commit to it, return the new branch.
            await gitRepo.createBranch(masterBranch,branch);
            return await gitRepo.updateHead(`heads/${branch}`,commitSha);
        } else {
            console.log('no changes');
            return null;
        }
    };

    //Create a PR from a new branch if changes exist
    if(await branchIfChanged(newTree,BranchName,CommitText)) {
        const Pr = (await gitRepo.createPullRequest({
            title: PrTitle,
            head: BranchName,
            base: masterBranch
        }))
        .data;

        //Label the Pr
       // await gitIssues.editIssue(Pr.number,{
       //     labels: PrLabels
       // });

        //Approve Pr
       // await gitRepo.mergePullRequest(Pr.number,{
       //     merge_method: 'squash'
       // });

        //Delete Branch
       // await gitRepo.deleteRef(`heads/${Pr.head.ref}`);
       return Pr;
    }

    return null;
};

module.exports = {
    doCovidVaccineEquity
};
