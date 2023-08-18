const { doCovidStateDashboardTablesHospitals } = require('../CovidStateDashboardTablesHospitals/worker');
const { slackBotChatPost, slackBotReportError, slackBotReplyPost, slackBotReactionAdd } = require('../common/slackBot');
const { isIdleDay } = require('../common/timeOffCheck');
//const notifyChannel = 'C01AA1ZB05B'; // #covid19-state-dash
const debugChannel = true || process.env.debug ? 'C02J16U50KE' : 'C01DBP67MSQ' //#jbum-testing vs #testingbot

module.exports = async function (context, myTimer) {
  const appName = context.executionContext.functionName;
  let slackPostTS = null;
  try {
    slackPostTS = (await (await slackBotChatPost(debugChannel,`${appName} (Every Thursday @ 3:35pm)`)).json()).ts;

    if (isIdleDay({weekends_off:true, holidays_off:true})) {
      await slackBotReplyPost(debugChannel, slackPostTS,`${appName} snoozed (weekend or holiday)`);
      await slackBotReactionAdd(debugChannel, slackPostTS, 'zzz');
    } else {
      const PrResults = await doCovidStateDashboardTablesHospitals(true);

      if(PrResults) {
        await slackBotReactionAdd(debugChannel, slackPostTS, 'package');

        for (let Pr of PrResults) {
          await slackBotReplyPost(debugChannel, slackPostTS, Pr.html_url);
          //removing notifications until final deployment
          //await slackBotChatPost(notifyChannel, Pr.html_url);
        }
      }
      await slackBotReplyPost(debugChannel, slackPostTS,`${appName} finished`);
      await slackBotReactionAdd(debugChannel, slackPostTS, 'white_check_mark');
    }
  } catch (e) {
    await slackBotReportError(debugChannel,`Error running ${appName}`,e,context,myTimer);

    if(slackPostTS) {
      await slackBotReplyPost(debugChannel, slackPostTS, `${appName} ERROR!`);
      await slackBotReactionAdd(debugChannel, slackPostTS, 'x');
    }
  }
};
