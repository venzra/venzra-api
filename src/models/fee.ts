export interface Fee {
    venzra: { amount: number, currency: string };
    gateway: { amount: number, currency: string };
    total: number;
}
