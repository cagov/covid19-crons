const { doTranslationPrUpdate  } = require('./worker');
const { slackBotReportError, slackBotChatPost, slackBotReactionAdd, slackBotReplyPost } = require('../common/slackBot');
const debugChannel = 'C01DBP67MSQ'; // 'C01AA1ZB05B';
const appName = 'CovidTranslationPrApproval';
const masterbranch='master';

module.exports = async function (context, myTimer) {
try {
  await doTranslationPrUpdate(masterbranch);

} catch (e) {
  await slackBotReportError(debugChannel,`Error running ${appName}`,e,context,myTimer);
}
};