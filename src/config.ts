export const config = {
    contactEmail: `${process.env['CONTACT_EMAIL']}`,
    emailDomain: process.env['DOMAIN'] || 'venzra-test.com',
    imageBucket: process.env['AWS_IMAGE_BUCKET'] || 'images.venzra-test.com',
    managementPortal: `${process.env['ADMIN_URL']}`,
    marketingPortal: `${process.env['MARKETING_URL']}`,
    replyTo: `Venzra Support <${process.env['REPLY_TO']}>`,
    secure: process.env['NODE_ENV'] === 'PRODUCTION',
    secret: process.env['JWT_SECRET'] || 'venzra-development',
    stripe: process.env.STRIPE_KEY || '',
    stripeWebhooks: process.env.STRIPE_WEBHOOK_KEY || '',
    stripeConnect: process.env.STRIPE_CONNECT_KEY || ''
};
