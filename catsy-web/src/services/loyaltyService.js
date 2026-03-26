import { apiClient } from './apiClient';

export const loyaltyService = {
    getStatus: () => apiClient.get('/loyalty/status'),

    claimReward: (rewardItem) =>
        apiClient.post('/loyalty/claim', { reward_item: rewardItem }),

    redeemCoupon: (couponCode) =>
        apiClient.post('/loyalty/redeem', { coupon_code: couponCode }),
};
