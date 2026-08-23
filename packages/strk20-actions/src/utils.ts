import { CampaignStatus } from "./types.js";
import type { Campaign } from "./types.js";

export function deriveCampaignStatus(
  campaign: Campaign,
  nowSeconds: bigint,
): CampaignStatus {
  if (nowSeconds < campaign.deadline) return CampaignStatus.Active;
  if (campaign.raised >= campaign.goal) {
    return campaign.claimed ? CampaignStatus.Claimed : CampaignStatus.Successful;
  }
  return CampaignStatus.Failed;
}

export function assertNever(value: never): never {
  throw new Error(`Unexpected value: ${value}`);
}
