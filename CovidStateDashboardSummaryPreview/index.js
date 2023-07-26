const { doCovidStateDashboardSummary } = require('../CovidStateDashboardSummary/worker');
const { slackBotChatPost, slackBotReportError, slackBotReplyPost, slackBotReactionAdd } = require('../common/slackBot');
const { isIdleDay } = require('../common/timeOffCheck');
const debugChannel = true || process.env.debug ? 'C02J16U50KE' : 'C01DBP67MSQ' //#jbum-testing vs #testingbot

module.exports = async function (context, myTimer) {
  const appName = context.executionContext.functionName;
  let slackPostTS = null;
  try {
    slackPostTS = (await (await slackBotChatPost(debugChannel,`${appName} (Every Wednesday @ 3:45pm)`)).json()).ts;

    if (isIdleDay({weekends_off:true, holidays_off:true})) {
      await slackBotReplyPost(debugChannel, slackPostTS,`${appName} snoozed (weekend or holiday)`);
      await slackBotReactionAdd(debugChannel, slackPostTS, 'zzz');
    } else {

      const TreeRunResults = await doCovidStateDashboardSummary(true);

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
