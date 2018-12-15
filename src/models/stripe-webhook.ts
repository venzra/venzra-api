export interface StripeWebhook {
    type: string;
    account?: string;
    data: any;
}
