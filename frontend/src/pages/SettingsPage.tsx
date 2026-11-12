import React, { useState } from 'react';
import { 
  User, 
  ShieldCheck, 
  Cloud, 
  KeyRound, 
  Lock, 
  CheckCircle2, 
  Server, 
  GitBranch, 
  Save
} from 'lucide-react';

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState<'profile' | 'storage' | 'security' | 'devsecops'>('profile');
  const [savedNotice, setSavedNotice] = useState(false);

  // Form states
  const [profile, setProfile] = useState({
    name: 'Alex Morgan',
    email: 'alex.morgan@cloudmedia.studio',
    role: 'Principal Cloud Architect',
    team: 'Media Platform & Infrastructure'
  });

  const [storageConfig, setStorageConfig] = useState({
    rawBucket: 'enterprise-cloud-media-raw-ap-southeast-1',
    processedBucket: 'enterprise-cloud-media-processed-ap-southeast-1',
    archiveDays: 30,
    enableIntelligentTiering: true,
    glacierTransitionClass: 'GLACIER_IR'
  });

  const [devsecopsConfig, setDevsecopsConfig] = useState({
    sonarqubeGate: 85,
    trivySeverity: 'CRITICAL,HIGH',
    autoDeployECS: true,
    zapScanEnabled: true
  });

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSavedNotice(true);
    setTimeout(() => setSavedNotice(false), 3000);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-slate-200 dark:border-slate-800">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">Settings & Governance</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Configure system preferences, AWS cloud resources, FinOps tiering, and DevSecOps security policies.
          </p>
        </div>
        <button
          onClick={handleSave}
          className="inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium rounded-lg text-white bg-indigo-600 hover:bg-indigo-700 shadow-sm transition-colors"
        >
          <Save className="w-4 h-4" />
          <span>Save Changes</span>
        </button>
      </div>

      {savedNotice && (
        <div className="p-3 bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 rounded-lg flex items-center gap-2 text-sm text-emerald-800 dark:text-emerald-300 animate-in fade-in">
          <CheckCircle2 className="w-4 h-4 flex-shrink-0" />
          <span>Settings successfully synchronized with AWS CloudFormation & Parameter Store.</span>
        </div>
      )}

      {/* Tabs */}
      <div className="flex border-b border-slate-200 dark:border-slate-800 space-x-6 text-sm font-medium">
        <button
          onClick={() => setActiveTab('profile')}
          className={`pb-3 border-b-2 flex items-center gap-2 transition ${activeTab === 'profile' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'}`}
        >
          <User className="w-4 h-4" />
          <span>Profile & Identity</span>
        </button>
        <button
          onClick={() => setActiveTab('storage')}
          className={`pb-3 border-b-2 flex items-center gap-2 transition ${activeTab === 'storage' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'}`}
        >
          <Cloud className="w-4 h-4" />
          <span>S3 & FinOps Policy</span>
        </button>
        <button
          onClick={() => setActiveTab('security')}
          className={`pb-3 border-b-2 flex items-center gap-2 transition ${activeTab === 'security' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'}`}
        >
          <ShieldCheck className="w-4 h-4" />
          <span>Security & IAM</span>
        </button>
        <button
          onClick={() => setActiveTab('devsecops')}
          className={`pb-3 border-b-2 flex items-center gap-2 transition ${activeTab === 'devsecops' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400' : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'}`}
        >
          <GitBranch className="w-4 h-4" />
          <span>DevSecOps Pipeline</span>
        </button>
      </div>

      {/* Tab 1: Profile & Identity */}
      {activeTab === 'profile' && (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-6 shadow-sm space-y-6">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-gradient-to-tr from-indigo-600 to-violet-500 flex items-center justify-center text-white font-bold text-xl shadow-md">
              AM
            </div>
            <div>
              <h3 className="font-semibold text-slate-900 dark:text-white text-lg">{profile.name}</h3>
              <p className="text-sm text-slate-500 dark:text-slate-400">{profile.role} • AWS Cognito SSO</p>
              <div className="flex items-center gap-2 mt-1.5">
                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                  MFA Enforced
                </span>
                <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800 dark:bg-indigo-950/60 dark:text-indigo-300">
                  Admin Privileges
                </span>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-4 border-t border-slate-100 dark:border-slate-800">
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">Full Name</label>
              <input
                type="text"
                value={profile.name}
                onChange={(e) => setProfile({ ...profile, name: e.target.value })}
                className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">Corporate Email</label>
              <input
                type="email"
                value={profile.email}
                onChange={(e) => setProfile({ ...profile, email: e.target.value })}
                className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">Organizational Role</label>
              <input
                type="text"
                value={profile.role}
                onChange={(e) => setProfile({ ...profile, role: e.target.value })}
                className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">Division / Team</label>
              <input
                type="text"
                value={profile.team}
                onChange={(e) => setProfile({ ...profile, team: e.target.value })}
                className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>
        </div>
      )}

      {/* Tab 2: Storage & FinOps Policy */}
      {activeTab === 'storage' && (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-6 shadow-sm space-y-6">
          <div className="flex items-center justify-between pb-4 border-b border-slate-100 dark:border-slate-800">
            <div>
              <h3 className="font-semibold text-slate-900 dark:text-white">Amazon S3 Lifecycle Rules & Bucket Configuration</h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Automated object transitions governed by Terraform IaC</p>
            </div>
            <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-indigo-50 text-indigo-700 dark:bg-indigo-950/60 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800">
              Region: ap-southeast-1
            </span>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">S3 Raw Upload Bucket</label>
              <input
                type="text"
                value={storageConfig.rawBucket}
                readOnly
                className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950 text-slate-600 dark:text-slate-400 font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">S3 Processed & CDN Cache Bucket</label>
              <input
                type="text"
                value={storageConfig.processedBucket}
                readOnly
                className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950 text-slate-600 dark:text-slate-400 font-mono"
              />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-2">
              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Glacier Transition Age (Days)
                </label>
                <input
                  type="number"
                  min={7}
                  max={365}
                  value={storageConfig.archiveDays}
                  onChange={(e) => setStorageConfig({ ...storageConfig, archiveDays: Number(e.target.value) })}
                  className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Objects older than this threshold automatically move to Cold Storage ($0.004/GB/mo).</p>
              </div>
              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Target Cold Storage Class
                </label>
                <select
                  value={storageConfig.glacierTransitionClass}
                  onChange={(e) => setStorageConfig({ ...storageConfig, glacierTransitionClass: e.target.value })}
                  className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="GLACIER_IR">S3 Glacier Instant Retrieval (Millisecond access)</option>
                  <option value="GLACIER_FLEXIBLE">S3 Glacier Flexible Retrieval (3-5 hour restore)</option>
                  <option value="DEEP_ARCHIVE">S3 Glacier Deep Archive (Lowest cost, 12h restore)</option>
                </select>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Tab 3: Security & IAM */}
      {activeTab === 'security' && (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-6 shadow-sm space-y-6">
          <div className="border-b border-slate-100 dark:border-slate-800 pb-4">
            <h3 className="font-semibold text-slate-900 dark:text-white">Cloud Security Posture & Cryptography</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Zero-hardcoded secrets enforcement & automated WAF defenses</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 rounded-xl border border-emerald-200 dark:border-emerald-900/50 bg-emerald-50/50 dark:bg-emerald-950/20">
              <div className="flex items-center gap-3">
                <KeyRound className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
                <div>
                  <h4 className="text-sm font-semibold text-slate-900 dark:text-white">Zero Static IAM Access Keys</h4>
                  <p className="text-xs text-slate-500 dark:text-slate-400">GitHub Actions OIDC + ECS Task IAM Execution Roles</p>
                </div>
              </div>
              <div className="mt-3 flex items-center gap-2 text-xs text-emerald-700 dark:text-emerald-300 font-medium">
                <CheckCircle2 className="w-4 h-4" />
                <span>Compliant with AWS Well-Architected Security Pillar</span>
              </div>
            </div>

            <div className="p-4 rounded-xl border border-indigo-200 dark:border-indigo-900/50 bg-indigo-50/50 dark:bg-indigo-950/20">
              <div className="flex items-center gap-3">
                <Lock className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
                <div>
                  <h4 className="text-sm font-semibold text-slate-900 dark:text-white">AWS KMS Customer Managed Key</h4>
                  <p className="text-xs text-slate-500 dark:text-slate-400">SSE-KMS AES-256 for S3 Buckets & RDS Storage</p>
                </div>
              </div>
              <div className="mt-3 flex items-center gap-2 text-xs text-indigo-700 dark:text-indigo-300 font-medium">
                <CheckCircle2 className="w-4 h-4" />
                <span>Encrypted at Rest & In Transit (TLS 1.3)</span>
              </div>
            </div>

            <div className="p-4 rounded-xl border border-violet-200 dark:border-violet-900/50 bg-violet-50/50 dark:bg-violet-950/20">
              <div className="flex items-center gap-3">
                <ShieldCheck className="w-5 h-5 text-violet-600 dark:text-violet-400" />
                <div>
                  <h4 className="text-sm font-semibold text-slate-900 dark:text-white">AWS WAFv2 Application Firewall</h4>
                  <p className="text-xs text-slate-500 dark:text-slate-400">Managed Rule Sets: CommonRuleSet, SQLi, KnownBadInputs</p>
                </div>
              </div>
              <div className="mt-3 flex items-center gap-2 text-xs text-violet-700 dark:text-violet-300 font-medium">
                <CheckCircle2 className="w-4 h-4" />
                <span>Active Protection at CloudFront & ALB</span>
              </div>
            </div>

            <div className="p-4 rounded-xl border border-sky-200 dark:border-sky-900/50 bg-sky-50/50 dark:bg-sky-950/20">
              <div className="flex items-center gap-3">
                <Server className="w-5 h-5 text-sky-600 dark:text-sky-400" />
                <div>
                  <h4 className="text-sm font-semibold text-slate-900 dark:text-white">AWS Secrets Manager Rotation</h4>
                  <p className="text-xs text-slate-500 dark:text-slate-400">RDS Master credentials auto-rotated every 30 days</p>
                </div>
              </div>
              <div className="mt-3 flex items-center gap-2 text-xs text-sky-700 dark:text-sky-300 font-medium">
                <CheckCircle2 className="w-4 h-4" />
                <span>Zero Database Credentials in Git or Images</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Tab 4: DevSecOps Pipeline */}
      {activeTab === 'devsecops' && (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-6 shadow-sm space-y-6">
          <div className="border-b border-slate-100 dark:border-slate-800 pb-4">
            <h3 className="font-semibold text-slate-900 dark:text-white">CI/CD Quality Gates & Vulnerability Thresholds</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Enforce security standards before container images push to Amazon ECR</p>
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 rounded-xl border border-slate-200 dark:border-slate-800">
              <div>
                <h4 className="text-sm font-semibold text-slate-900 dark:text-white">SonarQube Code Coverage & Quality Gate</h4>
                <p className="text-xs text-slate-500 dark:text-slate-400">Block pull requests failing minimum test coverage threshold</p>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-sm font-bold text-indigo-600 dark:text-indigo-400">{devsecopsConfig.sonarqubeGate}%</span>
                <input
                  type="range"
                  min="60"
                  max="95"
                  value={devsecopsConfig.sonarqubeGate}
                  onChange={(e) => setDevsecopsConfig({ ...devsecopsConfig, sonarqubeGate: Number(e.target.value) })}
                  className="w-28 accent-indigo-600 cursor-pointer"
                />
              </div>
            </div>

            <div className="flex items-center justify-between p-4 rounded-xl border border-slate-200 dark:border-slate-800">
              <div>
                <h4 className="text-sm font-semibold text-slate-900 dark:text-white">Trivy Container Vulnerability Gate</h4>
                <p className="text-xs text-slate-500 dark:text-slate-400">Fail CI pipeline if CVEs are detected above severity level</p>
              </div>
              <span className="px-2.5 py-1 text-xs font-semibold rounded bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-300 font-mono">
                {devsecopsConfig.trivySeverity}
              </span>
            </div>

            <div className="flex items-center justify-between p-4 rounded-xl border border-slate-200 dark:border-slate-800">
              <div>
                <h4 className="text-sm font-semibold text-slate-900 dark:text-white">GitLeaks Secret Scanning Pre-commit</h4>
                <p className="text-xs text-slate-500 dark:text-slate-400">Prevent commits containing AWS credentials, private keys, or API tokens</p>
              </div>
              <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300">
                ACTIVE (100% Enforced)
              </span>
            </div>

            <div className="flex items-center justify-between p-4 rounded-xl border border-slate-200 dark:border-slate-800">
              <div>
                <h4 className="text-sm font-semibold text-slate-900 dark:text-white">OWASP ZAP Dynamic Application Security Testing (DAST)</h4>
                <p className="text-xs text-slate-500 dark:text-slate-400">Baseline penetration testing against running staging API container</p>
              </div>
              <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-indigo-100 text-indigo-800 dark:bg-indigo-950/60 dark:text-indigo-300">
                ENABLED ON MERGE
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
