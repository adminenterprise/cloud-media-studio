export interface UserProfile {
  id: string;
  name: string;
  email: string;
  role: string;
  team: string;
  avatarUrl: string;
  plan: 'Enterprise Pro' | 'Standard Creator';
  region: string;
}

