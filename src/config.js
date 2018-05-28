module.exports = config = {
    contactEmail: process.env['CONTACT_EMAIL'],
    managementPortal: process.env['ADMIN_URL'],
    marketingPortal: process.env['MARKETING_URL'],
    replyTo: `Venzra <${process.env['REPLY_TO']}>`
};
