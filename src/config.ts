export const config = {
    managementPortal: `${process.env['ADMIN_URL']}`,
    marketingPortal: `${process.env['MARKETING_URL']}`,
    contactEmail: `${process.env['CONTACT_EMAIL']}`,
    replyTo: `Venzra Support <${process.env['REPLY_TO']}>`,
    emailDomain: process.env['DOMAIN'] || 'venzra-test.com',
    secure: process.env['NODE_ENV'] === 'PRODUCTION',
    secret: process.env['JWT_SECRET'] || 'venzra-development',
    imageBucket: process.env['AWS_IMAGE_BUCKET'] || 'images.venzra-test.com'
};
